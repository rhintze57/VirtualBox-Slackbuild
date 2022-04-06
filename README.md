# slackware
A collection of slackware goodies

Slackbuild for virtualbox 6.1.32
tested on slackware current. (with 5.15.17 testing or stock)

**** the version on https://www.slackbuilds.org/repository/15.0/system/virtualbox/ is the same version ****

(I would use their version ;) this was always based on it anyway



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
KERNEL=5.15.17 HARDENING=yes ./virtualbox-kernel.SlackBuild
```
