
all: $(GW_NAME).rpt $(GW_NAME).bin

%.blif: $(GW_SOURCE)
	yosys -ql $*.log -p 'synth_ice40 -top $(GW_SOURCE_TOP) -blif $@' $

%.json: $(GW_SOURCE)
	yosys -ql $*.log -p 'synth_ice40 -top $(GW_SOURCE_TOP) -json $@' $^

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) $(if $(PACKAGE),--package $(PACKAGE)) $(if $(FREQ),--freq $(FREQ)) --json $(filter-out $<,$^) --pcf $< --asc $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime $(if $(FREQ),-c $(FREQ)) -d $(DEVICE) -mtr $@ $<

%_tb.vvp: %_tb.v $(GW_SOURCE) $(GW_SIM)
	iverilog -g2012 -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_tb.vcd: %_tb.vvp
	vvp -N $< +vcd=$@ $(if $(FW_NAME),+firmware=$(FW_NAME).hex)

sim_gw_fw: $(FW_NAME).hex $(GW_NAME)_tb.vcd

prog_gw: $(GW_NAME).bin
	iceprog $<

sudo-prog_gw: $(GW_NAME).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean_gw:
	rm -f $(GW_NAME).blif $(GW_NAME).asc $(GW_NAME).rpt $(GW_NAME).bin $(GW_NAME).json $(GW_NAME).log $(GW_NAME)_tb.vvp $(ADD_CLEAN)

.SECONDARY:
.PHONY: all prog_gw clean
