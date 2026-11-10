`timescale 1ns/1ps

// testbench do SafeCrack Pro
// usa CLK_HZ = 100 para que 5 s sejam 500 ciclos e 3 s sejam 300 ciclos
module tb_safecrack;

    localparam int CLK_HZ  = 100;
    localparam int T_ABERTO = 5 * CLK_HZ;
    localparam int T_ERRO   = 3 * CLK_HZ;

    logic        CLOCK_50 = 0;
    logic [3:0]  KEY = 4'b1111;
    logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4;
    logic [8:0]  LEDG;
    logic [17:0] LEDR;

    int erros = 0;
    int testes = 0;

    safecrack_top #(.CLK_HZ(CLK_HZ)) dut (.*);

    // clock de 10 ns (a escala de tempo real nao importa, so a quantidade de ciclos)
    always #5 CLOCK_50 = ~CLOCK_50;

    // mesma tabela do modulo seg7, usada para conferir os displays
    function automatic logic [6:0] seg(input int n);
        case (n)
            0: seg = 7'b1000000;
            1: seg = 7'b1111001;
            2: seg = 7'b0100100;
            3: seg = 7'b0110000;
            4: seg = 7'b0011001;
            5: seg = 7'b0010010;
            6: seg = 7'b0000010;
            7: seg = 7'b1111000;
            8: seg = 7'b0000000;
            9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    endfunction

    // compara e imprime OK ou FAIL, contando os erros
    task automatic check(input bit cond, input string msg);
        testes++;
        if (cond) $display("[ OK ] %s", msg);
        else begin
            erros++;
            $display("[FAIL] %s  (t=%0t)", msg, $time);
        end
    endtask

    task automatic ciclos(input int n);
        repeat (n) @(posedge CLOCK_50);
    endtask

    // aperta um botao por 4 ciclos e solta
    task automatic aperta(input int k);
        KEY[k] = 1'b0;
        ciclos(4);
        KEY[k] = 1'b1;
        ciclos(4);
    endtask

    task automatic aperta_dois(input int a, input int b);
        KEY[a] = 1'b0;
        KEY[b] = 1'b0;
        ciclos(4);
        KEY[a] = 1'b1;
        KEY[b] = 1'b1;
        ciclos(4);
    endtask

    // segura um botao por n ciclos (deve contar uma acao so)
    task automatic segura(input int k, input int n);
        KEY[k] = 1'b0;
        ciclos(n);
        KEY[k] = 1'b1;
        ciclos(4);
    endtask

    // confere os quatro displays de digitos
    task automatic mostra(input int a, input int b, input int c, input int d, input string msg);
        check(HEX3 == seg(a) && HEX2 == seg(b) && HEX1 == seg(c) && HEX0 == seg(d), msg);
    endtask

    task automatic sobe(input int n);
        repeat (n) aperta(2);
    endtask

    // digita uma senha de 4 digitos, confirmando cada um
    task automatic digita(input int a, input int b, input int c, input int d);
        sobe(a); aperta(1);
        sobe(b); aperta(1);
        sobe(c); aperta(1);
        sobe(d); aperta(1);
    endtask

    // monitores que medem quantos ciclos seguidos os LEDs ficaram acesos
    int cnt_r = 0, last_r = 0;
    int cnt_g = 0, last_g = 0;

    always @(posedge CLOCK_50) begin
        if (LEDR === 18'h3FFFF) cnt_r++;
        else begin
            if (cnt_r > 0) last_r = cnt_r;
            cnt_r = 0;
        end
        if (LEDG === 9'h1FF) cnt_g++;
        else begin
            if (cnt_g > 0) last_g = cnt_g;
            cnt_g = 0;
        end
    end

    // espera todos os LEDs apagarem
    task automatic espera_fim;
        while (LEDG !== 9'h000 || LEDR !== 18'h00000) @(posedge CLOCK_50);
    endtask


    initial begin
        $dumpfile("safecrack.vcd");
        $dumpvars(0, tb_safecrack);

        ciclos(5);
        aperta(0);
        ciclos(5);

        $display("\n--- T1: estado inicial ---");
        mostra(0, 0, 0, 0, "displays iniciam em 0000");
        check(HEX4 == seg(1), "HEX4 indica o primeiro digito");
        check(LEDG == 0 && LEDR == 0, "LEDs apagados");

        $display("\n--- T2: incrementa, decrementa e wrap-around ---");
        aperta(2);
        mostra(1, 0, 0, 0, "KEY[2] incrementa 0 -> 1");
        aperta(3);
        mostra(0, 0, 0, 0, "KEY[3] decrementa 1 -> 0");
        aperta(3);
        mostra(9, 0, 0, 0, "wrap-around 0 -> 9");
        aperta(2);
        mostra(0, 0, 0, 0, "wrap-around 9 -> 0");

        $display("\n--- T3: botao segurado conta uma vez so ---");
        segura(2, 60);
        mostra(1, 0, 0, 0, "KEY[2] segurado por 60 ciclos incrementa apenas 1");
        segura(3, 60);
        mostra(0, 0, 0, 0, "KEY[3] segurado por 60 ciclos decrementa apenas 1");

        $display("\n--- T4: confirmacao avanca o digito ativo ---");
        sobe(1);
        aperta(1);
        check(HEX4 == seg(2), "HEX4 indica o segundo digito");
        sobe(2);
        mostra(1, 2, 0, 0, "digito 1 fixado, digito 2 editado");
        aperta(1);
        check(HEX4 == seg(3), "HEX4 indica o terceiro digito");
        aperta(1);
        check(HEX4 == seg(4), "HEX4 indica o quarto digito");

        $display("\n--- T5: reset no meio da digitacao ---");
        aperta(0);
        ciclos(2);
        mostra(0, 0, 0, 0, "reset zera os displays");
        check(HEX4 == seg(1), "reset volta ao primeiro digito");

        $display("\n--- T6: senha incorreta (1235) ---");
        digita(1, 2, 3, 5);
        ciclos(2);
        check(LEDR == 18'h3FFFF && LEDG == 0, "LEDs vermelhos acesos, verdes apagados");
        mostra(1, 2, 3, 5, "displays mantem a tentativa durante o erro");
        check(HEX4 == 7'b1111111, "HEX4 apagado durante o feedback");
        aperta(2);
        mostra(1, 2, 3, 5, "botoes ignorados durante o erro");
        espera_fim();
        ciclos(3);
        check(last_r == T_ERRO, $sformatf("LED vermelho ficou aceso por 3s (%0d de %0d ciclos)", last_r, T_ERRO));
        check(LEDR == 0 && LEDG == 0, "LEDs apagados ao terminar");
        mostra(0, 0, 0, 0, "displays voltam a 0000");
        check(HEX4 == seg(1), "primeiro digito volta a ser o ativo");

        $display("\n--- T7: senha correta (1234) ---");
        digita(1, 2, 3, 4);
        ciclos(2);
        check(LEDG == 9'h1FF && LEDR == 0, "todos os LEDs verdes acesos");
        espera_fim();
        ciclos(3);
        check(last_g == T_ABERTO, $sformatf("LEDs verdes ficaram acesos por 5s (%0d de %0d ciclos)", last_g, T_ABERTO));
        check(LEDG == 0 && LEDR == 0, "LEDs apagados ao terminar");
        mostra(0, 0, 0, 0, "displays voltam a 0000");
        check(HEX4 == seg(1), "primeiro digito volta a ser o ativo");

        $display("\n--- T8: reset durante o feedback ---");
        digita(1, 2, 3, 4);
        ciclos(20);
        check(LEDG == 9'h1FF, "cofre aberto");
        aperta(0);
        ciclos(2);
        check(LEDG == 0 && LEDR == 0, "reset apaga os LEDs");
        mostra(0, 0, 0, 0, "reset zera os displays");

        $display("\n--- T9: nova tentativa apos erro funciona ---");
        digita(9, 9, 9, 9);
        espera_fim();
        ciclos(3);
        digita(1, 2, 3, 4);
        ciclos(2);
        check(LEDG == 9'h1FF, "senha correta abre o cofre apos uma tentativa errada");

        ciclos(T_ABERTO + 10);

        $display("\n--- T10: botoes apertados ao mesmo tempo ---");
        aperta(0);
        ciclos(2);
        aperta_dois(2, 3);
        mostra(0, 0, 0, 0, "KEY[2] e KEY[3] juntos: nenhum dos dois vale");
        check(HEX4 == seg(1), "continua no primeiro digito");
        aperta_dois(1, 2);
        mostra(0, 0, 0, 0, "KEY[1] e KEY[2] juntos: o digito nao muda");
        check(HEX4 == seg(2), "so a confirmacao vale e avanca para o segundo digito");

        $display("\n--- T11: reset durante o erro ---");
        aperta(0);
        ciclos(2);
        digita(1, 1, 1, 1);
        ciclos(20);
        check(LEDR == 18'h3FFFF, "erro ativo");
        aperta(0);
        ciclos(2);
        check(LEDR == 0 && LEDG == 0, "reset apaga os LEDs vermelhos");
        mostra(0, 0, 0, 0, "reset zera os displays");
        check(HEX4 == seg(1), "reset volta ao primeiro digito");

        $display("\n--- T12: botoes ignorados durante o feedback ---");
        digita(1, 2, 3, 4);
        ciclos(20);
        aperta(1);
        aperta(2);
        aperta(3);
        check(LEDG == 9'h1FF, "cofre continua aberto apos apertar KEY[1], KEY[2] e KEY[3]");
        espera_fim();
        ciclos(3);
        check(last_g == T_ABERTO, $sformatf("a contagem de 5s nao foi alterada pelos botoes (%0d de %0d ciclos)", last_g, T_ABERTO));
        mostra(0, 0, 0, 0, "displays voltam a 0000");

        $display("\n=========================================");
        if (erros == 0) $display("RESULTADO: PASSOU (%0d verificacoes)", testes);
        else            $display("RESULTADO: FALHOU (%0d erros em %0d verificacoes)", erros, testes);
        $display("=========================================");
        $finish;
    end

    initial begin
        #5_000_000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
