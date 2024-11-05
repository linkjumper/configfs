#!/bin/bash

G1=/sys/kernel/config/usb_gadget/g1
UDC=ci_hdrc.0
idVendor=0x0525
idProduct=0xa4a5
manufacturer="NetChip"
product="Linux File-Backed Storage"
serialnumber=12345

function usage() {
    echo "Usage: $0 [-f <BLK_DEV_FILENAME>]"
    exit 1
}

function parse_args() {
    [[ $# == 0 ]] && usage

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f)
                shift
                if [[ -z "$1" || "$1" == -* ]]; then
                    echo "Error: -f requires a block device filename"
                    usage
                else
                	if [[ ! -b "$1" ]]; then
                		echo "Error: -f $1 is no block device"
                		usage
                	fi
                    blk_device="$1" # e.g. /dev/mmcblk0p2
                fi
                ;;
            *)
                usage
                ;;
        esac
        shift
    done
}

function setup_mass_storage() {
    # Create usb gadget
    mkdir $G1 && cd $G1 || exit 1
    echo "$idVendor" > idVendor
    echo "$idProduct" > idProduct
    mkdir strings/0x409
    echo "$manufacturer" > strings/0x409/manufacturer
    echo "$product" > strings/0x409/product
    echo "$serialnumber" > strings/0x409/serialnumber
    mkdir -p configs/c.1/strings/0x409
    echo 40 > configs/c.1/MaxPower
    mkdir functions/mass_storage.usb0
    ln -s functions/mass_storage.usb0 configs/c.1/
    echo "$blk_device" > functions/mass_storage.usb0/lun.0/file

    # Start the UDC
    echo $UDC > $G1/UDC
}

function cleanup_mass_storage() {
    # Only stop the UDC if it is still active
    if [[ -n $(cat $G1/UDC) ]]; then
        echo "" > $G1/UDC
    fi
    rm $G1/configs/c.1/mass_storage.usb0
    rmdir $G1/functions/mass_storage.usb0
    rmdir $G1/configs/c.1/strings/0x409
    rmdir $G1/configs/c.1
    rmdir $G1/strings/0x409
    rmdir $G1
}

if [[ ! -d $G1 ]]; then
    parse_args "$@"
    setup_mass_storage
else
    read -r -p "Remove USB Gadget Mass Storage? [yN]" a
    [[ $a == y ]] && cleanup_mass_storage
fi

