// seg7: converte um digito de 0 a 9 nos 7 segmentos do display da DE2-115
// os displays da placa sao ativos em nivel baixo: 0 acende o segmento, 1 apaga
// ordem dos bits: hex[6:0] = {g, f, e, d, c, b, a}
module seg7 (
    input  logic [3:0] value,
    input  logic       blank,   // 1 apaga o display inteiro
    output logic [6:0] hex
);

    always_comb begin
        if (blank) begin
            hex = 7'b1111111;
        end
        else begin
            unique case (value)
                4'd0:    hex = 7'b1000000;
                4'd1:    hex = 7'b1111001;
                4'd2:    hex = 7'b0100100;
                4'd3:    hex = 7'b0110000;
                4'd4:    hex = 7'b0011001;
                4'd5:    hex = 7'b0010010;
                4'd6:    hex = 7'b0000010;
                4'd7:    hex = 7'b1111000;
                4'd8:    hex = 7'b0000000;
                4'd9:    hex = 7'b0010000;
                default: hex = 7'b1111111;   // valores de 10 a 15: display apagado
            endcase
        end
    end

endmodule
