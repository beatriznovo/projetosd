// safecrack_top: modulo de topo, liga a FSM aos pinos da DE2-115
module safecrack_top #(
    parameter int CLK_HZ = 50_000_000   // clock da placa; a simulacao usa um valor menor
)(
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,

    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,
    output logic [8:0]  LEDG,
    output logic [17:0] LEDR
);

    // senha do cofre: 1, 2, 3, 4
    localparam logic [15:0] SENHA = 16'h1234;

    logic [3:0] dig0, dig1, dig2, dig3;
    logic [1:0] idx;
    logic       ativo;
    logic [3:0] idx_exibido;

    // HEX4 mostra o digito ativo de 1 a 4 (para mostrar de 0 a 3, retire o + 4'd1)
    assign idx_exibido = {2'b00, idx} + 4'd1;

    safecrack_fsm #(
        .SENHA (SENHA),
        .CLK_HZ(CLK_HZ)
    ) u_fsm (
        .clk      (CLOCK_50),
        .key      (KEY),
        .dig0     (dig0),
        .dig1     (dig1),
        .dig2     (dig2),
        .dig3     (dig3),
        .idx      (idx),
        .ativo    (ativo),
        .led_green(LEDG),
        .led_red  (LEDR)
    );

    // HEX3 e o primeiro digito e HEX0 e o quarto
    seg7 u_hex3 (.value(dig0),        .blank(1'b0),   .hex(HEX3));
    seg7 u_hex2 (.value(dig1),        .blank(1'b0),   .hex(HEX2));
    seg7 u_hex1 (.value(dig2),        .blank(1'b0),   .hex(HEX1));
    seg7 u_hex0 (.value(dig3),        .blank(1'b0),   .hex(HEX0));
    // HEX4 fica apagado durante o feedback, quando nenhum digito esta sendo editado
    seg7 u_hex4 (.value(idx_exibido), .blank(~ativo), .hex(HEX4));

endmodule
