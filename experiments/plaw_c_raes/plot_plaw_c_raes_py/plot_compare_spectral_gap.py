import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


file_raes = "results/plaw_raes/spectral_gap_vs_p_standard_params_plaw_raes.csv"
file_c_raes = "results/plaw_c_raes/spectral_gap_vs_p_standard_params_plaw_c_raes.csv"


output_plot = "results/plot_comparison_spectral_gap_raes_vs_craes_clean.png"


if not os.path.exists(file_raes):
    raise FileNotFoundError(f"File non trovato: {file_raes}")
if not os.path.exists(file_c_raes):
    raise FileNotFoundError(f"File non trovato: {file_c_raes}")


df_raes = pd.read_csv(file_raes)
df_c_raes = pd.read_csv(file_c_raes)


sns.set_theme(style="whitegrid")
plt.figure(figsize=(8, 5))


plt.plot(
    df_raes["p_value"], 
    df_raes["mean_gap"], 
    label="PL-RAES",
    marker='o',          
    linestyle='-',       
    linewidth=2.5,
    markersize=7,
    color="navy"
)


plt.plot(
    df_c_raes["p_value"], 
    df_c_raes["mean_gap"], 
    label="C-PL-RAES",
    marker='s',          
    linestyle='-',       
    linewidth=2.5,
    markersize=7,
    color="firebrick"
)


plt.title("Spectral Gap Comparison: PL-RAES vs C-PL-RAES", fontsize=14)
plt.xlabel("Mixture Parameter p", fontsize=12)
plt.ylabel("Average Spectral Gap", fontsize=12)


plt.legend(loc="best", fontsize=11)
plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True) if os.path.dirname(output_plot) else None
plt.savefig(output_plot, dpi=300)
print(f"Grafico salvato con successo in: {output_plot}")

