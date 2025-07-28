import matplotlib.pyplot as plt
import numpy as np
from test_lib import run_simulation

# Set consistent figure parameters for single column paper
plt.rcParams.update({
    'font.size': 16,
    'font.weight': 'bold',
    'axes.labelsize': 16,
    'axes.titlesize': 16,
    'xtick.labelsize': 16,
    'ytick.labelsize': 16,
    'legend.fontsize': 9,
    'axes.linewidth': 1.0,
    'grid.linewidth': 1,
    'lines.linewidth': 3.0
})

def create_multihop_efficiency_plot(ax):
    """Create the multihop efficiency plot"""
    # Constants
    M_SIZE = 1 * 1024 * 1024 * 1024  # 1GB in bytes
    SIGNATURE_SIZE = 65              # bytes
    HASH_SIZE = 32                   # bytes (256 bits)

    def calculate_multihop_efficiency(relay_hops, chunk_sizes_bytes):
        """Calculate efficiency for multi-hop protocol"""
        efficiencies = {}
        for chunk_size in chunk_sizes_bytes:
            n = M_SIZE // chunk_size  # number of chunks
            
            efficiency_per_hop = []
            for r in relay_hops:
                # Cost for the originator to send (r=0)
                base_cost = (2 * n + 3) * HASH_SIZE + (n + 1) * SIGNATURE_SIZE
                # Additional cost per relay hop
                per_hop_cost = r * (n * HASH_SIZE + n * SIGNATURE_SIZE)
                
                total_overhead = base_cost + per_hop_cost
                total_size = M_SIZE + total_overhead
                
                efficiency = M_SIZE / total_size
                efficiency_per_hop.append(efficiency)
                
            chunk_kb = chunk_size // 1024
            efficiencies[f'{chunk_kb} KB'] = efficiency_per_hop
            
        return efficiencies

    # Parameters
    relay_hops = np.arange(0, 11, 1)  # 0 to 10 hops
    chunk_sizes_kb = [2, 4, 8, 16, 32, 64]
    chunk_sizes_bytes = [cs * 1024 for cs in chunk_sizes_kb]

    # Calculate efficiencies
    all_efficiencies = calculate_multihop_efficiency(relay_hops, chunk_sizes_bytes)

    # Style map
    style_map = {
        '2 KB':  {'color': '#1f77b4', 'marker': 'o'},
        '4 KB':  {'color': '#ff7f0e', 'marker': 's'},
        '8 KB':  {'color': '#2ca02c', 'marker': '^'},
        '16 KB': {'color': '#d62728', 'marker': 'D'},
        '32 KB': {'color': '#9467bd', 'marker': 'v'},
        '64 KB': {'color': '#8c564b', 'marker': 'p'},
    }

    # Plot data
    for label, efficiency_values in all_efficiencies.items():
        style = style_map.get(label, {'color': 'black', 'marker': 'x'})
        ax.plot(relay_hops, np.array(efficiency_values) * 100, 
                label=f'Chunk Size = {label}',
                marker=style['marker'],
                color=style['color'],
                markersize=4,
                markerfacecolor=style['color'],
                markeredgecolor='white',
                markeredgewidth=0.8)

    # Formatting
    ax.set_xlabel('Relay Hops', fontweight='bold')
    ax.set_ylabel('Efficiency (%)', fontweight='bold')
    ax.set_xticks(np.arange(0, 11, 2))
    ax.set_ylim(65, 101)
    ax.grid(True, linestyle=':', alpha=0.6)
    ax.legend(loc='lower left', frameon=True, fancybox=True, shadow=True, framealpha=0.9)

def create_file_size_performance_plot(ax):
    """Create the file size performance plot"""
    # Parameters
    path_numbers = [1, 2, 4, 8]
    chunk_size = 64 * 1024  # 64 KB
    files_size = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024]  # in MB

    # Store decryption times (only need one set)
    decryption_times = []
    decryption_times_collected = False

    # Plotting styles
    markers = ['o', 's', '^', 'D']
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']

    for i, num_paths in enumerate(path_numbers):
        delivery_times = []
        current_dec_times = []

        for file_size_mb in files_size:
            file_size = file_size_mb * 1024 * 1024  # Convert MB to bytes
            total_chunks = int(file_size / chunk_size)

            # Run simulation
            results = run_simulation(
                TOTAL_CHUNKS=total_chunks,
                RELAYER_CORE=24,
                PROVIDER_CORE=64,
                CUSTOMER_CORE=24,
                M=num_paths,
                N=1
            )

            del_time = results['delivery_time']
            dec_time = results['decryption_time']
            delivery_times.append(del_time)
            
            if not decryption_times_collected:
                current_dec_times.append(dec_time)

        # Plot delivery time curves
        ax.plot(files_size, delivery_times, 
                label=f'Delivery (Paths={num_paths})', 
                marker=markers[i], 
                color=colors[i])
        
        if not decryption_times_collected:
            decryption_times = current_dec_times
            decryption_times_collected = True

    # Plot decryption time curve
    if decryption_times:
        ax.plot(files_size, decryption_times, 
                label='Decryption', 
                marker='x', 
                linestyle='--', 
                color='purple')

    # Formatting
    ax.set_xscale('log', base=2)
    ax.set_yscale('log')
    ax.set_xlabel('File Size (MB)', fontweight='bold')
    ax.set_ylabel('Time (s)', fontweight='bold')
    ax.grid(True, linestyle=':', alpha=0.6)
    
    # Set x-axis ticks
    ax.set_xticks([1, 4, 16, 64, 256, 1024])
    ax.set_xticklabels(['1', '4', '16', '64', '256', '1024'])
    
    ax.legend(loc='upper left', frameon=True, fancybox=True, shadow=True, framealpha=0.9)

# Create the combined figure for single column
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4.5))

# Create both plots
create_multihop_efficiency_plot(ax1)
create_file_size_performance_plot(ax2)

# Adjust layout for single column paper
plt.tight_layout(pad=2.0)

# Save the combined figure
plt.savefig('combined_relay_performance.pdf', format='pdf', dpi=300, bbox_inches='tight')
plt.savefig('combined_relay_performance.png', format='png', dpi=300, bbox_inches='tight')

# Also create individual figures with consistent styling
def save_individual_figures():
    # Individual multihop efficiency figure
    fig1, ax1 = plt.subplots(1, 1, figsize=(6, 4.5))
    create_multihop_efficiency_plot(ax1)
    plt.tight_layout()
    plt.savefig('multihop_efficiency_aligned.pdf', format='pdf', dpi=300, bbox_inches='tight')
    plt.savefig('multihop_efficiency_aligned.png', format='png', dpi=300, bbox_inches='tight')
    plt.close()

    # Individual file size performance figure
    fig2, ax2 = plt.subplots(1, 1, figsize=(6, 4.5))
    create_file_size_performance_plot(ax2)
    plt.tight_layout()
    plt.savefig('file_size_performance_aligned.pdf', format='pdf', dpi=300, bbox_inches='tight')
    plt.savefig('file_size_performance_aligned.png', format='png', dpi=300, bbox_inches='tight')
    plt.close()

save_individual_figures()

print("Generated files:")
print("- combined_relay_performance.pdf/png: Both plots side-by-side")
print("- multihop_efficiency_aligned.pdf/png: Individual multihop efficiency plot")
print("- file_size_performance_aligned.pdf/png: Individual file size performance plot")
print("All figures use consistent styling optimized for single column papers.")