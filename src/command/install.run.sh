civibuild_app_assert_loaded
[ "$ACTION" == "reinstall" ] && FORCE_INSTALL=1
civibuild_app_install
civibuild_app_save
civibuild_app_show