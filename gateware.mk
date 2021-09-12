
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

%_tb: %_tb.v %.v
	iverilog -g2012 -o $@ $^

%_tb.vcd: %_tb
	vvp -N $< +vcd=$@

%_syn.v: %.blif
	yosys -p 'read_blif -wideports $^; write_verilog $@'

%_syntb: %_tb.v %_syn.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_syntb.vcd: %_syntb
	vvp -N $< +vcd=$@

prog_gw: $(GW_NAME).bin
	iceprog $<

sudo-prog_gw: $(GW_NAME).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean_gw:
	rm -f $(GW_NAME).blif $(GW_NAME).asc $(GW_NAME).rpt $(GW_NAME).bin $(GW_NAME).json $(GW_NAME).log $(ADD_CLEAN)

.SECONDARY:
.PHONY: all prog_gw clean
