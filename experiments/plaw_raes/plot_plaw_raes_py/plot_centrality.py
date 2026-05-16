import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_raes"
file_path = os.path.join(results_folder, "optimized_dynamic_stats.csv")
output_plot = os.path.join(results_folder, "centrality_plot_python.png")

if not os.path.exists(file_path):
    raise FileNotFoundError(f"File dati non trovato: {file_path}")


df = pd.read_csv(file_path)


sns.set_theme(style="whitegrid")
plt.figure(figsize=(8, 5))


plt.errorbar(
    df["p_value"], 
    df["mean_max_betweenness"], 
    yerr=df["std_max_betweenness"],
    label="Max Betweenness Centrality",
    fmt='-o',           
    linewidth=2,
    markersize=6,
    color="firebrick", 
    capsize=4           
)


plt.title("Network Centralization: Maximum Betweenness", fontsize=14)
plt.xlabel("Mixture Parameter p (Prob. of Standard Degree)", fontsize=12)
plt.ylabel("Betweenness Score", fontsize=12)

plt.legend(loc="upper right") 
plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True)
plt.savefig(output_plot, dpi=300)
print(f"Grafico salvato: {output_plot}")
