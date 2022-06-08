# slackware
A collection of slackware goodies

Slackbuild for virtualbox 6.1.34
tested on slackware current. (with 5.15.17 testing or stock



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
