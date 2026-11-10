#!/bin/sh
set -e
cd "$(dirname "$0")"
iverilog -g2012 -o tb.vvp ../rtl/btn_sync.sv ../rtl/seg7.sv ../rtl/safecrack_fsm.sv ../rtl/safecrack_top.sv tb_safecrack.sv
vvp tb.vvp
python3 plot_waves.py
