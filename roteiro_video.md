# Roteiro sugerido para o vídeo (máximo 5 minutos)

Cada integrante explica uma parte. A divisão abaixo é uma sugestão de cerca de 1 minuto por pessoa; troquem como preferirem.

| Tempo | Quem | O que mostrar e explicar |
|---|---|---|
| 0:00 a 1:00 | Luiza Severo | Apresenta o projeto e mostra o cofre funcionando na placa: editar um dígito, confirmar, errar a senha (LED vermelho por 3 s) e acertar a senha (LEDs verdes por 5 s). |
| 1:00 a 2:00 | Beatriz Novo | `btn_sync.sv`: por que o botão passa por dois flip-flops e como o pulso de um ciclo faz um aperto valer uma ação só. |
| 2:00 a 3:00 | Clara Galamba | `safecrack_fsm.sv`: os estados `DIGITO0` a `DIGITO3`, `ABERTO` e `ERRO`, e o diagrama de estados. |
| 3:00 a 4:00 | Beatriz Holanda | Edição dos dígitos (incremento, decremento e wrap-around), a comparação com a senha e o contador de 5 s e 3 s. |
| 4:00 a 5:00 | Maria Lucia Fragoso | `seg7.sv` e `safecrack_top.sv` (displays e LEDs), a simulação e as waveforms, e os known issues. |

## Antes de gravar

- Compile e grave o projeto na placa pelo Quartus e confira a checklist "Teste na placa" do README.
- Deixe o código aberto no editor e as imagens das waveforms (`docs/`) à mão para mostrar.
- Cada pessoa fala olhando para o trecho de código que explica.
- Ensaiem uma vez com o cronômetro: o limite é de 5 minutos.
