## Comparison with other development environments

`bknix` serves a function similar to MAMP or XAMPP -- it facilitates local development by bundling Apache/PHP/etc with a small launcher to run the servers.  However, it is built with the open-source [nix package manager](https://nixos.org/nix) (compatible with OS X and Linux). Like Docker, `nix` lets you create a small project with a manifest-file, and it won't interfere with your normal system settings.  However, unlike Docker, it is not coupled to the Linux kernel -- it can always run on a native (unvirtualized) filesystem.  This significantly improves performance on OS X workstations -- especially if the PHP/JS codebase is large.

(*To be sure, MAMP and Docker both have other advantages -- e.g. MAMP/XAMPP provide a GUI launcher/configuration screen, and Docker's ecosystem touches on process-orchestration, volume-management, virtualized networking, etc. I just don't need those things as much as I need fast/transparent filesystem and portability.*)

## Highly opinionated

* It is primarily intended for developing patches and extensions for CiviCRM -- this influences the set of tools included.
* It combines service binaries (`mysqld`, `httpd`, etc) from [nix](https://nixos.org/nix) with an unsophisticated process-manager script (`bknix`) and all the tools from [buildkit](https://github.com/civicrm/civicrm-buildkit).
* To facilitate quick development with any IDE/editor, all file-storage and development-tasks run in the current users' local Linux/macOS (*without* any virtualization, containerization, invisible filesystems, or magic permissions).
* To optimize DB performance, `mysqld` stores all its data in a ramdisk.
* To avoid conflicts with other tools on your system, all binaries are stored in their own folders, and services run on alternative ports.
