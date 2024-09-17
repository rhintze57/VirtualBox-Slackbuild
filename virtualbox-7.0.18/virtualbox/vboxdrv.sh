#! /bin/sh
# Oracle VM VirtualBox
# Linux kernel module init script

#
# Copyright (C) 2006-2023 Oracle and/or its affiliates.
#
# This file is part of VirtualBox base platform packages, as
# available from https://www.virtualbox.org.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, in version 3 of the
# License.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <https://www.gnu.org/licenses>.
#
# SPDX-License-Identifier: GPL-3.0-only
#

# chkconfig: 345 20 80
# description: VirtualBox Linux kernel module
#
### BEGIN INIT INFO
# Provides:       vboxdrv
# Required-Start: $syslog
# Required-Stop:
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description: VirtualBox Linux kernel module
### END INIT INFO

## @todo This file duplicates a lot of script with vboxadd.sh.  When making
# changes please try to reduce differences between the two wherever possible.

## @todo Remove the stop_vms target so that this script is only relevant to
# kernel modules.  Nice but not urgent.

PATH=/sbin:/bin:/usr/sbin:/usr/bin:$PATH
DEVICE=/dev/vboxdrv
MODPROBE=/sbin/modprobe
SCRIPTNAME=vboxdrv.sh

# The below is GNU-specific.  See VBox.sh for the longer Solaris/OS X version.
TARGET=`readlink -e -- "${0}"` || exit 1
SCRIPT_DIR="${TARGET%/[!/]*}"

if $MODPROBE -c | grep -q '^allow_unsupported_modules  *0'; then
  MODPROBE="$MODPROBE --allow-unsupported-modules"
fi

setup_log()
{
    test -n "${LOG}" && return 0
    # Rotate log files
    LOG="/var/log/vbox-setup.log"
    mv "${LOG}.3" "${LOG}.4" 2>/dev/null
    mv "${LOG}.2" "${LOG}.3" 2>/dev/null
    mv "${LOG}.1" "${LOG}.2" 2>/dev/null
    mv "${LOG}" "${LOG}.1" 2>/dev/null
}

[ -f /etc/vbox/vbox.cfg ] && . /etc/vbox/vbox.cfg
export VBOX_KBUILD_TYPE
export USERNAME
export USER=$USERNAME

if test -n "${INSTALL_DIR}" && test -x "${INSTALL_DIR}/VirtualBox"; then
    MODULE_SRC="${INSTALL_DIR}/src/vboxhost"
elif test -x /usr/lib/virtualbox/VirtualBox; then
    INSTALL_DIR=/usr/lib/virtualbox
    MODULE_SRC="/usr/share/virtualbox/src/vboxhost"
elif test -x "${SCRIPT_DIR}/VirtualBox"; then
    # Executing from the build directory
    INSTALL_DIR="${SCRIPT_DIR}"
    MODULE_SRC="${INSTALL_DIR}/src"
else
    # Silently exit if the package was uninstalled but not purged.
    # Applies to Debian packages only (but shouldn't hurt elsewhere)
    exit 0
fi
VIRTUALBOX="${INSTALL_DIR}/VirtualBox"
VBOXMANAGE="${INSTALL_DIR}/VBoxManage"
BUILDINTMP="${MODULE_SRC}/build_in_tmp"
if test -u "${VIRTUALBOX}"; then
    GROUP=root
    DEVICE_MODE=0600
else
    GROUP=vboxusers
    DEVICE_MODE=0660
fi

KERN_VER=`uname -r`

# Prepend PATH for building UEK7 on OL8 distribution.
case "$KERN_VER" in
    5.15.0-*.el8uek*) PATH="/opt/rh/gcc-toolset-11/root/usr/bin:$PATH";;
esac

if test -e "${MODULE_SRC}/vboxpci"; then
    MODULE_LIST="vboxdrv vboxnetflt vboxnetadp vboxpci"
else
    MODULE_LIST="vboxdrv vboxnetflt vboxnetadp"
fi
# Secure boot state.
case "`mokutil --sb-state 2>/dev/null`" in
    *"disabled in shim"*) unset HAVE_SEC_BOOT;;
    *"SecureBoot enabled"*) HAVE_SEC_BOOT=true;;
    *) unset HAVE_SEC_BOOT;;
esac
# So far we can only sign modules on Ubuntu and on Debian 10 and later.
DEB_PUB_KEY=/var/lib/shim-signed/mok/MOK.der
DEB_PRIV_KEY=/var/lib/shim-signed/mok/MOK.priv
unset HAVE_DEB_KEY
case "`mokutil --test-key "$DEB_PUB_KEY" 2>/dev/null`" in
    *"is already"*) DEB_KEY_ENROLLED=true;;
    *) unset DEB_KEY_ENROLLED;;
esac

# Try to find a tool for modules signing.
SIGN_TOOL=$(which kmodsign 2>/dev/null)
# Attempt to use in-kernel signing tool if kmodsign not found.
if test -z "$SIGN_TOOL"; then
    if test -x "/lib/modules/$KERN_VER/build/scripts/sign-file"; then
        SIGN_TOOL="/lib/modules/$KERN_VER/build/scripts/sign-file"
    fi
fi

# Check if update-secureboot-policy tool supports required commandline options.
update_secureboot_policy_supports()
{
    opt_name="$1"
    [ -n "$opt_name" ] || return

    [ -z "$(update-secureboot-policy --help 2>&1 | grep "$opt_name")" ] && return
    echo "1"
}

HAVE_UPDATE_SECUREBOOT_POLICY_TOOL=
if type update-secureboot-policy >/dev/null 2>&1; then
    [ "$(update_secureboot_policy_supports new-key)" = "1" -a "$(update_secureboot_policy_supports enroll-key)" = "1" ] && \
        HAVE_UPDATE_SECUREBOOT_POLICY_TOOL=true
fi

[ -r /etc/default/virtualbox ] && . /etc/default/virtualbox

# Preamble for Gentoo
if [ "`which $0`" = "/sbin/rc" ]; then
    shift
fi

begin_msg()
{
    test -n "${2}" && echo "${SCRIPTNAME}: ${1}."
    logger -t "${SCRIPTNAME}" "${1}."
}

succ_msg()
{
    logger -t "${SCRIPTNAME}" "${1}."
}

fail_msg()
{
    echo "${SCRIPTNAME}: failed: ${1}." >&2
    logger -t "${SCRIPTNAME}" "failed: ${1}."
}

failure()
{
    fail_msg "$1"
    exit 1
}

running()
{
    lsmod | grep -q "$1[^_-]"
}

log()
{
    setup_log
    echo "${1}" >> "${LOG}"
}

module_build_log()
{
    setup_log
    echo "${1}" | egrep -v \
        "^test -e include/generated/autoconf.h|^echo >&2|^/bin/false\)$" \
        >> "${LOG}"
}

# Detect VirtualBox version info or report error.
VBOX_VERSION="`"$VBOXMANAGE" -v | cut -d r -f1`"
[ -n "$VBOX_VERSION" ] || failure 'Cannot detect VirtualBox version number'
VBOX_REVISION="r`"$VBOXMANAGE" -v | cut -d r -f2`"
[ "$VBOX_REVISION" != "r" ] || failure 'Cannot detect VirtualBox revision number'

## Output the vboxdrv part of our udev rule.  This is redirected to the right file.
udev_write_vboxdrv() {
    VBOXDRV_GRP="$1"
    VBOXDRV_MODE="$2"

    echo "KERNEL==\"vboxdrv\", OWNER=\"root\", GROUP=\"$VBOXDRV_GRP\", MODE=\"$VBOXDRV_MODE\""
    echo "KERNEL==\"vboxdrvu\", OWNER=\"root\", GROUP=\"root\", MODE=\"0666\""
    echo "KERNEL==\"vboxnetctl\", OWNER=\"root\", GROUP=\"$VBOXDRV_GRP\", MODE=\"$VBOXDRV_MODE\""
}

## Output the USB part of our udev rule.  This is redirected to the right file.
udev_write_usb() {
    INSTALLATION_DIR="$1"
    USB_GROUP="$2"

    echo "SUBSYSTEM==\"usb_device\", ACTION==\"add\", RUN+=\"$INSTALLATION_DIR/VBoxCreateUSBNode.sh \$major \$minor \$attr{bDeviceClass}${USB_GROUP}\""
    echo "SUBSYSTEM==\"usb\", ACTION==\"add\", ENV{DEVTYPE}==\"usb_device\", RUN+=\"$INSTALLATION_DIR/VBoxCreateUSBNode.sh \$major \$minor \$attr{bDeviceClass}${USB_GROUP}\""
    echo "SUBSYSTEM==\"usb_device\", ACTION==\"remove\", RUN+=\"$INSTALLATION_DIR/VBoxCreateUSBNode.sh --remove \$major \$minor\""
    echo "SUBSYSTEM==\"usb\", ACTION==\"remove\", ENV{DEVTYPE}==\"usb_device\", RUN+=\"$INSTALLATION_DIR/VBoxCreateUSBNode.sh --remove \$major \$minor\""
}

## Generate our udev rule file.  This takes a change in udev rule syntax in
## version 55 into account.  It only creates rules for USB for udev versions
## recent enough to support USB device nodes.
generate_udev_rule() {
    VBOXDRV_GRP="$1"      # The group owning the vboxdrv device
    VBOXDRV_MODE="$2"     # The access mode for the vboxdrv device
    INSTALLATION_DIR="$3" # The directory VirtualBox is installed in
    USB_GROUP="$4"        # The group that has permission to access USB devices
    NO_INSTALL="$5"       # Set this to "1" to remove but not re-install rules

    # Extra space!
    case "$USB_GROUP" in ?*) USB_GROUP=" $USB_GROUP" ;; esac
    case "$NO_INSTALL" in "1") return ;; esac
    udev_write_vboxdrv "$VBOXDRV_GRP" "$VBOXDRV_MODE"
    udev_write_usb "$INSTALLATION_DIR" "$USB_GROUP"
}

## Install udev rule (disable with INSTALL_NO_UDEV=1 in
## /etc/default/virtualbox).
install_udev() {
    VBOXDRV_GRP="$1"      # The group owning the vboxdrv device
    VBOXDRV_MODE="$2"     # The access mode for the vboxdrv device
    INSTALLATION_DIR="$3" # The directory VirtualBox is installed in
    USB_GROUP="$4"        # The group that has permission to access USB devices
    NO_INSTALL="$5"       # Set this to "1" to remove but not re-install rules

    if test -d /etc/udev/rules.d; then
        generate_udev_rule "$VBOXDRV_GRP" "$VBOXDRV_MODE" "$INSTALLATION_DIR" \
                           "$USB_GROUP" "$NO_INSTALL"
    fi
    # Remove old udev description file
    rm -f /etc/udev/rules.d/10-vboxdrv.rules 2> /dev/null
}

## Create a usb device node for a given sysfs path to a USB device.
install_create_usb_node_for_sysfs() {
    path="$1"           # sysfs path for the device
    usb_createnode="$2" # Path to the USB device node creation script
    usb_group="$3"      # The group to give ownership of the node to
    if test -r "${path}/dev"; then
        dev="`cat "${path}/dev" 2> /dev/null`"
        major="`expr "$dev" : '\(.*\):' 2> /dev/null`"
        minor="`expr "$dev" : '.*:\(.*\)' 2> /dev/null`"
        class="`cat ${path}/bDeviceClass 2> /dev/null`"
        sh "${usb_createnode}" "$major" "$minor" "$class" \
              "${usb_group}" 2>/dev/null
    fi
}

udev_rule_file=/etc/udev/rules.d/60-vboxdrv.rules
sysfs_usb_devices="/sys/bus/usb/devices/*"

## Install udev rules and create device nodes for usb access
setup_usb() {
    VBOXDRV_GRP="$1"      # The group that should own /dev/vboxdrv
    VBOXDRV_MODE="$2"     # The mode to be used for /dev/vboxdrv
    INSTALLATION_DIR="$3" # The directory VirtualBox is installed in
    USB_GROUP="$4"        # The group that should own the /dev/vboxusb device
                          # nodes unless INSTALL_NO_GROUP=1 in
                          # /etc/default/virtualbox.  Optional.
    usb_createnode="$INSTALLATION_DIR/VBoxCreateUSBNode.sh"
    # install udev rule (disable with INSTALL_NO_UDEV=1 in
    # /etc/default/virtualbox)
    if [ "$INSTALL_NO_GROUP" != "1" ]; then
        usb_group=$USB_GROUP
        vboxdrv_group=$VBOXDRV_GRP
    else
        usb_group=root
        vboxdrv_group=root
    fi
    install_udev "${vboxdrv_group}" "$VBOXDRV_MODE" \
                 "$INSTALLATION_DIR" "${usb_group}" \
                 "$INSTALL_NO_UDEV" > ${udev_rule_file}
    # Build our device tree
    for i in ${sysfs_usb_devices}; do  # This line intentionally without quotes.
        install_create_usb_node_for_sysfs "$i" "${usb_createnode}" \
                                          "${usb_group}"
    done
}

cleanup_usb()
{
    # Remove udev description file
    rm -f /etc/udev/rules.d/60-vboxdrv.rules
    rm -f /etc/udev/rules.d/10-vboxdrv.rules

    # Remove our USB device tree
    rm -rf /dev/vboxusb
}

# Returns path to module file as seen by modinfo(8) or empty string.
module_path()
{
    mod="$1"
    [ -n "$mod" ] || return

    modinfo "$mod" 2>/dev/null | grep -e "^filename:" | tr -s ' ' | cut -d " " -f2
}

# Returns module version if module is available or empty string.
module_version()
{
    mod="$1"
    [ -n "$mod" ] || return

    modinfo "$mod" 2>/dev/null | grep -e "^version:" | tr -s ' ' | cut -d " " -f2
}

# Returns module revision if module is available in the system or empty string.
module_revision()
{
    mod="$1"
    [ -n "$mod" ] || return

    modinfo "$mod" 2>/dev/null | grep -e "^version:" | tr -s ' ' | cut -d " " -f3
}

# Returns "1" if module is signed and signature can be verified
# with public key provided in DEB_PUB_KEY. Or empty string otherwise.
module_signed()
{
    mod="$1"
    [ -n "$mod" ] || return

    # Be nice with distributions which do not provide tools which we
    # use in order to verify module signature. This variable needs to
    # be explicitly set by administrator. This script will look for it
    # in /etc/vbox/vbox.cfg. Make sure that you know what you do!
    if [ "$VBOX_BYPASS_MODULES_SIGNATURE_CHECK" = "1" ]; then
        echo "1"
        return
    fi

    extraction_tool=/lib/modules/"$(uname -r)"/build/scripts/extract-module-sig.pl
    mod_path=$(module_path "$mod" 2>/dev/null)
    openssl_tool=$(which openssl 2>/dev/null)
    # Do not use built-in printf!
    printf_tool=$(which printf 2>/dev/null)

    # Make sure all the tools required for signature validation are available.
    [ -x "$extraction_tool" ] || return
    [ -n "$mod_path"        ] || return
    [ -n "$openssl_tool"    ] || return
    [ -n "$printf_tool"     ] || return

    # Make sure openssl can handle hash algorithm.
    sig_hashalgo=$(modinfo -F sig_hashalgo "$mod" 2>/dev/null)
    [ "$(module_sig_hash_supported $sig_hashalgo)" = "1" ] || return

    # Generate file names for temporary stuff.
    mod_pub_key=$(mktemp -u)
    mod_signature=$(mktemp -u)
    mod_unsigned=$(mktemp -u)

    # Convert public key in DER format into X509 certificate form.
    "$openssl_tool" x509 -pubkey -inform DER -in "$DEB_PUB_KEY" -out "$mod_pub_key" 2>/dev/null
    # Extract raw module signature and convert it into binary format.
    "$printf_tool" \\x$(modinfo -F signature "$mod" | sed -z 's/[ \t\n]//g' | sed -e "s/:/\\\x/g") 2>/dev/null > "$mod_signature"
    # Extract unsigned module for further digest calculation.
    "$extraction_tool" -0 "$mod_path" 2>/dev/null > "$mod_unsigned"

    # Verify signature.
    rc=""
    "$openssl_tool" dgst "-$sig_hashalgo" -binary -verify "$mod_pub_key" -signature "$mod_signature" "$mod_unsigned" 2>&1 >/dev/null && rc="1"
    # Clean up.
    rm -f $mod_pub_key $mod_signature $mod_unsigned

    # Check result.
    [ "$rc" = "1" ] || return

    echo "1"
}

# Returns "1" if externally built module is available in the system and its
# version and revision number do match to current VirtualBox installation.
# Or empty string otherwise.
module_available()
{
    mod="$1"
    [ -n "$mod" ] || return

    [ "$VBOX_VERSION" = "$(module_version "$mod")" ] || return
    [ "$VBOX_REVISION" = "$(module_revision "$mod")" ] || return

    # Check if module belongs to VirtualBox installation.
    #
    # We have a convention that only modules from /lib/modules/*/misc
    # belong to us. Modules from other locations are treated as
    # externally built.
    mod_path="$(module_path "$mod")"

    # If module path points to a symbolic link, resolve actual file location.
    [ -L "$mod_path" ] && mod_path="$(readlink -e -- "$mod_path")"

    # File exists?
    [ -f "$mod_path" ] || return

    # Extract last component of module path and check whether it is located
    # outside of /lib/modules/*/misc.
    mod_dir="$(dirname "$mod_path" | sed 's;^.*/;;')"
    [ "$mod_dir" = "misc" ] || return

    echo "1"
}

# Check if required modules are installed in the system and versions match.
setup_complete()
{
    [ "$(module_available vboxdrv)"    = "1" ] || return
    [ "$(module_available vboxnetflt)" = "1" ] || return
    [ "$(module_available vboxnetadp)" = "1" ] || return

    # All modules are in place.
    echo "1"
}

start()
{
    begin_msg "Starting VirtualBox services" console
    if [ -d /proc/xen ]; then
        failure "Running VirtualBox in a Xen environment is not supported"
    fi
    if ! running vboxdrv; then

        # Check if system already has matching modules installed.
        [ "$(setup_complete)" = "1" ] || setup

        if ! rm -f $DEVICE; then
            failure "Cannot remove $DEVICE"
        fi
        if ! $MODPROBE vboxdrv > /dev/null 2>&1; then
            failure "modprobe vboxdrv failed. Please use 'dmesg' to find out why"
        fi
        sleep .2
    fi
    # ensure the character special exists
    if [ ! -c $DEVICE ]; then
        MAJOR=`sed -n 's;\([0-9]\+\) vboxdrv$;\1;p' /proc/devices`
        if [ ! -z "$MAJOR" ]; then
            MINOR=0
        else
            MINOR=`sed -n 's;\([0-9]\+\) vboxdrv$;\1;p' /proc/misc`
            if [ ! -z "$MINOR" ]; then
                MAJOR=10
            fi
        fi
        if [ -z "$MAJOR" ]; then
            rmmod vboxdrv 2>/dev/null
            failure "Cannot locate the VirtualBox device"
        fi
        if ! mknod -m 0660 $DEVICE c $MAJOR $MINOR 2>/dev/null; then
            rmmod vboxdrv 2>/dev/null
            failure "Cannot create device $DEVICE with major $MAJOR and minor $MINOR"
        fi
    fi
    # ensure permissions
    if ! chown :"${GROUP}" $DEVICE 2>/dev/null; then
        rmmod vboxpci 2>/dev/null
        rmmod vboxnetadp 2>/dev/null
        rmmod vboxnetflt 2>/dev/null
        rmmod vboxdrv 2>/dev/null
        failure "Cannot change group ${GROUP} for device $DEVICE"
    fi
    if ! $MODPROBE vboxnetflt > /dev/null 2>&1; then
        failure "modprobe vboxnetflt failed. Please use 'dmesg' to find out why"
    fi
    if ! $MODPROBE vboxnetadp > /dev/null 2>&1; then
        failure "modprobe vboxnetadp failed. Please use 'dmesg' to find out why"
    fi
    if test -e "${MODULE_SRC}/vboxpci" && ! $MODPROBE vboxpci > /dev/null 2>&1; then
        failure "modprobe vboxpci failed. Please use 'dmesg' to find out why"
    fi
    # Create the /dev/vboxusb directory if the host supports that method
    # of USB access.  The USB code checks for the existence of that path.
    if grep -q usb_device /proc/devices; then
        mkdir -p -m 0750 /dev/vboxusb 2>/dev/null
        chown root:vboxusers /dev/vboxusb 2>/dev/null
    fi
    succ_msg "VirtualBox services started"
}

stop()
{
    begin_msg "Stopping VirtualBox services" console

    if running vboxpci; then
        if ! rmmod vboxpci 2>/dev/null; then
            failure "Cannot unload module vboxpci"
        fi
    fi
    if running vboxnetadp; then
        if ! rmmod vboxnetadp 2>/dev/null; then
            failure "Cannot unload module vboxnetadp"
        fi
    fi
    if running vboxdrv; then
        if running vboxnetflt; then
            if ! rmmod vboxnetflt 2>/dev/null; then
                failure "Cannot unload module vboxnetflt"
            fi
        fi
        if ! rmmod vboxdrv 2>/dev/null; then
            failure "Cannot unload module vboxdrv"
        fi
        if ! rm -f $DEVICE; then
            failure "Cannot unlink $DEVICE"
        fi
    fi
    succ_msg "VirtualBox services stopped"
}

# enter the following variables in /etc/default/virtualbox:
#   SHUTDOWN_USERS="foo bar"
#     check for running VMs of user foo and user bar
#   SHUTDOWN=poweroff
#   SHUTDOWN=acpibutton
#   SHUTDOWN=savestate
#     select one of these shutdown methods for running VMs
stop_vms()
{
    wait=0
    for i in $SHUTDOWN_USERS; do
        # don't create the ipcd directory with wrong permissions!
        if [ -d /tmp/.vbox-$i-ipc ]; then
            export VBOX_IPC_SOCKETID="$i"
            VMS=`$VBOXMANAGE --nologo list runningvms | sed -e 's/^".*".*{\(.*\)}/\1/' 2>/dev/null`
            if [ -n "$VMS" ]; then
                if [ "$SHUTDOWN" = "poweroff" ]; then
                    begin_msg "Powering off remaining VMs"
                    for v in $VMS; do
                        $VBOXMANAGE --nologo controlvm $v poweroff
                    done
                    succ_msg "Remaining VMs powered off"
                elif [ "$SHUTDOWN" = "acpibutton" ]; then
                    begin_msg "Sending ACPI power button event to remaining VMs"
                    for v in $VMS; do
                        $VBOXMANAGE --nologo controlvm $v acpipowerbutton
                        wait=30
                    done
                    succ_msg "ACPI power button event sent to remaining VMs"
                elif [ "$SHUTDOWN" = "savestate" ]; then
                    begin_msg "Saving state of remaining VMs"
                    for v in $VMS; do
                        $VBOXMANAGE --nologo controlvm $v savestate
                    done
                    succ_msg "State of remaining VMs saved"
                fi
            fi
        fi
    done
    # wait for some seconds when doing ACPI shutdown
    if [ "$wait" -ne 0 ]; then
        begin_msg "Waiting for $wait seconds for VM shutdown"
        sleep $wait
        succ_msg "Waited for $wait seconds for VM shutdown"
    fi
}

# setup_script
setup()
{
    echo "Not implemented! Please use the virtualbox-kernel.SlackBuild available at SlackBuilds.org instead."
}

dmnstatus()
{
    if running vboxdrv; then
        str="vboxdrv"
        if running vboxnetflt; then
            str="$str, vboxnetflt"
            if running vboxnetadp; then
                str="$str, vboxnetadp"
            fi
        fi
        if running vboxpci; then
            str="$str, vboxpci"
        fi
        echo "VirtualBox kernel modules ($str) are loaded."
        for i in $SHUTDOWN_USERS; do
            # don't create the ipcd directory with wrong permissions!
            if [ -d /tmp/.vbox-$i-ipc ]; then
                export VBOX_IPC_SOCKETID="$i"
                VMS=`$VBOXMANAGE --nologo list runningvms | sed -e 's/^".*".*{\(.*\)}/\1/' 2>/dev/null`
                if [ -n "$VMS" ]; then
                    echo "The following VMs are currently running:"
                    for v in $VMS; do
                       echo "  $v"
                    done
                fi
            fi
        done
    else
        echo "VirtualBox kernel module is not loaded."
    fi
}

case "$1" in
start)
    start
    ;;
stop)
    stop_vms
    stop
    ;;
stop_vms)
    stop_vms
    ;;
restart)
    stop && start
    ;;
setup)
    test -n "${2}" && export KERN_VER="${2}"
    # Create udev rule and USB device nodes.
    ## todo Wouldn't it make more sense to install the rule to /lib/udev?  This
    ## is not a user-created configuration file after all.
    ## todo Do we need a udev rule to create /dev/vboxdrv[u] at all?  We have
    ## working fall-back code here anyway, and the "right" code is more complex
    ## than the fall-back.  Unnecessary duplication?
    stop
    setup_usb "$GROUP" "$DEVICE_MODE" "$INSTALL_DIR"
    start
    ;;
force-reload)
    stop
    start
    ;;
status)
    dmnstatus
    ;;
*)
    echo "Usage: $0 {start|stop|stop_vms|restart|setup|force-reload|status}"
    exit 1
esac

exit 0
