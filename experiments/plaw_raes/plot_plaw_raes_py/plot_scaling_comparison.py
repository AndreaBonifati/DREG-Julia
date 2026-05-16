import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np




input_dir = "results/plaw_raes_scaling"
file_std = "scaling_metrics_k2.0_metrics.csv"
file_half = "scaling_metrics_k2.0_metrics_half_nodes.csv"


if not os.path.exists(os.path.join(input_dir, file_std)):
    input_dir = "." 

path_std = os.path.join(input_dir, file_std)
path_half = os.path.join(input_dir, file_half)

output_dir = os.path.join(input_dir, "plots_scaling")
os.makedirs(output_dir, exist_ok=True)


if not os.path.exists(path_std) or not os.path.exists(path_half):
    print(f"Errore: Assicurati che {file_std} e {file_half} siano nella cartella corretta.")

    raise FileNotFoundError("File CSV non trovati.")

df_std = pd.read_csv(path_std)
df_half = pd.read_csv(path_half)


df_std = df_std.sort_values(by="N")
df_half = df_half.sort_values(by="N")

print(f"Caricati dati per N = {df_std['N'].unique()}")

sns.set_theme(style="whitegrid")

def plot_scaling_metric(col_name, title, ylabel, filename, log_y=False):
    plt.figure(figsize=(8, 5))
    

    plt.plot(df_std["N"], df_std[col_name], 
             marker='o', markersize=8, linewidth=2.5, 
             label="$p=0.0$ (Pure Power-Law)", color="navy") 
    

    plt.plot(df_half["N"], df_half[col_name], 
             marker='s', markersize=8, linewidth=2.5, 
             linestyle="--", label="$p=0.5$ (Hybrid Mixture)", color="darkorange")
    

    plt.xscale("log", base=2) 
    if log_y:
        plt.yscale("log")
        
    plt.xlabel("Network Size ($n$)", fontsize=12) 
    plt.ylabel(ylabel, fontsize=12)
    plt.title(title, fontsize=14)
    

    ticks = df_std["N"].unique()
    plt.xticks(ticks, [int(x) for x in ticks])
    plt.minorticks_off()
    
    plt.legend()
    plt.grid(True, which="both", linestyle='--', alpha=0.5)
    plt.tight_layout()
    

    out_path = os.path.join(output_dir, filename)
    plt.savefig(out_path, dpi=300)
    plt.close()
    print(f" -> Grafico salvato: {out_path}")


plot_scaling_metric(
    col_name="SpectralGap",
    title="Scaling of Spectral Expansion",
    ylabel="Spectral Gap ($1 - \lambda_2$)",
    filename="scaling_spectral_gap.png"
)


plot_scaling_metric(
    col_name="Diameter",
    title="Scaling of Network Diameter",
    ylabel="Estimated Diameter (hops)",
    filename="scaling_diameter.png"
)


plot_scaling_metric(
    col_name="HubDominance",
    title="Scaling of Hub Dominance",
    ylabel="Edge Volume to Top 1% Nodes (%)",
    filename="scaling_hub_dominance.png"
)


plot_scaling_metric(
    col_name="Assortativity",
    title="Scaling of Assortativity",
    ylabel="Assortativity Coefficient ($r$)",
    filename="scaling_assortativity.png"
)

print("\nFinito! Controlla la cartella 'plots_scaling'.")