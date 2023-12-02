#!/bin/bash

nix-env -iA nixos.wget
nix-shell -p wget squashfsTools && bash ./install.sh

check_existence "mount"
check_existence "modprobe"
check_existence "chroot"
check_existence "wget"
check_existence "sed"
check_existence "grep"
check_existence "unsquashfs"
check_existence "mktemp"
check_existence "id"
check_existence "sha256sum"

# This script will create a crypted boot, btrfs filesystem with a swapfile
# It will download and install the latest nix os distribution
# The system will have the systemd-bootloader to open the crypted boot by label
# The script will clone a nix config from a git repo apply it and then reboot

# Set some variables
BOOT_LABEL="boot"
BOOT_SIZE="512M"
SWAP_SIZE="1G"
ROOT_LABEL="root"
NIX_URL="https://channels.nixos.org/nixos-21.11/latest-nixos-minimal-x86_64-linux.iso"
NIX_FILE="nixos.iso"
NIX_DEV="/dev/disk/by-label/NIXOS_ISO"
GIT_REPO="https://github.com/user/nix-config.git"
GIT_DIR="/mnt/etc/nixos"

# Create partitions
echo "Creating partitions..."
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MiB 100%

# Encrypt boot partition
echo "Encrypting root partition..."
echo -n "Enter encryption password: "
read -s ENCRYPTION_PASSWORD
echo
cryptsetup -q luksFormat /dev/sda1 -d <(echo -n "$ENCRYPTION_PASSWORD")
cryptsetup luksOpen /dev/sda1 "$ROOT_LABEL" -d <(echo -n "$ENCRYPTION_PASSWORD")

# Create logical volumes
echo "Creating logical volumes..."
pvcreate "/dev/mapper/$ROOT_LABEL"
vgcreate vg "/dev/mapper/$ROOT_LABEL"
lvcreate -L "$BOOT_SIZE" -n boot vg
lvcreate -l 100%FREE -n root vg

# Create filesystems
echo "Creating filesystems..."
mkfs.vfat -F 32 -n boot /dev/vg/boot
mkfs.btrfs -f -L root /dev/vg/root

# Mount filesystems
echo "Mounting filesystems..."
mount /dev/mapper/vg-root /mnt
mkdir -p /mnt/boot
mount /dev/mapper/vg-boot /mnt/boot

# Create swapfile
echo "Creating swapfile..."
truncate -s 0 /mnt/swapfile
chattr +C /mnt/swapfile
btrfs property set /mnt/swapfile compression none
fallocate -l "$SWAP_SIZE" /mnt/swapfile
chmod 600 /mnt/swapfile
#mkswap /mnt/swapfile
#swapon /mnt/swapfile

# Copy configuration
mkdir -p /mnt/etc/nixos
cp ./configuration.nix /mnt/etc/nixos/configuration.nix

# Install nix
echo "Entering chroot environment..."
cd ~
mkdir -p inst host/nix
wget $NIX_URL -O $NIX_FILE
modprobe loop
mount -o loop $NIX_FILE inst
unsquashfs -d host/nix/store inst/nix-store.squashfs '*'

cd host
mkdir -p etc dev proc sys
cp /etc/resolv.conf etc
for fn in dev proc sys; do mount --bind "/${fn}" "${fn}"; done

INIT=$(find . -type f -path '*nixos*/init')
BASH=$(find . -type f -path '*/bin/bash' | tail -n 1)
mount ./nix/store -o remount,rw
sed -i "s,exec /.*systemd,exec /$BASH," $INIT

chroot . /$INIT

echo "Creating NixOS configuration..."
nixos-generate-config --root /mnt

echo "Installing NixOS..."
NIX_PATH="nixpkgs=channel:nixos-21.11" nixos-install

echo "Exiting chroot environment..."
exit


# Clone nix config from git repo
#echo "Cloning nix config from git repo..."
#git clone "$GIT_REPO" "$GIT_DIR"

# Apply nix config
echo "Applying nix config..."
nixos-rebuild switch

# Reboot
echo "Rebooting..."
#reboot
