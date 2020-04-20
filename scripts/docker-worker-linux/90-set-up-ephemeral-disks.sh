#!/bin/bash

set -exv

# init helpers
helpers_dir=${MONOPACKER_HELPERS_DIR:-"/etc/monopacker/scripts"}
. ${helpers_dir}/*.sh

# This is copied over from docker-worker almost verbatim but
# with a modified grep for nvme0 to get devices. This should
# work in both aws and google


disk_setup_script="/usr/local/bin/configure-docker-worker-disks"

cat << EOF > "${disk_setup_script}"
#!/bin/bash -vxe

# The goal of this script is to initialize instance storage.
# We create an LVM logical volume from all available storage devices,
# format it, mount it, and ensure basic structure is in place.

# Create logical volume
# Do not attempt to create if volume already exists (upstart respawn).
if ! lvdisplay | grep instance_storage; then
    echo "Creating logical volume 'instance_storage'"
    # Find instance storage devices
    # c5 and newer has nvme* devices. The nvmeN devices can't be used
    # with vgcreate. But nvmeNnN can.
    root_device=\$(mount | grep " / " | awk '{print \$1}')
    if [ -e /dev/nvme0 ]; then
        # root device is /dev/nvme[0-9]
        root_device=\${root_device:0:10}
        devices=\$(ls -1 /dev/nvme*n* | grep -v "\${root_device}")
    else
        # root device is /dev/xvd[a-z]
        root_device=\${root_device:0:9}
        devices=\$(ls -1 /dev/xvd* | grep -v "\${root_device}")
    fi

    if [ -z "\${devices}" ]; then
        echo "could not find devices to use for instance storage"
        exit 1
    fi

    echo "Found devices: \$devices"

    # Unmount block-device if already mounted, the first block-device always is
    for d in \$devices; do umount \$d || true; done

    # Create volume group containing all instance storage devices
    echo \$devices | xargs vgcreate -y instance_storage

    # Create logical volume with all storage
    lvcreate -y -l 100%VG -n all instance_storage
else
    echo "Logical volume 'instance_storage' already exists"
fi

# Check to see if instance_storage-all is mounted already
if ! df -T /dev/mapper/instance_storage-all | grep 'ext4'; then
    # Format logical volume with ext4
    echo "Logical volume does not appear mounted."
    echo "Formating 'instance_storage' as ext4"

    if ! mkfs.ext4 /dev/instance_storage/all; then
        echo "Could not format 'instance_storage' as ext4."
        exit 1
    else
        echo "Succesfully formated 'instance_storage' as ext4."
        echo "Mounting logical volume"

        # Our assumption is that workers are ephemeral. If errors are encountered, the
        # worker should be thrown away. Workers are never rebooted. So filesystem
        # durability isn't too important to us.

        # Default mount options: rw,relatime,errors=remount-ro,data=ordered
        #
        # We make the following changes:
        #
        # errors=panic -- The worker is unusable if the mount isn't writable. So
        # panic if we encounter this.
        #
        # data=writeback -- Don't require write ordering between journal and main
        # filesystem. Since we don't have a separate journal device, this probably
        # does little. But in theory it relaxes durability so it shouldn't hurt.
        #
        # nobarrier -- Loosen restrictions around writes to journal.
        #
        # commit=60 -- By default, ext4 tries to sync every 5s to ensure
        # minimal data loss in case of system failure. We increase that to 60s to
        # avoid excessive filesystem sync. The filesystem will still write out
        # changes in the background. And a sync() issued by an application can
        # still force a full flush sooner. But ext4 itself won't be flushing all
        # changes as often.
        mount -o 'rw,relatime,errors=panic,data=writeback,nobarrier,commit=60' /dev/instance_storage/all /mnt
    fi
else
    echo "Logical volume 'instance_storage' is already mounted."
fi

echo "Creating docker specific directories"
mkdir -p /mnt/var/lib/docker
mkdir -p /mnt/docker-tmp
mkdir -p /mnt/var/cache/docker-worker
EOF

file "${disk_setup_script}"
chmod +x "${disk_setup_script}"

cat << EOF > /etc/systemd/system/docker-worker-disk-setup.service
[Unit]
Description=Taskcluster docker worker ephemeral disk setup
Before=docker.service

[Service]
Type=oneshot
ExecStart=${disk_setup_script}
User=root

[Install]
RequiredBy=multi-user.target
EOF

systemctl enable docker-worker-disk-setup

cat << EOF > /etc/docker/daemon.json
{
  "data-root": "/mnt/var/lib/docker",
  "storage-driver": "overlay2",
  "ipv6": true,
  "fixed-cidr-v6": "fd15:4ba5:5a2b:100a::/64",
  "icc": false,
  "iptables": true
}
EOF
