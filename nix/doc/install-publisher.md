# Installation for Publisher

### Summary

* One copy of `civicrm-buildkit.git` in (`$HOME/buildkit`)
* No persistent profiles. `use-bknix` reads fresh package-list from `$HOME/buildkit` on every invocation.
* No live services, except for DBMS. (Use MariaDB via Debian; only store empty/placeholder databases.)

### Installation Steps

* (_Note: These steps will use a placeholder, `fixme_s3cr3t`, for the MySQL password._)

* Install nix CLI

* As a sudo-enabled user, install cachix

    ```bash
    sudo -i nix-env -iA cachix -f https://cachix.org/api/v1/install
    sudo -i cachix use bknix
    ```

* Install Debian's mariadb-server -- to placate `civibuild create cividist`

    ```sql
    CREATE USER 'jenkins'@'localhost' IDENTIFIED VIA unix_socket;
    GRANT ALL PRIVILEGES ON *.* TO 'jenkins'@'localhost' WITH GRANT OPTION;
    CREATE USER 'amp'@'localhost' IDENTIFIED BY 'fixme_s3cr3t';
    GRANT ALL PRIVILEGES ON *.* TO 'amp'@'localhost' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
    ```

* Give `jenkins` a copy of buildkit

    ```bash
    sudo -iu jenkins bash
    git clone https://github.com/civicrm/civicrm-buildkit ~/buildkit
    nix-shell -A min
      civi-download-tools
      amp config:set --mysql_dsn=mysql://amp:fixme_s3cr3t@127.0.0.1:3306 --perm_type=none --httpd_type=none --httpd_visibility=local --hosts_type=none
      exit
    ```

* Install special variant of `use-bknix`

    ```bash
    sudo ln -sf /home/jenkins/buildkit/nix/bin/use-bknix.publish /usr/local/bin/use-bknix
    ```

### Upgrade Steps

To deploy a new version of buildkit, just use the normal steps, e.g.

```bash
sudo -iu jenkins bash
cd ~/buildkit
git pull
nix-shell -A min --run civi-download-tools
```
