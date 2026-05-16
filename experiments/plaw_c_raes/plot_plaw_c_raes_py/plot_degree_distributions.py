import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_c_raes"
file_path = os.path.join(results_folder, "degree_distributions.csv")
output_plot = os.path.join(results_folder, "plot_degree_distributions_python.png")

if not os.path.exists(file_path):
    file_path = "degree_distributions.csv"
    output_plot = "plot_degree_distributions_python.png"


df = pd.read_csv(file_path)


sns.set_theme(style="whitegrid")
plt.figure(figsize=(10, 6))

degrees = df["degree"]


p_cols = [col for col in df.columns if col.startswith("p_")]


palette = sns.color_palette("viridis", len(p_cols))

for i, col in enumerate(p_cols):
    
    p_label = col.replace("p_", "p = ")
    
    
    mask = df[col] > 0
    plt.plot(degrees[mask], df[col][mask], 
             marker='.', 
             markersize=6,
             linewidth=1.5,
             alpha=0.8,
             color=palette[i],
             label=p_label)


plt.title("Degree Distributions across different values of p", fontsize=14)
plt.xlabel("Degree", fontsize=12)
plt.ylabel("Probability p", fontsize=12)


plt.yscale("log")
# plt.xscale("log") # Decommentare per grafico Log-Log 


plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=10)
plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True) if os.path.dirname(output_plot) else None
plt.savefig(output_plot, dpi=300, bbox_inches='tight') 
print(f"Grafico salvato: {output_plot}")