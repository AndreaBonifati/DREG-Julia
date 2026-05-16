import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_raes"
file_path = os.path.join(results_folder, "optimized_dynamic_stats.csv")
output_plot = os.path.join(results_folder, "diameter_vs_apl_python.png")

if not os.path.exists(file_path):
    raise FileNotFoundError(f"File dati non trovato: {file_path}")


df = pd.read_csv(file_path)


sns.set_theme(style="whitegrid")
plt.figure(figsize=(8, 5))


plt.errorbar(
    df["p_value"], 
    df["mean_diameter"], 
    yerr=df["std_diameter"],
    label="Mean Diameter",
    fmt='-o',          
    linewidth=2,
    markersize=6,
    color="navy",      
    capsize=4         
)


plt.errorbar(
    df["p_value"], 
    df["mean_apl"], 
    yerr=df["std_apl"],
    label="Average Path Length (APL)",
    fmt='--s',         
    linewidth=2,
    markersize=6,
    color="dodgerblue", 
    capsize=4
)


plt.title("Network Efficiency: Compactness", fontsize=14)
plt.xlabel("Mixture Parameter $p$ (Prob. of Standard Degree)", fontsize=12)
plt.ylabel("Distance (hops)", fontsize=12)

plt.legend(loc="upper left") 
plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True)

plt.savefig(output_plot, dpi=300)
print(f"Grafico salvato: {output_plot}")

