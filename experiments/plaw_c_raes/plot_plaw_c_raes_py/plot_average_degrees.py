import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns



results_folder = "results/plaw_c_raes"
file_path = os.path.join(results_folder, "average_degrees.csv")
output_plot = os.path.join(results_folder, "plot_average_degrees_python.png")

if not os.path.exists(file_path):
    file_path = "average_degrees.csv"
    output_plot = "plot_average_degrees_python.png"


df = pd.read_csv(file_path)


sns.set_theme(style="whitegrid")
plt.figure(figsize=(8, 5))

plt.errorbar(
    df["p_value"], 
    df["average_degree"], 
    yerr=df["std_degree"],
    label="Average Degree",
    fmt='--s',         
    linewidth=2.5,
    markersize=7,
    color="forestgreen",
    capsize=4
)


plt.title("Average Network Degree vs probability p (k=2.0)", fontsize=14)
plt.xlabel("Mixture parameter p", fontsize=12)
plt.ylabel("Average Degree", fontsize=12)

plt.legend(loc="upper left")
plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True) if os.path.dirname(output_plot) else None
plt.savefig(output_plot, dpi=300)
print(f"Grafico salvato: {output_plot}")