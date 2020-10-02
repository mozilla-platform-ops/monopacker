Building the kernel
===================

Best to do this on a fresh VM in a cloud, running the desired distribution.

* `rev=5.4.0-1024-aws`
* Enable source repositories in `/etc/apt/sources.list`
```
deb-src http://archive.ubuntu.com/ubuntu bionic main
deb-src http://archive.ubuntu.com/ubuntu bionic-updates main
```
* `sudo apt-get build-dep linux linux-image-$rev`
* `sudo apt-get install libncurses-dev flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf fakeroot gcc-aarch64-linux-gnu` (cross-compiler appears to be necessary to run `editconfigs` below, but this does not build aarch64 images)
* `apt-get source linux-image-$rev`
* `cd /root/linux-*`
* `chmod a+x debian/rules`
* `chmod a+x debian/scripts/*`
* `chmod a+x debian/scripts/misc/*`
* `fakeroot debian/rules clean`
* `fakeroot debian/rules editconfigs`

Use the `menuconfig` interface for the amd64 config to set the following configurations.  There is no need to edit the arm64 config.

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
* `fakeroot debian/rules binary-headers binary-aws binary-perarch` (this will take *hours*)
* `cd ..`
* `ls *.deb`

Copy those `*.deb` files into this directory and point to them in `scripts/ubuntu-bionic/01-kernel.sh`.
