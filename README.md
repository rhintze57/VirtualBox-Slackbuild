# slackware
A collection of slackware goodies

Slackbuild for virtualbox 6.1.28
tested on slackware current. (with 5.14.14 testing or stock)


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
KERNEL=5.14.14 HARDENING=yes ./virtualbox-kernel.SlackBuild
```
