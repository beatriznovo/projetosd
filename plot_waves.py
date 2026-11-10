import re
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

def achar_ids():
    escopo = []
    ids = {}
    alvo = {("tb_safecrack", "KEY"): "KEY", ("tb_safecrack", "LEDR"): "LEDR", ("tb_safecrack", "LEDG"): "LEDG",
            ("u_fsm", "dig0"): "dig0", ("u_fsm", "dig1"): "dig1", ("u_fsm", "dig2"): "dig2", ("u_fsm", "dig3"): "dig3",
            ("u_fsm", "state"): "state"}
    for linha in open("safecrack.vcd"):
        p = linha.split()
        if not p:
            continue
        if p[0] == "$scope":
            escopo.append(p[2])
        elif p[0] == "$upscope":
            escopo.pop()
        elif p[0] == "$var":
            chave = (escopo[-1], p[4])
            if chave in alvo and alvo[chave] not in ids:
                ids[alvo[chave]] = p[3]
        elif p[0] == "$enddefinitions":
            break
    return ids

IDS = achar_ids()
NAMES = {0: "D0", 1: "D1", 2: "D2", 3: "D3", 4: "ABERTO", 5: "ERRO"}
PERIODO = 10000

data = {k: [] for k in IDS}
rev = {v: k for k, v in IDS.items()}
tempo = 0
passou_header = False
for linha in open("safecrack.vcd"):
    linha = linha.strip()
    if linha.startswith("$enddefinitions"):
        passou_header = True
        continue
    if not passou_header:
        continue
    if linha.startswith("#"):
        tempo = int(linha[1:])
    elif linha.startswith("b"):
        valor, ident = linha[1:].split()
        if ident in rev:
            v = int(valor.replace("x", "0").replace("z", "0"), 2)
            data[rev[ident]].append((tempo, v))

def vetor(nome):
    return data[nome]

def valor_em(nome, t):
    v = 0
    for tt, vv in data[nome]:
        if tt <= t:
            v = vv
        else:
            break
    return v

def bit(nome, i):
    saida = []
    for t, v in data[nome]:
        saida.append((t, (v >> i) & 1))
    return saida

def primeiro(nome, valor, apos=0):
    for t, v in data[nome]:
        if t >= apos and v == valor:
            return t
    return None

def janela(t0, t1, arquivo, titulo, mostrar_hold=False):
    t0 = max(0, t0)
    fig, eixos = plt.subplots(8, 1, figsize=(13, 8.2), sharex=True,
                              gridspec_kw={"height_ratios": [1, 1, 1, 1, 1.5, 1.3, 1, 1]})
    cor_digital = "#1f3a5f"
    cor_bus = "#8a5a2b"

    def digital(ax, serie, rotulo, cor=cor_digital, invertido=False):
        xs, ys = [], []
        atual = serie[0][1] if serie else 0
        for t, v in serie:
            if t < t0:
                atual = v
        xs.append(t0)
        ys.append(atual)
        for t, v in serie:
            if t0 <= t <= t1:
                xs.append(t); ys.append(ys[-1])
                xs.append(t); ys.append(v)
        xs.append(t1); ys.append(ys[-1])
        ax.step([x / PERIODO for x in xs], ys, where="post", color=cor, linewidth=1.6)
        ax.set_ylim(-0.25, 1.35)
        ax.set_yticks([0, 1])
        ax.set_ylabel(rotulo, rotation=0, ha="right", va="center", fontsize=10)

    def barramento(ax, nome, rotulo, formato, cor=cor_bus):
        mudancas = [t for t, v in data[nome] if t0 < t < t1]
        pontos = [t0] + mudancas + [t1]
        for a, b in zip(pontos[:-1], pontos[1:]):
            v = valor_em(nome, a)
            ax.fill_between([a / PERIODO, b / PERIODO], 0, 1, color=cor, alpha=0.13)
            ax.plot([a / PERIODO, b / PERIODO], [1, 1], color=cor, linewidth=1.4)
            ax.plot([a / PERIODO, b / PERIODO], [0, 0], color=cor, linewidth=1.4)
            ax.plot([a / PERIODO, a / PERIODO], [0, 1], color=cor, linewidth=1.4)
            if (b - a) / PERIODO > (t1 - t0) / PERIODO * 0.018:
                ax.text((a + b) / 2 / PERIODO, 0.5, formato(v), ha="center", va="center", fontsize=9.5)
        ax.set_ylim(-0.2, 1.2)
        ax.set_yticks([])
        ax.set_ylabel(rotulo, rotation=0, ha="right", va="center", fontsize=10)

    digital(eixos[0], bit("KEY", 0), "KEY[0] reset\n(ativo em 0)")
    digital(eixos[1], bit("KEY", 1), "KEY[1] confirma\n(ativo em 0)")
    digital(eixos[2], bit("KEY", 2), "KEY[2] incrementa\n(ativo em 0)")
    digital(eixos[3], bit("KEY", 3), "KEY[3] decrementa\n(ativo em 0)")
    barramento(eixos[4], "state", "estado da FSM", lambda v: NAMES.get(v, str(v)), cor="#2d6a4f")
    barramento(eixos[5], "dig0", "HEX3 (dígito 1)", lambda v: str(v))
    barramento(eixos[6], "dig3", "HEX0 (dígito 4)", lambda v: str(v))
    ledg = [(t, 1 if v == 0x1FF else 0) for t, v in data["LEDG"]]
    ledr = [(t, 1 if v == 0x3FFFF else 0) for t, v in data["LEDR"]]
    digital(eixos[7], ledg, "LEDs verdes", cor="#2d6a4f")
    eixos[7].twiny
    eixos[7].set_xlabel("tempo (ciclos de clock)")
    for ax in eixos:
        ax.grid(axis="x", color="#dddddd", linewidth=0.6)
        for s in ("top", "right"):
            ax.spines[s].set_visible(False)
    ax_r = eixos[7]
    if ledr:
        pass
    fig.suptitle(titulo, fontsize=13, x=0.02, ha="left")
    eixos[0].set_xlim(t0 / PERIODO, t1 / PERIODO)
    fig.tight_layout(rect=[0, 0, 1, 0.97])
    fig.savefig(arquivo, dpi=130)
    plt.close(fig)

def janela_led(t0, t1, arquivo, titulo, usar="LEDR"):
    t0 = max(0, t0)
    fig, eixos = plt.subplots(7, 1, figsize=(13, 7.4), sharex=True,
                              gridspec_kw={"height_ratios": [1, 1.5, 1, 1, 1, 1, 1]})
    cor_digital = "#1f3a5f"

    def digital(ax, serie, rotulo, cor=cor_digital):
        xs, ys = [t0], [0]
        for t, v in serie:
            if t < t0:
                ys[0] = v
        for t, v in serie:
            if t0 <= t <= t1:
                xs.append(t); ys.append(ys[-1])
                xs.append(t); ys.append(v)
        xs.append(t1); ys.append(ys[-1])
        ax.step([x / PERIODO for x in xs], ys, where="post", color=cor, linewidth=1.6)
        ax.set_ylim(-0.25, 1.35)
        ax.set_yticks([0, 1])
        ax.set_ylabel(rotulo, rotation=0, ha="right", va="center", fontsize=10)

    def barramento(ax, nome, rotulo, formato, cor="#8a5a2b"):
        mudancas = [t for t, v in data[nome] if t0 < t < t1]
        pontos = [t0] + mudancas + [t1]
        for a, b in zip(pontos[:-1], pontos[1:]):
            v = valor_em(nome, a)
            ax.fill_between([a / PERIODO, b / PERIODO], 0, 1, color=cor, alpha=0.13)
            ax.plot([a / PERIODO, b / PERIODO], [1, 1], color=cor, linewidth=1.4)
            ax.plot([a / PERIODO, b / PERIODO], [0, 0], color=cor, linewidth=1.4)
            ax.plot([a / PERIODO, a / PERIODO], [0, 1], color=cor, linewidth=1.4)
            if (b - a) / PERIODO > (t1 - t0) / PERIODO * 0.018:
                ax.text((a + b) / 2 / PERIODO, 0.5, formato(v), ha="center", va="center", fontsize=9.5)
        ax.set_ylim(-0.2, 1.2)
        ax.set_yticks([])
        ax.set_ylabel(rotulo, rotation=0, ha="right", va="center", fontsize=10)

    digital(eixos[0], bit("KEY", 1), "KEY[1] confirma\n(ativo em 0)")
    barramento(eixos[1], "state", "estado da FSM", lambda v: NAMES.get(v, str(v)), cor="#2d6a4f")
    barramento(eixos[2], "dig0", "HEX3 (dígito 1)", lambda v: str(v))
    barramento(eixos[3], "dig1", "HEX2 (dígito 2)", lambda v: str(v))
    barramento(eixos[4], "dig2", "HEX1 (dígito 3)", lambda v: str(v))
    barramento(eixos[5], "dig3", "HEX0 (dígito 4)", lambda v: str(v))
    if usar == "LEDR":
        serie = [(t, 1 if v == 0x3FFFF else 0) for t, v in data["LEDR"]]
        digital(eixos[6], serie, "LEDs vermelhos\n(todos)", cor="#b23a48")
    else:
        serie = [(t, 1 if v == 0x1FF else 0) for t, v in data["LEDG"]]
        digital(eixos[6], serie, "LEDs verdes\n(todos)", cor="#2d6a4f")
    eixos[6].set_xlabel("tempo (ciclos de clock)")
    for ax in eixos:
        ax.grid(axis="x", color="#dddddd", linewidth=0.6)
        for s in ("top", "right"):
            ax.spines[s].set_visible(False)
    fig.suptitle(titulo, fontsize=13, x=0.02, ha="left")
    eixos[0].set_xlim(t0 / PERIODO, t1 / PERIODO)
    fig.tight_layout(rect=[0, 0, 1, 0.97])
    fig.savefig(arquivo, dpi=130)
    plt.close(fig)

mud_dig0 = data["dig0"]
t_a = mud_dig0[1][0] if len(mud_dig0) > 1 else 0
vals = [v for t, v in mud_dig0]
idx_inc = next(i for i, (t, v) in enumerate(mud_dig0) if i >= 1 and v == 1)
t_inc = mud_dig0[idx_inc][0]
inicio_edicao = None
for t, v in bit("KEY", 2):
    if v == 0 and t > 100000:
        inicio_edicao = t
        break
janela(inicio_edicao - 8 * PERIODO, inicio_edicao + 40 * PERIODO, "../docs/waveform_edicao.png",
       "Edição do dígito: incrementar, decrementar e wrap-around (0 → 9 e 9 → 0)")

t_hold = None
cont = 0
for t, v in bit("KEY", 2):
    if v == 0 and t > inicio_edicao + 280 * PERIODO - 1:
        pass
quedas = [t for t, v in bit("KEY", 2) if v == 0]
alvo = None
for a, b in zip(quedas[:-1], quedas[1:]):
    pass
ups = [(t, v) for t, v in bit("KEY", 2)]
longos = []
for i in range(len(ups) - 1):
    if ups[i][1] == 0 and ups[i + 1][0] - ups[i][0] > 40 * PERIODO:
        longos.append(ups[i][0])
t_hold = longos[0]
janela(t_hold - 15 * PERIODO, t_hold + 90 * PERIODO, "../docs/waveform_botao_segurado.png",
       "Botão KEY[2] segurado por 60 ciclos: o dígito é incrementado uma única vez")

t_erro = primeiro("state", 5)
janela_led(t_erro - 135 * PERIODO, t_erro + 325 * PERIODO, "../docs/waveform_senha_errada.png",
           "Senha incorreta (1235): LEDs vermelhos por 3 s e retorno ao estado inicial", usar="LEDR")

t_ok = primeiro("state", 4)
janela_led(t_ok - 135 * PERIODO, t_ok + 525 * PERIODO, "../docs/waveform_senha_correta.png",
           "Senha correta (1234): LEDs verdes por 5 s e retorno ao estado inicial", usar="LEDG")
t_juntos = next(t for t, v in data["KEY"] if (v & 0b1100) == 0 and t > t_ok)
janela(t_juntos - 8 * PERIODO, t_juntos + 17 * PERIODO, "../docs/waveform_botoes_simultaneos.png",
       "Botões apertados ao mesmo tempo: KEY[2]+KEY[3] são ignorados e KEY[1]+KEY[2] só confirmam")
print("ok")
