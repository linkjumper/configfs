#!/bin/bash

# todo
# - generic UDC param
# - remove sleep 1 in function ffs_app() 
# - handle error if udc stop fails

G1=/sys/kernel/config/usb_gadget/g1
UDC=ci_hdrc.0 # see /sys/class/udc/* for UDC name
FFS_DIR=~/ffs
APP=~/aio_simple
idVendor=0xfffe
idProduct=0xa4a4
manufacturer="Foo, Inc."
product="Bar Gadget"
serialnumber=12345

function usage() {
    echo "Usage: $0 [-l|-s|-f]"
    echo "  Enable one or more usb gadget functions:"
    echo "  -l Loopback"
    echo "  -s SourceSink"
    echo "  -f FFS"
}

function parse_args() {
    [[ $# == 0 ]] && usage && exit
    for arg in "$@"
    do
        case "$arg" in
            "-l") lb=1 ;;
            "-s") ss=1 ;;
            "-f") ffs=1 ;;
            *) usage;
               exit ;;
        esac
    done
}

function ffs_app() {
    # Caution: Starting and stopping the ffs app is very application specific.
    # It is very likely that the start and stop cases will need to be adjusted
    case "$1" in
        start) $APP $FFS_DIR & ;;
        stop) pid=$(pidof $(basename $APP))
              if [[ $pid ]]; then
                  kill -s SIGTERM $pid
              fi ;;
        *) echo "ffs_app(): unknown pattern" ;;
    esac
    sleep 1
}

function init_usb_gadget() {
    # create usb gadget
    mkdir $G1 && cd $G1
    echo $idVendor > idVendor
    echo $idProduct > idProduct
    mkdir strings/0x409
    echo $manufacturer > strings/0x409/manufacturer
    echo $product > strings/0x409/product
    echo $serialnumber > strings/0x409/serialnumber
    mkdir configs/c.1
    mkdir configs/c.1/strings/0x409
    echo 2 > configs/c.1/MaxPower

    if [[ $ffs ]]; then
        # link ffs
        mkdir functions/ffs.usb0
        ln -s functions/ffs.usb0 configs/c.1/
        mkdir -p $FFS_DIR
        mount usb0 $FFS_DIR -t functionfs
        ffs_app start
    fi

    if [[ $lb ]]; then
        # link loopback
        mkdir functions/Loopback.usb0
        ln -s functions/Loopback.usb0 configs/c.1/
    fi
    
    if [[ $ss ]]; then
        # link sourcesink
        mkdir functions/SourceSink.usb0
        ln -s functions/SourceSink.usb0 configs/c.1/
    fi

    # Start the UDC
    echo $UDC > $G1/UDC
}

function deinit_usb_gadget() {
    # Only stop the UDC if it is still active
    if [[ -n $(cat $G1/UDC) ]]; then
        echo "" > $G1/UDC
    fi

    # clean up
    cd $G1
    
    if [[ -d "configs/c.1/ffs.usb0" ]]; then
        #unlink ffs
        ffs_app stop
        umount $FFS_DIR
        rmdir $FFS_DIR
        rm configs/c.1/ffs.usb0
        rmdir functions/ffs.usb0
    fi

    if [[ -d "configs/c.1/Loopback.usb0" ]]; then
        #unlink loopback
        rm configs/c.1/Loopback.usb0
        rmdir functions/Loopback.usb0
    fi
    
    if [[ -d "configs/c.1/SourceSink.usb0" ]]; then
        #unlink sourcesink
        rm configs/c.1/SourceSink.usb0
        rmdir functions/SourceSink.usb0
    fi
    
    rmdir configs/c.1/strings/0x409
    rmdir configs/c.1
    rmdir strings/0x409
    cd ~
    rmdir $G1
}

if [[ ! -d $G1 ]]; then
    parse_args $@
    init_usb_gadget
else
    read -r -p "Remove gadget? [yN]" a
    [[ $a == y ]] && deinit_usb_gadget
fi

