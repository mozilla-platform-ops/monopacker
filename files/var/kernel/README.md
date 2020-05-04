Building the kernel
===================

* Enable source repositories in `/etc/apt/sources.list`
```
  deb-src http://archive.ubuntu.com/ubuntu bionic main
  deb-src http://archive.ubuntu.com/ubuntu bionic-updates main
```
* `sudo apt-get build-dep linux linux-image-$(uname -r)`
* `sudo apt-get install libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf`
* `apt-get source linux-image-$(uname -r)`
* `cd linux-image*`
* `chmod a+x debian/rules`
* `chmod a+x debian/scripts/*`
* `chmod a+x debian/scripts/misc/*`
* `fakeroot debian/rules clean`
* `fakeroot debian/rules editconfigs`

Make sure the `menuconfig` matches the following configurations:

```
Device Driver -->
  <M> Multimedia support -->
    [*] Cameras/video grabbers support
  <M> Sound card support -->
    <M> Advanced Linux Sound Architecture -->
      [*] Generic sound devices -->
        <M> Generic loopback driver
      [*] Dynamic device file minor number -->
        (96) Max number of sound cards
```

* `fakeroot debian/rules clean`
* `fakeroot debian/rules binary-headers binary-aws binary-perarch`
* `cd ..`
* `ls *.deb`

Building `v4l2loopback`
=======================

* `export version=0.12.5`
* `sudo git clone -b v$version git://github.com/umlaeute/v4l2loopback /usr/src/v4l2loopback-$version`
* Edit the file `v4l2looback.c` and change the `MAX_DEVICES` definition to `96`
* `sudo dkms build -k $(uname -r) -m v4l2loopback -v $version`
* `sudo dkms mkdeb -k $(uname -r) -m v4l2loopback -v $version`
* The `deb` package is available at `/var/lib/dkms/v4l2loopback/$version/deb/`
