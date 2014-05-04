#Not Yet another installer for OpenBSD

NYaifO use the autoinstall(8) feature of OpenBSD 5.5 to create hand & console
free installation of OpenBSD.

#YES no code, but you do not need code or patch for this!

##Warning

It is the first time I mess with `/usr/src`, and play with compiling my own
image on an OpenBSD. So everything may{be| feel} hackish {and|or} dirty.
Constructive criticism more than welcome.

I do not cover cross compiling here, and I only test this with the amd64
distrib. But I do not see any reason that may prevent this to work on other
distrib.

##What is this?

It is a guide (and in a near future, a serie of patch) to create a
`miniroot55.fs` system, that will boot a server and automatically install
OpenBSD 5.5 on it.  Without the need to have an accessible console on this
server.

The short term goal here is to have an quick & dirty way to install OpenBSD
when you can not access the console output of the machine.

The long term may be to create a specifically tailored installer for this. See
that has a *really long term* objective.

I would love to have feedback on this, since I am not really an OpenBSD hacker
:)

##What do you need

  * A working OpenBSD 5.5 system (VM is okay, I use one in Virtualbox)
  * The `comp.tar.gz` set installed
  * The source tree in `/usr/src/` (`src.tar.gz` & `sys.tar.gz` from your
    favorite ftp)

##Support

  * Basic install of OpenBSD booting directly from your hard-drive

##Enhancement to do

  * A way to partition the disk using a definition file. Currently this use the
    default scheme, which may no fit your server need.
  * I think my make commands are suboptimal, compiling more that needed.

##How to do it

We are going to modify the miniroot source, which lay in
`/usr/src/distrib/miniroot`. This contains parts of the installation scripts.

###Create an install.conf

Create the file `/usr/src/distrib/miniroot/install.conf`. See autoinstall(8)
for more info.

Here is the one I will use for this demo:

```
System hostname = test_auto_install
Password for root = <the_root_password>
Do you expect to run the X Window System = no
What timezone are you in = Europe/Zurich
Use (W)hole disk = W
Location of sets = http
Server = ftp.ch.openbsd.org
```

*Avoid putting the root password in clear!* You can use encrypt(1) to generate
an encrypted version:

```
# encrypt -b 8
dummypass
$2a$08$ZOm7pTQh4R8veZ7NbMn9Nuw14o4.eTTbabtGZWo5x8COwg5FblD3W
^C
```

If you look in autoinstall(8) you will see that the `install.conf` file is just
`question = answer`. You are not forced to put the whole question, just a
non-ambiguous part (and no question mark).

When configuring the disk, OpenBSD will only used an existing OpenBSD area if
one exist. Because the `miniroot55.fs` will be dd(1) on the target hard drive,
an OpenBSD area will exist, but will only have a size of ~3.5MB. So we have to
add the `Use (W)hole disk = W` question in the answer file. Otherwise the
system will not use the whole disk.

###Add it to the miniroot files tree

Now modify `/usr/src/miniroot/list`, and add this lines somewhere:

```
# copy file in /
COPY    ${CURDIR}/install.conf                  install.conf
```

This will add our `install.conf` file in the root of the miniroot image.

###Modify the installation question

Since we do not boot using the netboot, the installation will not start
automatically.  So we are going to force to start. Que `(I)nstall, (U)pgrade,
(A)utoinstall or (S)hell?` interactive question is in
`/usr/src/miniroot/dot.profile`. Between the lines 92 and 123.

```
...
 92         while :; do
 93                echo -n '(I)nstall, (U)pgrade, (A)utoinstall or (S)hell? '
 94                read REPLY
...
120                !*)     eval "${REPLY#?}"
121                        ;;
122                esac
123         done
...
```

I have remove this whole part, and replaced it with:
```
/install -a -f install.conf
```

So as soon as the machine will have booted, it will launch the install script
in automatic mode (`-a`) with our answer file (`-f install.conf`).

###Automatically reboot at the end of the installation

Since we will not have any console, we will not be able to reboot the machine. In the file `/usr/src/distrib/miniroot/install.sub` you will
find the `finish_up()` function. Go to the end (line 2167), and add the reboot(8) command.

```
...
2163         [[ "$MODE" == upgrade ]] && \
2164                 echo "After rebooting, run sysmerge(8) to update your system configuration."
2165         $auto && >/ai.done
2166
2167         reboot
2168 }
...
```

Now the server will automatically reboot at the end of the installation.

###Build the image

First, go in `/usr/src/distrib/special` and build it:

```
# make clean
# make obj
# make
# make install
```

Then go in your distrib folder (`/usr/src/distrib/amd64` in my case) and build
the image with:

```
# make clean
# make obj
# make depend
# make
```

Take some time for you now, go make some tea, meditate. Obviously those step
will depends of the power of your machine.

When the compilation end, you will find the `miniroot55.fs` file in your
`/usr/src/<your_distrib>/ramdisk_cd/obj/miniroot55.fs`.

###Copy the miniroot & reboot your machine.

Now that you have your miniroot you will have to dd(1) it on the target
hardware. This step will greatly varies depending of your hoster. The basic
step are:

  * Make your image available from the network somewhere
  * Boot your server in rescue mode
  * Download your image, and dd(1) it.
  * Reboot your server

When the machine will reboot, it will boot in your miniroot images, launching
the installation. This may take time, so do not stress and continue to drink
you tea.

After some time your server will come back

###Done

You are done. I do not know what you thinks, but to me as an OpenBSD noob, I
found this easy enough to set up :)

##Pitfalls

  * The install only use DHCP for the network, ensure that will not lockup your
    box
  * Ensure all your hardware will be supported by the default kernel.
  * In general, think before acting. Read this completely before doing it.
    (Yes, the fact that this is at the end, is a test ;))

##Contributing

I would love to have feedback on this, and learn new things about OpenBSD, do
not hesitate to do constructive criticism. I am pretty sure this whole things
is far from perfect!

##Contact

  * By twitter: [@Mayeu](https://twitter.com/Mayeu)
  * By e-mail:
    * GPG key: A016 F2D8 0472 1186 1B33 A419 22B1 0496 B00D A693
    * Or see my [webpage](http://6x9.fr/contact)
