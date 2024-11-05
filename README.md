# configfs

This little tool helps to create a USB OTG gadget from an embedded device with the help of configfs. The USB functionality is generated via the functionfs (ffs).

## Requirements
* A ffs userspace tool like [this](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/tools/usb/ffs-aio-example/simple/device_app/aio_simple.c?h=v5.10.12) or check [these](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/tools/usb?h=v5.10.12).


## How to use ?
* Update script variables for your specific environment (UDC, FFS_DIR, APP, ..) 
* The tool expects the ffs programm in `~/ffs/aio_simple`

```sh
# Start (
> ./start_usb_gadget.sh -f

# Stop
> ./start_usb_gadget.sh

```

## Misc
* Sourcesink (`./start_usb_gadget.sh -s`) and
* Loopback (`./start_usb_gadget.sh -l`) is for debugging purposes
