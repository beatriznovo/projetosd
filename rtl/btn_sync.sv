// btn_sync: sincroniza um botao com o clock e detecta o instante em que ele e apertado
module btn_sync (
    input  logic clk,
    input  logic btn_n,   
    output logic level,   
    output logic pulse    
);

    
    logic s0   = 1'b0;
    logic s1   = 1'b0;
    logic prev = 1'b0;   // valor de s1 no ciclo anterior

    always_ff @(posedge clk) begin
        s0   <= ~btn_n;  // inverte: 1 passa a significar "apertado"
        s1   <= s0;
        prev <= s1;
    end

    assign level = s1;
    // borda de subida: agora apertado e antes nao apertado
    
    assign pulse = s1 & ~prev;

endmodule
