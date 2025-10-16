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
# LoadModule vhost_alias_module modules/mod_vhost_alias.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
# LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so

ServerAdmin you@example.com
ServerName localhost:{{HTTPD_PORT}}
TraceEnable Off

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

ErrorLog "|/usr/bin/env cat"

LogLevel info

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>

    # CustomLog "|/usr/bin/env cat" common

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
#<Proxy fcgi://{{LOCALHOST}}:{{PHPFPM_PORT}}>
#  ProxySet timeout=600
#</Proxy>

<VirtualHost *:{{HTTPD_PORT}}>
    ServerAdmin webmaster@{{HTTPD_DOMAIN}}
    ServerName {{HTTPD_DOMAIN}}

    UseCanonicalName    Off

    RewriteEngine on
    # LogLevel alert rewrite:trace6

    RewriteCond "%{HTTP_HOST}" "([-\w]+)."
    RewriteRule ^ - [E=BKIT_VHOST:%1]

    ## The demo server has several different build folders (`~/bknix-min/build`, `~/bknix-max/build`, etc).
    ## Each has its own php-fpm, mysqld, etc. When we receive a request for `VHOST.example.com`,
    ## we search for `~/bknix-min/build/VHOST`, `~/bknix-max/build/VHOST`, and so on.

    ##########################################################################################################
    # Act as an HTTP reverse-proxy. Forward requests to the appropriate HTTPD.

    # [loco.yml]      If $HOME/bknix/build/$VHOST/web            ===> forward to http://localhost:8001/$1
    # [demo.yml:dfl]  If $HOME/bknix/build-dfl/build/$VHOST/web  ===> forward to http://localhost:8001/$1
    # [demo.yml:min]  If $HOME/bknix/build-min/build/$VHOST/web  ===> forward to http://localhost:8002/$1
    # [demo.yml:max]  If $HOME/bknix/build-max/build/$VHOST/web  ===> forward to http://localhost:8003/$1
    # [demo.yml:edge] If $HOME/bknix/build-edge/build/$VHOST/web ===> forward to http://localhost:8007/$1

    RewriteCond "%{ENV:HOME}/bknix/build/%{ENV:BKIT_VHOST}/web" -d
    RewriteRule ^ - [L,E=BACKEND_URL:{{LOCALHOST}}:8001]

    RewriteCond "%{ENV:HOME}/bknix-dfl/build/%{ENV:BKIT_VHOST}/web" -d
    RewriteRule ^ - [L,E=BACKEND_URL:{{LOCALHOST}}:8001]

    RewriteCond "%{ENV:HOME}/bknix-min/build/%{ENV:BKIT_VHOST}/web" -d
    RewriteRule ^ - [L,E=BACKEND_URL:{{LOCALHOST}}:8002]

    RewriteCond "%{ENV:HOME}/bknix-max/build/%{ENV:BKIT_VHOST}/web" -d
    RewriteRule ^ - [L,E=BACKEND_URL:{{LOCALHOST}}:8003]

    RewriteCond "%{ENV:HOME}/bknix-edge/build/%{ENV:BKIT_VHOST}/web" -d
    RewriteRule ^ - [L,E=BACKEND_URL:{{LOCALHOST}}:8007]

    ProxyPassInterpolateEnv On
    ProxyPreserveHost On
    ProxyPass / http://${BACKEND_URL}/ interpolate
    ProxyPassReverse / http://${BACKEND_URL}/ interpolate

    ##########################################################################################################
    # This configuration is theoretically better because it doesn't route through as many layers.
    # However, it bypasses the `.htaccess` files in each Drupal/WP/Joomla build.
    # SEE ALSO: .loco/plugins/portname.php

    # [demo.yml:dfl]  If $HOME/bknix-dfl/build/$VHOST/web  ===> set BKIT_PHPFPM=9009 and BKIT_DOCROOT=...
    # [demo.yml:min]  If $HOME/bknix-min/build/$VHOST/web  ===> set BKIT_PHPFPM=9010 and BKIT_DOCROOT=...
    # [demo.yml:max]  If $HOME/bknix-max/build/$VHOST/web  ===> set BKIT_PHPFPM=9011 and BKIT_DOCROOT=...
    # [demo.yml:edge] If $HOME/bknix-edge/build/$VHOST/web ===> set BKIT_PHPFPM=9015 and BKIT_DOCROOT=...
    # [loco.yml]      If $HOME/bknix/build/$VHOST/web      ===> set BKIT_PHPFPM=9009 and BKIT_DOCROOT=...

    #RewriteCond "%{ENV:HOME}/bknix-dfl/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_PHPFPM:9009]
    #RewriteCond "%{ENV:HOME}/bknix-dfl/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_DOCROOT:%{ENV:HOME}/bknix-dfl/build/%{ENV:BKIT_VHOST}/web]

    #RewriteCond "%{ENV:HOME}/bknix-min/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_PHPFPM:9010]
    #RewriteCond "%{ENV:HOME}/bknix-min/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_DOCROOT:%{ENV:HOME}/bknix-min/build/%{ENV:BKIT_VHOST}/web]

    #RewriteCond "%{ENV:HOME}/bknix-max/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_PHPFPM:9011]
    #RewriteCond "%{ENV:HOME}/bknix-max/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_DOCROOT:%{ENV:HOME}/bknix-max/build/%{ENV:BKIT_VHOST}/web]

    #RewriteCond "%{ENV:HOME}/bknix-edge/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_PHPFPM:9015]
    #RewriteCond "%{ENV:HOME}/bknix-edge/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_DOCROOT:%{ENV:HOME}/bknix-edge/build/%{ENV:BKIT_VHOST}/web]

    #RewriteCond "%{ENV:HOME}/bknix/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_PHPFPM:9009]
    #RewriteCond "%{ENV:HOME}/bknix/build/%{ENV:BKIT_VHOST}/web" -d
    #RewriteRule ^ - [E=BKIT_DOCROOT:%{ENV:HOME}/bknix/build/%{ENV:BKIT_VHOST}/web]

    #RewriteRule   "^(.*)" "%{ENV:BKIT_DOCROOT}/$1"

    #<Directory ~ "${HOME}/bknix(|-dfl|-min|-max|-alt|-edge)/build/">
    #    Options All
    #    AllowOverride All
    #    <IfModule mod_authz_host.c>
    #        Require all granted
    #    </IfModule>
    #</Directory>

    #DirectoryIndex index.html index.php

    #<FilesMatch \.php$>
    #  SetHandler "proxy:fcgi://{{LOCALHOST}}:%{ENV:BKIT_PHPFPM}"
    #</FilesMatch>

</VirtualHost>
