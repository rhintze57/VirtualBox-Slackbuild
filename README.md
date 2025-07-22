# slackware
A collection of slackware goodies

Slackbuild for virtualbox 7.1.12
tested on slackware current. (with 6.12.39 testing or stock
 - Seems there is a need to uninstall older versions before installing


Dependancies:  acpica, virtualbox-kernel
(both available at slackbuilds.org)
 

The SlackBuilds here are just modified versions from slackbuilds.org

To download the need source files run this: (in each folder)

```
./download_needed.sh
```

I use :
```
HARDENING=yes ./virtualbox.SlackBuild
KERNEL=6.12.39 HARDENING=yes ./virtualbox-kernel.SlackBuild
```

add this to bootloader options (elilo, grub, or refined):
```
kvm.enable_virt_at_load=0
sample:
[elilo]
append="root=PARTUUID=xxxxxxxxxx-xxxxxxx-xxxxxx kvm.enable_virt_at_load=0  vga=normal ro"
[refined]
options "ro root=PARTUUID=xxxxxxxxxx-xxxxx-xxxxx kvm.enable_virt_at_load=0"

```
or  (found on linuxquestions)
Just create /etc/modprobe.d/virtualbox.conf with content:
```
options kvm enable_virt_at_load=0
```
