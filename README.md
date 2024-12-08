# slackware
A collection of slackware goodies

Slackbuild for virtualbox 7.1.4
tested on slackware current. (with 6.12.3 testing or stock
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
KERNEL=6.12.3 HARDENING=yes ./virtualbox-kernel.SlackBuild
```

add this to bootloader options (elilo, grub, or refined):
```
kvm.enable_virt_at_load=0
sample:
options "ro root=PARTUUID=xxxxxxxxxx-xxxxx-xxxxx kvm.enable_virt_at_load=0"
```
