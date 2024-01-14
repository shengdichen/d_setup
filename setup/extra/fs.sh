#!/usr/bin/env dash

__swapfile() {
    return
}

__swapfile_edit() {
    # 1. rename root-parition
    # # sudo e2label /dev/sda<ROOT> "ROOT"
    # NOTE:
    #   1. the label will NOT showup until remounting partition, in the case of a root partition: until reboot
    #   2. verify with |$ blkid|

    # 2. swapfile

    # 3. edit /etc/fstab
    #       LABEL=ROOT / ext4 rw,relatime 0 1
    #       /SWAP none swap defaults 0 0

    return
}
