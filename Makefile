



CROSS=riscv64-unknown-elf-
CFLAGS=

FW_ADDRESS_OFFSET=1M

OUT_DIR=build
FW_DIR=firmware
GW_DIR=gateware

FW_NAME=$(OUT_DIR)/picosoc_fw
FW_SOURCE_FILES=$(FW_DIR)/start.s $(FW_DIR)/firmware.c

GW_NAME=$(OUT_DIR)/icebreaker_psoc
GW_SOURCE_TOP=icebreaker
GW_SOURCE=$(GW_DIR)/icebreaker_psoc.v $(GW_DIR)/ice40up5k_spram.v $(GW_DIR)/spimemio.v $(GW_DIR)/simpleuart.v $(GW_DIR)/picosoc.v $(GW_DIR)/picorv32.v
GW_SIM=$(GW_DIR)/spiflash.v



PIN_DEF=$(GW_DIR)/icebreaker.pcf
DEVICE=up5k
PACKAGE=sg48


prog: prog_gw prog_fw

clean: clean_gw clean_fw

ser:
	screen /dev/tty.usbserial-ib4QuhwC1 115200

include gateware.mk
include firmware.mk

