# script do ModelSim/Questa: rode com "do simulate.do" dentro da pasta sim
vlib work
vlog -sv ../rtl/btn_sync.sv ../rtl/seg7.sv ../rtl/safecrack_fsm.sv ../rtl/safecrack_top.sv tb_safecrack.sv
vsim -onfinish stop -voptargs=+acc work.tb_safecrack

add wave -divider "ENTRADAS"
add wave -label "CLOCK_50"        /tb_safecrack/CLOCK_50
add wave -label "KEY[3:0]"        /tb_safecrack/KEY

add wave -divider "FSM"
add wave -label "estado"          /tb_safecrack/dut/u_fsm/state
add wave -label "contador"        -radix unsigned /tb_safecrack/dut/u_fsm/delay_cnt

add wave -divider "DIGITOS"
add wave -label "dig0 (HEX3)"     -radix unsigned /tb_safecrack/dut/u_fsm/dig0
add wave -label "dig1 (HEX2)"     -radix unsigned /tb_safecrack/dut/u_fsm/dig1
add wave -label "dig2 (HEX1)"     -radix unsigned /tb_safecrack/dut/u_fsm/dig2
add wave -label "dig3 (HEX0)"     -radix unsigned /tb_safecrack/dut/u_fsm/dig3
add wave -label "indice ativo"    -radix unsigned /tb_safecrack/dut/u_fsm/idx

add wave -divider "PULSOS DOS BOTOES"
add wave -label "reset"           /tb_safecrack/dut/u_fsm/rst_lvl
add wave -label "confirma"        /tb_safecrack/dut/u_fsm/ok_pls
add wave -label "incrementa"      /tb_safecrack/dut/u_fsm/inc_pls
add wave -label "decrementa"      /tb_safecrack/dut/u_fsm/dec_pls

add wave -divider "SAIDAS"
add wave -label "HEX4"            -radix binary /tb_safecrack/HEX4
add wave -label "LEDG"            /tb_safecrack/LEDG
add wave -label "LEDR"            /tb_safecrack/LEDR

run -all
wave zoom full
