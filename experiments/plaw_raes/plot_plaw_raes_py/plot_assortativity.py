import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_raes"
input_file = os.path.join(results_folder, "assortativity_stats_k2.csv")
output_file = os.path.join(results_folder, "assortativity_plot_python.png")

if not os.path.exists(input_file):

    raise FileNotFoundError(f"File dati non trovato: {input_file}")


df = pd.read_csv(input_file)


p_values = df.iloc[:, 0]
r_means = df.iloc[:, 1]
r_stds = df.iloc[:, 2]


sns.set_theme(style="whitegrid")
plt.figure(figsize=(8, 6)) 


plt.errorbar(
    p_values,
    r_means,
    yerr=r_stds,
    label="Mean Assortativity (r)",
    fmt='-o',         
    color="blue",      
    linewidth=2,
    markersize=5,
    alpha=0.8,
    capsize=4         
)


plt.axhline(
    y=0,
    color="red",
    linestyle="--",     
    linewidth=2,
    label="Neutrality (Random Mixing)"
)


plt.title("Network Assortativity vs Default target degree probability p", fontsize=14)
plt.xlabel("Mixture Parameter p (Prob. of Standard Degree)", fontsize=12)
plt.ylabel("Pearson Correlation Coeff. (r)", fontsize=12)


plt.ylim(-0.35, 0.05)


plt.legend(loc="lower right", fontsize=10)

plt.grid(True, linestyle='--', alpha=0.7)
plt.tight_layout()


os.makedirs(os.path.dirname(output_file), exist_ok=True)
plt.savefig(output_file, dpi=300)
print(f"Grafico salvato con successo in: {output_file}")

