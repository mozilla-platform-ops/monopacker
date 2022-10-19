Building the kernel
===================

Best to do this on a fresh VM in a cloud, running the desired distribution.

* `export rev=5.15.0-1022-aws`
* Enable source repositories in `/etc/apt/sources.list`
```
deb-src http://archive.ubuntu.com/ubuntu jammy main
deb-src http://archive.ubuntu.com/ubuntu jammy-updates main
```
* `sudo apt-get update`
* `sudo apt-get build-dep linux linux-image-$rev`
* `sudo apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf llvm fakeroot gcc-aarch64-linux-gnu` (cross-compiler appears to be necessary to run `editconfigs` below, but this does not build aarch64 images)
* `apt-get source linux-image-unsigned-$(uname -r)`
* `cd linux-aws-<x.y.z>`
* `chmod a+x debian/rules`
* `chmod a+x debian/scripts/*`
* `chmod a+x debian/scripts/misc/*`
* `LANG=C fakeroot debian/rules clean`
* `vim debian.aws/config/annotations` and find the following strings:
  - `CONFIG_SND_MAX_CARDS` and change the `amd64` value to `96`
  - `CONFIG_SND_DYNAMIC_MINORS` and change the `amd64` value to `y`
* `LANG=C fakeroot debian/rules editconfigs`

Use the `menuconfig` interface for the amd64 config to set the following configurations.  There is no need to edit the arm64 config.

```bash
Device Driver -->
  <M> Multimedia support -->
    Media device types -->
      [*] Cameras and video grabbers
  <M> Sound card support -->
    <M> Advanced Linux Sound Architecture -->
      [*] Generic sound devices -->
        <M> Generic loopback driver (PCM)
      [*] Dynamic device file minor numbers -->
        (96) Max number of sound cards
```

* `LANG=C fakeroot debian/rules clean`
* `LANG=C fakeroot debian/rules binary-headers binary-aws binary-perarch` (this will take *hours*)
* `cd ..`
* `ls *.deb`

Copy those `*.deb` files into this directory and point to them in `scripts/ubuntu-bionic/01-kernel.sh`.
