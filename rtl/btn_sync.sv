// btn_sync: sincroniza um botao com o clock e detecta o instante em que ele e apertado
module btn_sync (
    input  logic clk,
    input  logic btn_n,   // botao da placa (ativo em nivel baixo: 0 = apertado)
    output logic level,   // 1 enquanto o botao esta apertado (ja sincronizado)
    output logic pulse    // 1 por um unico ciclo quando o botao acaba de ser apertado
);

    // s0 e s1 formam o sincronizador: o botao e assincrono em relacao ao clock,
    // entao passa por dois flip-flops antes de ser usado pelo resto do circuito
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
    // segurar o botao nao repete o pulso
    assign pulse = s1 & ~prev;

endmodule
