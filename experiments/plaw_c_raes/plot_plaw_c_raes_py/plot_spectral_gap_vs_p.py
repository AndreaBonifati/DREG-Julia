import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_c_raes"
file_path = os.path.join(results_folder, "spectral_gap_vs_p.csv")
output_plot = os.path.join(results_folder, "plot_spectral_gap_vs_p_python.png")

if not os.path.exists(file_path):
    file_path = "spectral_gap_vs_p.csv" 
    output_plot = "plot_spectral_gap_vs_p_c.png"


df = pd.read_csv(file_path)


sns.set_theme(style="whitegrid")
plt.figure(figsize=(8, 5))

plt.errorbar(
    df["p_value"], 
    df["mean_gap"], 
    yerr=df["std_gap"],
    label="Mean Spectral Gap",
    fmt='-o',          
    linewidth=2.5,
    markersize=7,
    color="navy",      
    capsize=4         
)


plt.title("Spectral Gap vs p (k=2.0)", fontsize=14)
plt.xlabel("Mixture parameter p", fontsize=12)
plt.ylabel("Average Spectral Gap", fontsize=12)

plt.legend(loc="lower right")
plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True) if os.path.dirname(output_plot) else None
plt.savefig(output_plot, dpi=300)
print(f"Grafico salvato: {output_plot}")