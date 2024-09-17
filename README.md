# slackware
A collection of slackware goodies

Slackbuild for virtualbox 7.0.18
tested on slackware current. (with 6.9.0 testing or stock



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
KERNEL=6.9.0 HARDENING=yes ./virtualbox-kernel.SlackBuild
```
