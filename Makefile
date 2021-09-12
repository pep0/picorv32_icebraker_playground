



CROSS=riscv64-unknown-elf-
CFLAGS=

FW_ADDRESS_OFFSET=1M

FW_NAME=picosoc_fw
FW_SOURCE_FILES=start.s firmware.c

GW_NAME=picosoc
GW_SOURCE_TOP=icebreaker
GW_SOURCE=icebreaker.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v picorv32.v



PIN_DEF=icebreaker.pcf
DEVICE=up5k
PACKAGE=sg48


prog: prog_gw prog_fw

clean: clean_gw clean_fw

include gateware.mk
include firmware.mk

