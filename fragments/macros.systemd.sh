# Scripts based on the RPM %systemd_post scriptlet. See:
#   - https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/#_systemd
#   - https://github.com/systemd/systemd/blob/v251/src/rpm/macros.systemd.in
#   - https://github.com/systemd/systemd/blob/v251/src/rpm/triggers.systemd.in
#   - https://github.com/systemd/systemd/blob/v251/src/rpm/systemd-update-helper.in
#
# As we currently target CentOS 7 and CentOS 8, these are the relevant versions of the
# original scripts (systemd-update-helper doesn't exist in these versions yet):
#
#   CentOS 8 systemd v239: https://github.com/systemd/systemd/blob/v239/src/core/macros.systemd.in
#                          https://github.com/systemd/systemd/blob/v239/src/core/triggers.systemd.in
#   CentOS 7 systemd v219: https://github.com/systemd/systemd/blob/v219/src/core/macros.systemd.in
#
# TODO: Allow the author of this file to add a line #SYSTEMD_RPM_MACROS# that will be replaced
# automatically by the helper functions that emulate systemd RPM macros behaviour for various
# known/supported versions of systemd.
#
# Note: These functions have only been tested with Bash.

systemd_update_helper_v239() {
    case "$command" in
        install-system-units)
            systemctl --no-reload preset "$@" &>/dev/null
            ;;

        remove-system-units)
            systemctl --no-reload disable --now "$@" &>/dev/null
            ;;

        mark-restart-system-units)
            systemctl try-restart "$@" &>/dev/null 2>&1
            ;;

        system-reload)
            systemctl daemon-reload
            ;;
    esac
}

systemd_update_helper_v219() {
    case "$command" in
        install-system-units)
            systemctl preset "$@" &>/dev/null 2>&1
            ;;

        remove-system-units)
            systemctl --no-reload disable "$@" > /dev/null 2>&1
            systemctl stop "$@" > /dev/null 2>&1
            ;;

        mark-restart-system-units)
            systemctl try-restart "$@" >/dev/null 2>&1
            ;;

        system-reload)
            ;;
    esac
}

systemd_update_helper() {
    command="${1:?}"
    shift

    command -v systemctl >/dev/null || exit 0

    # Determine the version of systemd we are running under.
    # systemctl --version outputs a first line of the form:
    #   systemd 239 (239-58.el8_6.8)
    SYSTEMD_VER=$(systemctl --version | head -1 | awk '{ print $2}')

    if [ ${SYSTEMD_VER} -le 219 ]; then
        systemd_update_helper_v219 "$@"
    else
        systemd_update_helper_v239 "$@"
    fi
}

systemd_post() {
    systemd_update_helper install-system-units "$@"
}

systemd_preun() {
    systemd_update_helper remove-system-units "$@"
}

systemd_postun_with_restart() {
    systemd_update_helper mark-restart-system-units "$@"
}

systemd_triggers() {
    systemd_update_helper system-reload
}