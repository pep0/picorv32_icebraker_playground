
prog_fw: $(FW_NAME).bin
	iceprog -o $(FW_ADDRESS_OFFSET) $(FW_NAME).bin

clean_fw:
	rm -f $(FW_NAME)_sections.lds $(FW_NAME).elf $(FW_NAME).hex $(FW_NAME).bin

$(FW_NAME)_sections.lds: $(FW_DIR)/sections.lds
	$(CROSS)cpp -P -DICEBREAKER -o $@ $^

$(FW_NAME).elf: $(FW_NAME)_sections.lds $(FW_SOURCE_FILES)
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -march=rv32i -mabi=ilp32 -Wl,-Bstatic,-T,$(FW_NAME)_sections.lds,--strip-debug -ffreestanding -nostdlib -o $(FW_NAME).elf $(FW_SOURCE_FILES)

$(FW_NAME).hex: $(FW_NAME).elf
	$(CROSS)objcopy -O verilog $(FW_NAME).elf $(FW_NAME).hex

$(FW_NAME).bin: $(FW_NAME).elf
	$(CROSS)objcopy -O binary $(FW_NAME).elf $(FW_NAME).bin


.SECONDARY:
.PHONY: all prog_fw clean
