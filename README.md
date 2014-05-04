#Not Yet Another Installer For OpenBSD

NYAIFO use the autoinstall(8) feature of OpenBSD 5.5 to create hand & console
free OpenBSD installation.

##Warning

It is the first time I mess with `/usr/src`, and play with compiling my own
image on an OpenBSD. So everything may feel hackish and/or dirty. Constructive
criticism more than welcome.

##What is this?

It is a series of guidelines (and in a near future, patch I hope) to create a
`miniroot55.fs` system, that will boot a server and automatically install
OpenBSD 5.5 on it.  Without the need to have an accessible console on this
server.

The short term goal here is to have an quick & dirty way to install OpenBSD
when you can not access the console output of the machine.

I would love to have feedback on this, since I am not really an OpenBSD hacker
:)

##What do you need

* A functional OpenBSD 5.5 somewhere (VM is okay, I have one in Virtualbox)
* The source tree (`src.tar.gz`)
* the `comp.tar.gz` set installed
