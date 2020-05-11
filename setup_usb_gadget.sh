#!/bin/bash

G1=/sys/kernel/config/usb_gadget/g1
UDC=ci_hdrc.0 # see /sys/class/udc/* for UDC name
FFS_DIR=~/ffs
APP=~/aio_simple
idVendor=0xfffe
idProduct=0xa4a4

function ffs_app() {
    # Caution: Starting and stopping the ffs app is very application specific.
    # It is very likely that the start and stop cases will need to be adjusted
    case "$1" in
        start) $APP $FFS_DIR & ;;
        stop) killall -s SIGTERM $(basename $APP) ;;
        *) echo "ffs_app(): unknown pattern" ;;
    esac
    sleep 0.01
}

function init_usb_gadget() {
    # create usb gadget
    mkdir $G1 && cd $G1
    echo $idVendor > idVendor
    echo $idProduct > idProduct
    mkdir strings/0x409
    mkdir configs/c.1
    mkdir configs/c.1/strings/0x409
    echo 2 > configs/c.1/MaxPower
    mkdir functions/ffs.usb0
    ln -s functions/ffs.usb0 configs/c.1/

    # create functionfs
    mkdir -p $FFS_DIR
    mount usb0 $FFS_DIR -t functionfs

    # start functionfs application
    ffs_app start

    # start usb gadget
    echo $UDC > $G1/UDC
}

function deinit_usb_gadget() {
    # stop usb gadget
    echo "" > $G1/UDC

    # stop functionfs application
    ffs_app stop

    # clean up
    umount $FFS_DIR
    rmdir $FFS_DIR
    cd $G1
    rm configs/c.1/ffs.usb0
    rmdir configs/c.1/strings/0x409
    rmdir configs/c.1
    rmdir functions/ffs.usb0
    rmdir strings/0x409
    cd ~
    rmdir $G1
}

if [[ ! -d $G1 ]]; then
    init_usb_gadget
else
    read -r -p "Remove gadget? [yN]" a
    [[ $a == y ]] && deinit_usb_gadget
fi

