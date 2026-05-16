import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_raes"
file_high_k = os.path.join(results_folder, "spectral_gap_trajectory_by_k.csv")
file_low_k  = os.path.join(results_folder, "spectral_gap_trajectory_k2_only.csv")
file_base   = os.path.join(results_folder, "spectral_gap_baseline_p1.csv")


trajectories = {}
baseline_traj = []


if os.path.exists(file_high_k):
    df_high = pd.read_csv(file_high_k)

    for index, row in df_high.iterrows():
        k_val = float(row.iloc[0])
        trajectories[k_val] = row.iloc[1:].values.astype(float)

if os.path.exists(file_low_k):
    df_low = pd.read_csv(file_low_k)

    trajectories[2.0] = df_low.iloc[:, 1].values.astype(float)


if os.path.exists(file_base):
    df_base = pd.read_csv(file_base)
    baseline_traj = df_base.iloc[:, 1].values.astype(float)
    print("  - Caricata Baseline P=1.0")
else:
    print(f"Warning: File Baseline non trovato: {file_base}")


print("Generazione grafico di confronto...")


sns.set_theme(style="whitegrid")
plt.figure(figsize=(10, 6.6)) 


if len(baseline_traj) > 0:
    plt.plot(range(1, len(baseline_traj) + 1), baseline_traj,
             label="p=1.0",
             color="black",
             linewidth=3,
             linestyle="--",
             alpha=0.8)


sorted_k = sorted(trajectories.keys())

palette = sns.color_palette("tab10", len(sorted_k))

for i, k in enumerate(sorted_k):
    traj = trajectories[k]
    plt.plot(range(1, len(traj) + 1), traj,
             label=f"p=0.0, k={k}",
             linewidth=2,
             color=palette[i])

plt.title("Average spectral gap comparison", fontsize=14)
plt.xlabel("Time (Round)", fontsize=12)
plt.ylabel("Average spectral gap", fontsize=12)
plt.legend(loc="lower right")
plt.tight_layout()

output_file = os.path.join(results_folder, "plot_comparison_time_p0_vs_p1_python.png")
plt.savefig(output_file, dpi=300)
print(f"Grafico salvato in: {output_file}")