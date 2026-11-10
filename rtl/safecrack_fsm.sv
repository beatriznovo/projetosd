// safecrack_fsm: logica do cofre
// guarda os 4 digitos, controla qual esta ativo, verifica a senha e conta o tempo do feedback
module safecrack_fsm #(
    parameter logic [15:0] SENHA  = 16'h1234,    // senha correta (um digito por grupo de 4 bits)
    parameter int          CLK_HZ = 50_000_000   // frequencia do clock, usada para contar segundos
)(
    input  logic        clk,
    input  logic [3:0]  key,        // KEY[3:0] da placa (ativos em nivel baixo)

    output logic [3:0]  dig0,       // primeiro digito (vai para HEX3)
    output logic [3:0]  dig1,       // segundo digito  (vai para HEX2)
    output logic [3:0]  dig2,       // terceiro digito (vai para HEX1)
    output logic [3:0]  dig3,       // quarto digito   (vai para HEX0)
    output logic [1:0]  idx,        // indice do digito ativo (0 a 3)
    output logic        ativo,      // 1 enquanto o usuario esta editando um digito
    output logic [8:0]  led_green,
    output logic [17:0] led_red
);

    // duracao do feedback em ciclos de clock
    localparam int TIME_5S = 5 * CLK_HZ;
    localparam int TIME_3S = 3 * CLK_HZ;

    // estados da FSM: um para cada digito em edicao e um para cada resultado
    typedef enum logic [2:0] {
        DIGITO0 = 3'b000,
        DIGITO1 = 3'b001,
        DIGITO2 = 3'b010,
        DIGITO3 = 3'b011,
        ABERTO  = 3'b100,   // senha correta: LEDs verdes por 5 s
        ERRO    = 3'b101    // senha incorreta: LEDs vermelhos por 3 s
    } state_t;

    state_t state = DIGITO0;
    state_t next_state;

    logic [15:0] dig = 16'h0000;   // os 4 digitos de 4 bits, primeiro digito nos bits 15:12
    logic [31:0] delay_cnt = 0;    // contador regressivo do feedback
    logic [31:0] next_delay_cnt;

    logic rst_lvl;
    logic dec_pls;
    logic inc_pls;
    logic ok_pls;

    // um btn_sync por botao: o reset usa o nivel (vale enquanto apertado),
    // os outros usam o pulso (uma acao por aperto)
    btn_sync u_rst (.clk(clk), .btn_n(key[0]), .level(rst_lvl), .pulse());
    btn_sync u_ok  (.clk(clk), .btn_n(key[1]), .level(),        .pulse(ok_pls));
    btn_sync u_inc (.clk(clk), .btn_n(key[2]), .level(),        .pulse(inc_pls));
    btn_sync u_dec (.clk(clk), .btn_n(key[3]), .level(),        .pulse(dec_pls));

    logic       senha_certa;
    logic [3:0] dig_ativo;     // valor do digito que esta sendo editado
    logic       edita_inc;
    logic       edita_dec;

    always_comb begin
        senha_certa = (dig == SENHA);
        dig_ativo   = dig[15 - idx*4 -: 4];

        // se confirmar chegar junto com incrementar ou decrementar, so a confirmacao vale
        // se incrementar e decrementar chegarem juntos, os dois sao ignorados
        edita_inc = inc_pls && !dec_pls && !ok_pls;
        edita_dec = dec_pls && !inc_pls && !ok_pls;
    end

    // logica de proximo estado (combinacional)
    always_comb begin
        next_state     = state;
        next_delay_cnt = delay_cnt;

        // o reset tem prioridade sobre qualquer estado
        if (rst_lvl) begin
            next_state     = DIGITO0;
            next_delay_cnt = 0;
        end
        else begin
            unique case (state)
                // confirmar avanca sempre para o digito seguinte, nunca volta
                DIGITO0: if (ok_pls) next_state = DIGITO1;
                DIGITO1: if (ok_pls) next_state = DIGITO2;
                DIGITO2: if (ok_pls) next_state = DIGITO3;

                // confirmar o quarto digito verifica a senha
                DIGITO3: begin
                    if (ok_pls) begin
                        if (senha_certa) begin
                            next_state     = ABERTO;
                            next_delay_cnt = TIME_5S;
                        end
                        else begin
                            next_state     = ERRO;
                            next_delay_cnt = TIME_3S;
                        end
                    end
                end

                // durante o feedback os botoes sao ignorados e o contador desce ate o fim
                ABERTO: begin
                    if (delay_cnt > 1) next_delay_cnt = delay_cnt - 1;
                    else               next_state     = DIGITO0;
                end

                ERRO: begin
                    if (delay_cnt > 1) next_delay_cnt = delay_cnt - 1;
                    else               next_state     = DIGITO0;
                end

                default: next_state = DIGITO0;
            endcase
        end
    end

    // registradores: estado, contador e digitos
    always_ff @(posedge clk) begin
        state     <= next_state;
        delay_cnt <= next_delay_cnt;

        // zera os digitos no reset ou quando o feedback termina
        if (rst_lvl || ((state == ABERTO || state == ERRO) && next_state == DIGITO0)) begin
            dig <= 16'h0000;
        end
        // so edita enquanto o usuario esta digitando
        else if (state != ABERTO && state != ERRO) begin
            if (edita_inc) begin
                // wrap-around: 9 + 1 volta para 0
                if (dig_ativo == 4'd9) dig[15 - idx*4 -: 4] <= 4'd0;
                else                   dig[15 - idx*4 -: 4] <= dig_ativo + 4'd1;
            end
            else if (edita_dec) begin
                // wrap-around: 0 - 1 vai para 9
                if (dig_ativo == 4'd0) dig[15 - idx*4 -: 4] <= 4'd9;
                else                   dig[15 - idx*4 -: 4] <= dig_ativo - 4'd1;
            end
        end
    end

    // saidas
    always_comb begin
        // o indice do digito ativo vem direto do estado
        unique case (state)
            DIGITO0: idx = 2'd0;
            DIGITO1: idx = 2'd1;
            DIGITO2: idx = 2'd2;
            DIGITO3: idx = 2'd3;
            default: idx = 2'd0;
        endcase

        ativo     = (state == DIGITO0 || state == DIGITO1 || state == DIGITO2 || state == DIGITO3);
        led_green = {9{state == ABERTO}};    // todos os LEDs verdes da placa
        led_red   = {18{state == ERRO}};     // todos os LEDs vermelhos da placa
        dig0      = dig[15:12];
        dig1      = dig[11:8];
        dig2      = dig[7:4];
        dig3      = dig[3:0];
    end

endmodule
