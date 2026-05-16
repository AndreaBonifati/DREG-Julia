import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

results_folder = "results/plaw_raes"
file_traj_p = os.path.join(results_folder, "spectral_gap_trajectory_by_p.csv")
file_baseline = os.path.join(results_folder, "spectral_gap_baseline_p1.csv")
file_p0 = os.path.join(results_folder, "spectral_gap_trajectory_k2_only.csv")
output_plot = os.path.join(results_folder, "plot_trajectories_by_p_python_2.png")

if not os.path.exists(file_traj_p):
    raise FileNotFoundError(f"File traiettorie non trovato: {file_traj_p}")

df_p = pd.read_csv(file_traj_p)
df_p0 = pd.read_csv(file_p0)


target_ps = [0.1, 0.3, 0.5, 0.7, 0.9]
df_p_filtered = df_p[df_p.iloc[:, 0].isin(target_ps)].copy()

has_baseline = False
df_base = pd.DataFrame()

if os.path.exists(file_baseline):
    df_base = pd.read_csv(file_baseline)
    has_baseline = True
else:
    print(f"ATTENZIONE: File baseline non trovato ({file_baseline}).")

sns.set_theme(style="whitegrid") 
plt.figure(figsize=(10, 6.6))    


p0_rounds = df_p0.iloc[:, 0]
p0_gaps = df_p0.iloc[:, 1]
plt.plot(p0_rounds, p0_gaps, label="p = 0.0", linewidth=2, alpha=0.8, color="C0")


palette = sns.color_palette("tab10", len(target_ps) + 1)[1:]

for i, (index, row) in enumerate(df_p_filtered.iterrows()):
    p_val = row.iloc[0]
    gaps = row.iloc[1:].values.astype(float) 
    rounds_x = range(1, len(gaps) + 1)       
    
    plt.plot(rounds_x, gaps,
             label=f"p = {p_val}",
             linewidth=2,
             alpha=0.8,
             color=palette[i]) 


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


plt.ylim(0.15, 0.65) 

plt.legend(loc="lower right", fontsize=10)
plt.tight_layout()

os.makedirs(os.path.dirname(output_plot), exist_ok=True)
plt.savefig(output_plot, dpi=300)
print(f"Grafico salvato con successo in: {output_plot}")