#!/usr/bin/env bash

set -e

if [ -z "${ARCH_INSTALL_TARGET_DISK}" ]; then
    echo "Error: ARCH_INSTALL_TARGET_DISK not set"
    exit 1
fi

parted -s "${ARCH_INSTALL_TARGET_DISK}" mklabel gpt mkpart ArchBoot fat32 1MiB 1025MiB mkpart ArchRoot ext4 1025MiB 100%

boot_part_path=/dev/$(lsblk -ln ${ARCH_INSTALL_TARGET_DISK} -o partn,name | grep -w 1 | cut -f3 -d' ')
root_part_path=/dev/$(lsblk -ln ${ARCH_INSTALL_TARGET_DISK} -o partn,name | grep -w 2 | cut -f3 -d' ')

mkfs.fat -F32 -n ArchBoot "${boot_part_path}"
mkfs.ext4 -L ArchRoot "${root_part_path}"

mount LABEL=ArchRoot /mnt
mount --mkdir LABEL=ArchBoot /mnt/boot

pacstrap -K /mnt base linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bash -c "curl https://raw.githubusercontent.com/riridotdev/arch-install-script/refs/heads/main/sync.sh | bash"

echo "Set root password..."
arch-chroot /mnt passwd

efibootmgr --create --disk "${ARCH_INSTALL_TARGET_DISK}" --part 1 --label "Arch Linux" \
    --loader /vmlinuz-linux --unicode 'root=LABEL=ArchRoot rw initrd=\initramfs-linux.img'
