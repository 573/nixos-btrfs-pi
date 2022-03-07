#!/usr/bin/env bash

set -Eeuf -o pipefail
set -x

make_swap() {
  umount -R /mnt/swap || true
  mkdir -p /mnt/swap
  mount -o subvol=@swap /dev/mmcblk0p2 /mnt/swap

  [[ -e /mnt/swap/swapfile ]] && {
    umount -R /mnt/swap
    return
  }

  pushd /mnt/swap
  touch ./swapfile
  chattr +C ./swapfile
  btrfs property set ./swapfile compression none
  dd if=/dev/zero of=./swapfile bs=1M count=1024 status=progress conv=fsync
  chmod 0600 ./swapfile
  mkswap ./swapfile
  popd
  umount -R /mnt/swap
  rm -r /mnt/swap
}

install() {
  nix-channel --update
  nixos-install \
    --root / \
    --no-root-passwd \
    --max-jobs "$(nproc)" \
    --no-bootloader
}

main() {
  make_swap
  install
  reboot
}

main "$@"