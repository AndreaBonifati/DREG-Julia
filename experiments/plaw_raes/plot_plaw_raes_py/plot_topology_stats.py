import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_folder = "results/plaw_raes"
csv_path = os.path.join(results_folder, "structure", "topology_stats_k2_extended.csv")
output_dir = os.path.join(results_folder, "structure")

os.makedirs(output_dir, exist_ok=True)

if not os.path.exists(csv_path):
    raise FileNotFoundError(f"File dati non trovato: {csv_path}")


df = pd.read_csv(csv_path)


p_vals = df.iloc[:, 0]
avg_deg = df.iloc[:, 1]
max_deg = df.iloc[:, 2]
perc_below = df.iloc[:, 4]  
hub_dominance = df.iloc[:, 8] 


sns.set_theme(style="whitegrid")

def create_and_save_plot(x_data, y_data, title, ylabel, filename, color, ylims=None, hline=None):
    """
    Funzione helper per creare i grafici con lo stesso stile.
    """
    plt.figure(figsize=(8, 5)) 
    
    plt.plot(x_data, y_data, 
             marker='o', 
             markersize=8, 
             linewidth=3, 
             color=color)
    
    if hline is not None:
        plt.axhline(y=hline, color='gray', linestyle='--', label=f"Rif ({hline}%)")
    
    plt.title(title, fontsize=14, pad=15)
    plt.xlabel("Mixture Parameter p (Prob. of Standard Degree)", fontsize=12)
    plt.ylabel(ylabel, fontsize=12)
    
    if ylims:
        plt.ylim(ylims)
        
    plt.tight_layout()
    

    out_path = os.path.join(output_dir, filename)
    plt.savefig(out_path, dpi=300)
    plt.close() 
    print(f" -> Salvato: {filename}")

print("Generazione grafici...")


create_and_save_plot(
    x_data=p_vals, 
    y_data=max_deg,
    title="Maximum degree (Influence of the Largest Hub)",
    ylabel="Maximum Degree",
    filename="plot_max_degree_python.png",
    color="rebeccapurple" 
)


create_and_save_plot(
    x_data=p_vals, 
    y_data=hub_dominance,
    title="Hub Dominance ",
    ylabel="% Total edges",
    filename="plot_hub_dominance_python.png",
    color="firebrick" 
)


create_and_save_plot(
    x_data=p_vals, 
    y_data=perc_below,
    title="Degree Inequality (Structural Asymmetry)",
    ylabel="% Nodes < Average",
    filename="plot_inequality_python.png",
    color="darkorange",
    ylims=(40, 100),
    hline=50 
)


create_and_save_plot(
    x_data=p_vals, 
    y_data=avg_deg,
    title="Average Degree Evolution",
    ylabel="Average Degree",
    filename="plot_avg_degree_python.png",
    color="forestgreen", 
    ylims=(0, max(avg_deg) + 2)
)

print(f"\nTutti i grafici sono stati generati in: {output_dir}")