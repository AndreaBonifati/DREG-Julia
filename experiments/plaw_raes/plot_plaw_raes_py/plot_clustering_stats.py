import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_raes"
file_path = os.path.join(results_folder, "optimized_dynamic_stats.csv")
output_plot = os.path.join(results_folder, "2_clustering_python.png")

if not os.path.exists(file_path):
    raise FileNotFoundError(f"File dati non trovato: {file_path}")


df = pd.read_csv(file_path)


sns.set_theme(style="whitegrid")
plt.figure(figsize=(8, 5))


plt.errorbar(
    df["p_value"], 
    df["mean_global_clust"], 
    yerr=df["std_global_clust"],
    label="Global Clustering",
    fmt='-D',        
    linewidth=2,
    markersize=6,
    color="forestgreen",
    capsize=4
)


plt.errorbar(
    df["p_value"], 
    df["mean_local_clust"], 
    yerr=df["std_local_clust"],
    label="Average Local Clustering",
    fmt='--^',         
    linewidth=2,
    markersize=6,
    color="limegreen",
    capsize=4
)


plt.title("Community Structure: Clustering Coefficient", fontsize=14)
plt.xlabel("Mixture Parameter p (Prob. of Standard Degree)", fontsize=12)
plt.ylabel("Clustering Coefficient", fontsize=12)


plt.ylim(0, 1.05) 

plt.legend(loc="upper right") 
plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True)
plt.savefig(output_plot, dpi=300)
print(f"Grafico salvato: {output_plot}")

