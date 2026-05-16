import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np


results_folder = "results/plaw_raes"
csv_path = os.path.join(results_folder, "flooding", "flooding_vs_p_k2_dynamic.csv")
output_plot = os.path.join(results_folder, "plot_flooding_vs_p_final_python.png")

if not os.path.exists(csv_path):
    raise FileNotFoundError(f"File dati non trovato: {csv_path}")


df = pd.read_csv(csv_path)


p_vals = df.iloc[:, 0]
flooding_times = df.iloc[:, 2]


sns.set_theme(style="whitegrid")

plt.figure(figsize=(8, 5)) 

plt.plot(p_vals, flooding_times,
         label="Flooding Time",
         marker='o',
         markersize=6,
         linewidth=2.5,
         color="blue") 


plt.xlabel("Mixture parameter p", fontsize=12)
plt.ylabel("Average Flooding Time (Round)", fontsize=12)
plt.title("Flooding Time vs p (k=2.0)", fontsize=14)


plt.xticks(np.arange(0.0, 1.1, 0.2))


min_y = flooding_times.min()
max_y = flooding_times.max()
plt.ylim(min_y - 0.3, max_y + 1)


plt.grid(True, linestyle='--', alpha=0.7)
plt.legend(loc="upper left") 

plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True)

plt.savefig(output_plot, dpi=300)
print(f"Grafico pulito salvato in: {output_plot}")

