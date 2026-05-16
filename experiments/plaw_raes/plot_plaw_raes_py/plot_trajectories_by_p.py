import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_raes"
file_traj_p = os.path.join(results_folder, "spectral_gap_trajectory_by_p.csv")
file_baseline = os.path.join(results_folder, "spectral_gap_baseline_p1.csv")
output_plot = os.path.join(results_folder, "plot_trajectories_by_p_python.png")

if not os.path.exists(file_traj_p):
    raise FileNotFoundError(f"File traiettorie non trovato: {file_traj_p}")


df_p = pd.read_csv(file_traj_p)


has_baseline = False
df_base = pd.DataFrame()

if os.path.exists(file_baseline):
    df_base = pd.read_csv(file_baseline)
    has_baseline = True
else:
    print(f"ATTENZIONE: File baseline non trovato ({file_baseline}). Niente linea nera.")


sns.set_theme(style="whitegrid") 
plt.figure(figsize=(10, 6.6))    


unique_p = len(df_p)
palette = sns.color_palette("tab10", unique_p)


for i, (index, row) in enumerate(df_p.iterrows()):
    p_val = row.iloc[0]
    gaps = row.iloc[1:].values.astype(float) 
    rounds_x = range(1, len(gaps) + 1)       
    
    plt.plot(rounds_x, gaps,
             label=f"p = {p_val}",
             linewidth=2,
             alpha=0.8,
             color=palette[i % len(palette)]) 


if has_baseline:
    base_rounds = df_base.iloc[:, 0]
    base_gaps = df_base.iloc[:, 1]
    
    plt.plot(base_rounds, base_gaps,
             label="Baseline (p=1.0)",
             linestyle="--",
             color="black",
             linewidth=2.5)


plt.title("Spectral Gap Evolution by p (k=2.0)", fontsize=14)
plt.xlabel("Round", fontsize=12)
plt.ylabel("Average Spectral Gap", fontsize=12)

plt.ylim(0.2, 0.65)

plt.legend(loc="lower right", fontsize=10)
plt.tight_layout()


os.makedirs(os.path.dirname(output_plot), exist_ok=True)
plt.savefig(output_plot, dpi=300)
print(f"Grafico salvato con successo in: {output_plot}")
