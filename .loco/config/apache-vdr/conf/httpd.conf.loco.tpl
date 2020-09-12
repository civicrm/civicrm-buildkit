ServerRoot "{{LOCO_SVC_VAR}}"
Listen {{HTTPD_PORT}}
PidFile {{LOCO_SVC_VAR}}/httpd.pid
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
ServerName localhost:{{HTTPD_PORT}}
<Directory />
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "{{LOCO_SVC_VAR}}/htdocs"
<Directory "{{LOCO_SVC_VAR}}/htdocs">
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

ErrorLog "|/bin/cat"

LogLevel info

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>

    CustomLog "|/bin/cat" common

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
<Proxy fcgi://{{LOCALHOST}}:{{PHPFPM_PORT}}>
  ProxySet timeout=600
</Proxy>

<VirtualHost *:{{HTTPD_PORT}}>
    ServerAdmin webmaster@{{HTTPD_DOMAIN}}
    ServerName {{HTTPD_DOMAIN}}

    UseCanonicalName    Off
    VirtualDocumentRoot "{{HTTPD_VDROOT}}/%1/web"

    <Directory "{{HTTPD_VDROOT}}">
        Options All
        AllowOverride All
        <IfModule mod_authz_host.c>
            Require all granted
        </IfModule>
    </Directory>

    ## Added for php-fpm
    # ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://{{LOCALHOST}}:{{PHPFPM_PORT}}/<?php echo $root ?>/$1
    DirectoryIndex index.html index.php

    <FilesMatch \.php$>
      # SetHandler "proxy:fcgi://{{LOCALHOST}}:{{PHPFPM_PORT}}#"
      # SetHandler "proxy:unix:/var/run/php5-fpm.sock|fcgi://localhost"
      SetHandler "proxy:fcgi://{{LOCALHOST}}:{{PHPFPM_PORT}}"
    </FilesMatch>

</VirtualHost>
