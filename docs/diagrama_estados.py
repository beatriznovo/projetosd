import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, FancyArrowPatch

AZUL = "#1f3a5f"
VERDE = "#2d6a4f"
VERM = "#b23a48"
CINZA = "#555555"

fig, ax = plt.subplots(figsize=(13, 7.5))
ax.set_xlim(0, 13)
ax.set_ylim(-1.1, 6.4)
ax.axis("off")

pos = {"DIGITO0": (2, 3.4), "DIGITO1": (4.8, 3.4), "DIGITO2": (7.6, 3.4), "DIGITO3": (10.4, 3.4),
       "ABERTO": (12.1, 5.5), "ERRO": (12.1, 1.3)}
cores = {"DIGITO0": AZUL, "DIGITO1": AZUL, "DIGITO2": AZUL, "DIGITO3": AZUL, "ABERTO": VERDE, "ERRO": VERM}
raio = {"DIGITO0": 0.78, "DIGITO1": 0.78, "DIGITO2": 0.78, "DIGITO3": 0.78, "ABERTO": 0.78, "ERRO": 0.78}

for nome, (x, y) in pos.items():
    ax.add_patch(Circle((x, y), raio[nome], facecolor="white", edgecolor=cores[nome], linewidth=2.2, zorder=3))
    ax.text(x, y + (0.14 if nome.startswith("DIGITO") else 0), nome, ha="center", va="center", fontsize=10.5, color=cores[nome], fontweight="bold", zorder=4)

for i, nome in enumerate(["DIGITO0", "DIGITO1", "DIGITO2", "DIGITO3"]):
    x, y = pos[nome]
    ax.text(x, y - 0.26, f"HEX4 = {i + 1}", ha="center", va="center", fontsize=8.5, color=CINZA, zorder=4)
ax.text(12.1, 4.45, "LEDs verdes\n5 s", ha="center", va="top", fontsize=9, color=VERDE)
ax.text(12.1, 0.2, "LEDs vermelhos 3 s", ha="center", va="bottom", fontsize=9, color=VERM)

def seta(p, q, rad=0.0, cor=CINZA, estilo="-|>"):
    a = FancyArrowPatch(p, q, connectionstyle=f"arc3,rad={rad}", arrowstyle=estilo, mutation_scale=18,
                        linewidth=1.8, color=cor, zorder=2, shrinkA=0, shrinkB=0)
    ax.add_patch(a)

seta((0.4, 3.4), (1.22, 3.4), cor=AZUL)
ax.text(0.4, 3.75, "início", ha="left", fontsize=9, color=CINZA)

for a, b in [("DIGITO0", "DIGITO1"), ("DIGITO1", "DIGITO2"), ("DIGITO2", "DIGITO3")]:
    xa, ya = pos[a]; xb, yb = pos[b]
    seta((xa + raio[a], ya), (xb - raio[b], yb), cor=AZUL)
    ax.text((xa + xb) / 2, ya + 0.22, "KEY[1]", ha="center", fontsize=10, color=AZUL)

xd, yd = pos["DIGITO3"]
seta((xd + 0.55, yd + 0.55), (pos["ABERTO"][0] - 0.3, pos["ABERTO"][1] - 0.72), rad=-0.15, cor=VERDE)
ax.text(10.7, 4.75, "KEY[1] e\nsenha correta", ha="center", fontsize=9.5, color=VERDE)
seta((xd + 0.55, yd - 0.55), (pos["ERRO"][0] - 0.3, pos["ERRO"][1] + 0.72), rad=0.15, cor=VERM)
ax.text(10.7, 2.0, "KEY[1] e\nsenha incorreta", ha="center", fontsize=9.5, color=VERM)

seta((pos["ABERTO"][0] - 0.78, pos["ABERTO"][1] + 0.1), (pos["DIGITO0"][0] + 0.2, pos["DIGITO0"][1] + 0.76), rad=0.18, cor=VERDE)
ax.text(6.4, 5.95, "fim dos 5 s", ha="center", fontsize=10, color=VERDE)
seta((pos["ERRO"][0] - 0.78, pos["ERRO"][1] - 0.1), (pos["DIGITO0"][0] + 0.2, pos["DIGITO0"][1] - 0.76), rad=-0.18, cor=VERM)
ax.text(6.4, 0.75, "fim dos 3 s", ha="center", fontsize=10, color=VERM)

ax.text(6.5, -0.15, "Em DIGITO0 a DIGITO3:  KEY[2] incrementa e KEY[3] decrementa o dígito ativo, sem mudar de estado.",
        ha="center", fontsize=10, color=AZUL)
ax.text(6.5, -0.7, "KEY[0] (reset), em qualquer estado: volta a DIGITO0, zera os dígitos e apaga os LEDs. Nos estados de dígito, os LEDs ficam apagados.",
        ha="center", fontsize=10, color=CINZA)

fig.suptitle("SafeCrack Pro: diagrama de estados", x=0.02, ha="left", fontsize=14)
fig.savefig("../docs/diagrama_estados.png", dpi=130, bbox_inches="tight")
