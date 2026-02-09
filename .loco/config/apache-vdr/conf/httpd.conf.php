<?php
// These defaults should only be used for interactive testing of the template.
$defaults = [
  'LOCO_SVC_VAR' => '/opt/loco/service',
  'HTTPD_PORT'   => 8080,
  'HTTPD_DOMAIN' => 'localhost',
  'HTTPD_PROXY'    => 'none',
  'HTTPD_VISIBILITY' => 'local',
  'LOCALHOST'    => '127.0.0.1',
  'PHPFPM_PORT'  => 9000,
  'HTTPD_VDROOT' => '/var/www/vhosts',
  'PROJECT_ROOT' => '/path/to/project',
];
foreach ($defaults as $key => $val) {
  if (getenv($key) === FALSE) {
    putenv("$key=$val");
  }
}

?>
ServerRoot "<?php echo getenv('LOCO_SVC_VAR'); ?>"
<?php if (getenv('HTTPD_VISIBILITY') === 'all'): ?>
Listen <?php echo getenv('HTTPD_PORT'); echo "\n"; ?>
<? else: ?>
Listen <?php echo getenv('LOCALHOST') . ':' . getenv('HTTPD_PORT'); echo "\n"; ?>
<? endif; ?>
PidFile <?php echo getenv('LOCO_SVC_VAR'); ?>/httpd.pid
LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule authn_file_module modules/mod_authn_file.so
LoadModule authn_core_module modules/mod_authn_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
LoadModule authz_user_module modules/mod_authz_user.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule access_compat_module modules/mod_access_compat.so
LoadModule auth_basic_module modules/mod_auth_basic.so
LoadModule reqtimeout_module modules/mod_reqtimeout.so
LoadModule filter_module modules/mod_filter.so
LoadModule mime_module modules/mod_mime.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule env_module modules/mod_env.so
LoadModule headers_module modules/mod_headers.so
<?php if (getenv('HTTPD_PROXY') !== 'none') : ?>
LoadModule remoteip_module modules/mod_remoteip.so
<?php endif; ?>
LoadModule setenvif_module modules/mod_setenvif.so
LoadModule version_module modules/mod_version.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule status_module modules/mod_status.so
LoadModule autoindex_module modules/mod_autoindex.so
<IfModule !mpm_prefork_module>
    #LoadModule cgid_module modules/mod_cgid.so
</IfModule>
<IfModule mpm_prefork_module>
    #LoadModule cgi_module modules/mod_cgi.so
</IfModule>
LoadModule dir_module modules/mod_dir.so
LoadModule alias_module modules/mod_alias.so

LoadModule deflate_module modules/mod_deflate.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule ssl_module modules/mod_ssl.so
LoadModule vhost_alias_module modules/mod_vhost_alias.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so

ServerAdmin you@example.com
ServerName localhost:<?php echo getenv('HTTPD_PORT'); echo "\n"; ?>
TraceEnable Off

<?php if (getenv('HTTPD_PROXY') === 'local') : ?>
RemoteIPHeader X-Forwarded-For
RemoteIPTrustedProxy <?php echo getenv('LOCALHOST'); echo "\n"; ?>
<?php endif; ?>

<Directory />
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "<?php echo getenv('LOCO_SVC_VAR'); ?>/htdocs"
<Directory "<?php echo getenv('LOCO_SVC_VAR'); ?>/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html index.php
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "|/usr/bin/env cat"

LogLevel info

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>

    CustomLog "|/usr/bin/env cat" common

</IfModule>

<IfModule headers_module>
    RequestHeader unset Proxy early
</IfModule>

<IfModule mime_module>
    TypesConfig conf/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
</IfModule>


<IfModule ssl_module>
SSLRandomSeed startup builtin
SSLRandomSeed connect builtin
</IfModule>

Timeout 600
<Proxy fcgi://<?php echo getenv('LOCALHOST'); ?>:<?php echo getenv('PHPFPM_PORT'); ?>>
  ProxySet timeout=600
</Proxy>

<VirtualHost *:<?php echo getenv('HTTPD_PORT'); ?>>
    ServerAdmin webmaster@<?php echo getenv('HTTPD_DOMAIN'); echo "\n"; ?>
    ServerName <?php echo getenv('HTTPD_DOMAIN'); echo "\n"; ?>

    UseCanonicalName    Off
    VirtualDocumentRoot "<?php echo getenv('HTTPD_VDROOT'); ?>/%1/web"

    <?php
    if (getenv('HTTPD_SSL_CERT') xor getenv('HTTPD_SSL_KEY')) :
      fprintf(STDERR, "ERROR: The variables HTTPD_SSL_CERT and HTTPD_SSL_KEY must be provided as a pair.\n");
      fprintf(STDERR, "Please fix the variables, then cleanup Apache (loco clean apache-vdr) and restart.\n");
      exit(1);
    elseif (getenv('HTTPD_SSL_CERT') && getenv('HTTPD_SSL_KEY')) :
    ?>
    SSLEngine             on
    SSLCertificateFile    <?php echo getenv('HTTPD_SSL_CERT'); echo "\n"; ?>
    SSLCertificateKeyFile <?php echo getenv('HTTPD_SSL_KEY'); echo "\n"; ?>
    <?php endif; ?>

    <?php if (getenv('HTTPD_PROXY') === 'local') : ?>
    ## Set HTTPS=on for proxied requests. Ideally, you trust X-Forwarded-Proto ONLY IF
    ## the X-Forwarded-For policy has been satisifed. However, I can't find a good way
    ## to do this when using Apache+remoteip. Here are two middling options:
    ##
    ## (1) Simple and portable policy -- accept X-Forwarded-Proto on all requests.
    ## ChatGPT suggests this.  :P Depending on the rest of your setup, it might
    ## allow a caller to coerce HTTPS=on even when using HTTP.  Of course, if you
    ## have HSTS or mandatory redirects (:80=>:443) at the right level, then that's
    ## not possible.  And even if you allow HTTP, it's hard to see how Mallory
    ## tricks Alice into making a vulnerable request.  (Unless your server allows
    ## CORS?) For many topologies, it probably works OK, even if it feels sketchy.
    #
    # SetEnvIf X-Forwarded-Proto "^https$" HTTPS=on
    #
    ## (2) Stricter version (special-case, local-proxy).  This relies on the
    ## fact that 127.0.0.1 is not routable on public internet; so if we
    ## received the request locally (Server_Addr=127.0.0.1), then the
    ## immediate sender was also local.  Works for local-proxy or special
    ## agent (like Cloudflare Tunnel) but not other topologies.  (N.B.  We
    ## cannot test for Remote_Addr=127.0.0.1 b/c mod_remoteip obscured it.)
    #
    SetEnvIf X-Forwarded-Proto "^https$" HTTPS_hdr=1
    SetEnvIf Server_Addr "<?php echo '^' . preg_quote(getenv('LOCALHOST')) . '$'; ?>" HTTPS_local=1
    SetEnvIfExpr "env('HTTPS_hdr') == '1' && env('HTTPS_local') == '1'" HTTPS=on
    <?php endif; ?>

    <Directory "<?php echo getenv('HTTPD_VDROOT'); ?>">
        Options All
        AllowOverride All
        <IfModule mod_authz_host.c>
            Require all granted
        </IfModule>
    </Directory>

    ## Added for php-fpm
    # ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://<?php echo getenv('LOCALHOST'); ?>:<?php echo getenv('PHPFPM_PORT'); ?>/<?php echo 'project-root'; ?>/$1
    DirectoryIndex index.html index.php

    <FilesMatch \.php$>
      # SetHandler "proxy:fcgi://<?php echo getenv('LOCALHOST'); ?>:<?php echo getenv('PHPFPM_PORT'); ?>#"
      # SetHandler "proxy:unix:/var/run/php5-fpm.sock|fcgi://localhost"
      SetHandler "proxy:fcgi://<?php echo getenv('LOCALHOST'); ?>:<?php echo getenv('PHPFPM_PORT'); ?>"
    </FilesMatch>

</VirtualHost>
