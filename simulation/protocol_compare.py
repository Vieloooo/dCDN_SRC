import matplotlib.pyplot as plt
import numpy as np
from matplotlib.gridspec import GridSpec

# Set consistent figure parameters
plt.rcParams.update({
    'font.size': 16,
    'font.weight': 'bold',
    'axes.labelsize': 18,
    'axes.titlesize': 20,
    'xtick.labelsize': 16,
    'ytick.labelsize': 16,
    'legend.fontsize': 14,
    'legend.title_fontsize': 16,
    'axes.linewidth': 1.2,
    'grid.linewidth': 0.8,
    'lines.linewidth': 2.5
})

def create_encoding_efficiency_plot(ax_container):
    """Create the encoding efficiency plot with broken y-axis"""
    # Constants
    M_SIZE = 1 * 1024 * 1024 * 1024  # 1GB in bytes
    SIGNATURE_SIZE = 65 # bytes
    HASH_SIZE = 32  # bytes (256 bits)
    GROUP_ELEMENT_SIZE = 48  # bytes (typical for BLS12-381)

    def calculate_efficiency(chunk_sizes):
        """Calculate encoding efficiency for different protocols"""
        efficiencies = {}

        for chunk_size in chunk_sizes:
            n = M_SIZE // chunk_size  # number of chunks
            
            # FairSwap: |m| + |h|
            fairswap_total = M_SIZE + HASH_SIZE
            efficiencies.setdefault('FairSwap', []).append(M_SIZE / fairswap_total)
            
            # FileBounty: |m| + n|h|
            filebounty_total = M_SIZE + n * HASH_SIZE
            efficiencies.setdefault('FileBounty', []).append(M_SIZE / filebounty_total)
            
            # FDE-ElGammal: 8|m| + 6 n |G|
            fde_total = 8 * M_SIZE + 6 * n * GROUP_ELEMENT_SIZE
            efficiencies.setdefault('FDE-ElGamal', []).append(M_SIZE / fde_total)
            
            # FDE-Paillier: 2|m| + n |\mathbb{F}|
            # Using 256 bytes for Paillier field element size (2048-bit modulus)
            PAILLIER_FIELD_SIZE = 256  # bytes
            fde_paillier_total = 2 * M_SIZE + n * PAILLIER_FIELD_SIZE
            efficiencies.setdefault('FDE-Paillier', []).append(M_SIZE / fde_paillier_total)

            # FairDownload: |m| + 2n|σ| + (2n-2)|h|
            fairdownload_total = M_SIZE + 2 * n * SIGNATURE_SIZE + (2 * n - 2) * HASH_SIZE
            efficiencies.setdefault('FairDownload', []).append(M_SIZE / fairdownload_total)
            
            # Bitstream: 2|m| + |h| + |σ|
            bitstream_total = 2 * M_SIZE + HASH_SIZE + SIGNATURE_SIZE
            efficiencies.setdefault('Bitstream', []).append(M_SIZE / bitstream_total)
            
            # Our protocol: |m| + (2n + 3)|h| + (n+1)|σ|
            our_total = M_SIZE + (2 * n + 3) * HASH_SIZE + (n + 1) * SIGNATURE_SIZE
            efficiencies.setdefault('FairRelay', []).append(M_SIZE / our_total)
        return efficiencies

    # Generate chunk sizes from 1KB to 256KB
    chunk_sizes = np.logspace(10, 18, 50, base=2, dtype=int)  # 2^10 (1KB) to 2^18 (256KB)
    chunk_sizes_kb = chunk_sizes / 1024  # Convert to KB for x-axis

    # Calculate efficiencies
    efficiencies = calculate_efficiency(chunk_sizes)

    # Define colors and line styles for each protocol
    style_map = {
        'FairSwap':     {'color': '#1f77b4', 'style': '-', 'marker': 'o'},
        'FileBounty':   {'color': '#ff7f0e', 'style': '--', 'marker': 's'},
        'FDE-ElGamal':  {'color': '#2ca02c', 'style': '-.', 'marker': '^'},
        'FDE-Paillier': {'color': '#8c564b', 'style': '--', 'marker': 'x'},
        'FairDownload': {'color': '#d62728', 'style': ':', 'marker': 'D'},
        'Bitstream':    {'color': '#9467bd', 'style': '-', 'marker': 'v'},
        'FairRelay':    {'color': '#e377c2', 'style': '-', 'marker': 'p'}
    }

    # If ax_container is a single axis (for combined plot), use simple plot
    if hasattr(ax_container, 'semilogx'):
        ax = ax_container
        for protocol, efficiency in efficiencies.items():
            s = style_map[protocol]
            ax.semilogx(chunk_sizes_kb, efficiency, 
                       label=protocol, 
                       color=s['color'],
                       linestyle=s['style'],
                       marker=s['marker'],
                       markersize=4,
                       markevery=5)

        ax.set_xlabel('Chunk Size (KB)', fontsize=18, fontweight='bold')
        ax.set_ylabel('(|m| / |total message|)', fontsize=18, fontweight='bold')
        ax.grid(True, linestyle=':', alpha=0.6)
        ax.set_xticks([1, 2, 4, 8, 16, 32, 64, 128, 256])
        ax.get_xaxis().set_major_formatter(plt.ScalarFormatter())
        ax.set_ylim(0.0, 1.0)
        ax.legend(loc='lower right', frameon=True, fancybox=True, shadow=True, framealpha=0.9)
    
    # If ax_container is a figure (for individual plot), create broken axis
    else:
        fig = ax_container
        # Create broken y-axis subplot
        ax1 = fig.add_subplot(2, 1, 1)
        ax2 = fig.add_subplot(2, 1, 2, sharex=ax1)
        fig.subplots_adjust(hspace=0.1)

        # Plot on both subplots
        for protocol, efficiency in efficiencies.items():
            s = style_map[protocol]
            for ax in [ax1, ax2]:
                ax.semilogx(chunk_sizes_kb, efficiency, 
                           label=protocol, 
                           color=s['color'],
                           linestyle=s['style'],
                           linewidth=2.5)

        # Set y-axis limits to create a break
        ax1.set_ylim(0.8, 1.01)  # Upper part
        ax2.set_ylim(0.1, 0.6)   # Lower part

        # Hide spines and ticks for a clean break
        ax1.spines['bottom'].set_visible(False)
        ax2.spines['top'].set_visible(False)
        ax1.xaxis.tick_top()
        ax1.tick_params(labeltop=False)
        ax2.xaxis.tick_bottom()

        # Add diagonal lines to indicate the break
        d = .015
        kwargs = dict(transform=ax1.transAxes, color='k', clip_on=False, linewidth=2)
        ax1.plot((-d, +d), (-d, +d), **kwargs)
        ax1.plot((1 - d, 1 + d), (-d, +d), **kwargs)
        kwargs.update(transform=ax2.transAxes)
        ax2.plot((-d, +d), (1 - d, 1 + d), **kwargs)
        ax2.plot((1 - d, 1 + d), (1 - d, 1 + d), **kwargs)

        # Labels and formatting
        ax2.set_xlabel('Chunk Size (KB)', fontsize=18, fontweight='bold')
        fig.text(0.06, 0.5, '(|m| / |total message|)', 
                va='center', rotation='vertical', fontsize=18, fontweight='bold')

        # Grid and ticks
        for ax in [ax1, ax2]:
            ax.grid(True, linestyle=':', alpha=0.6)
            ax.tick_params(axis='y', labelsize=16)
        ax2.tick_params(axis='x', labelsize=16)
        ax2.set_xticks([1, 2, 4, 8, 16, 32, 64, 128, 256])
        ax2.get_xaxis().set_major_formatter(plt.ScalarFormatter())

        # Legend
        handles, labels = ax1.get_legend_handles_labels()
        fig.legend(handles, labels, loc='upper right', bbox_to_anchor=(0.98, 0.85),
                  fontsize=14, frameon=True, fancybox=True, shadow=True, framealpha=0.9)

def create_gas_cost_plot(ax):
    """Create the gas cost comparison plot"""
    # Data
    protocols = ['FairSwap', 'FileBounty', 'FDE-ElGamal', 'FDE-Paillier', 'FairDownload', 'FairRelay']
    op_usd = [14.755, 1.9295, 3.4787523, 3.7810028, 5.4366046, 0]
    pem_usd_16kb = [50.621, 18.841, 3.4787523, 3.7810028, 31.78, 3.03652225]
    pem_usd_32kb = [383.0322333, 18.841, 3.4787523, 3.7810028, 54.48, 3.03652225]


    # Set up bar positions
    x = np.arange(len(protocols))
    width = 0.25

    # Create bars
    bars1 = ax.bar(x - width, op_usd, width, label='Optimistic Cost', 
                   color='lightblue', edgecolor='black', linewidth=0.8, 
                   hatch='||||', alpha=0.8)
    bars2 = ax.bar(x, pem_usd_16kb, width, label='Pessimistic Cost (16KB)', 
                   color='lightcoral', edgecolor='black', linewidth=0.8, 
                   hatch='///', alpha=0.8)
    bars3 = ax.bar(x + width, pem_usd_32kb, width, label='Pessimistic Cost (32KB)', 
                   color='lightgreen', edgecolor='black', linewidth=0.8, 
                   hatch='...', alpha=0.8)

    ax.set_ylabel('Cost (USD)')
    ax.set_xticks(x)
    ax.set_xticklabels(protocols, rotation=45, ha='right')
    ax.set_yscale('log')
    ax.grid(True, linestyle=':', alpha=0.6, axis='y')
    ax.set_axisbelow(True)
    
    # Set y-axis range
    max_value = max(max(op_usd), max(pem_usd_16kb), max(pem_usd_32kb))
    min_value = min([x for x in op_usd + pem_usd_16kb + pem_usd_32kb if x > 0])
    ax.set_ylim(min_value * 0.5, max_value * 2)
    
    # Add legend
    ax.legend(loc='upper right', frameon=True, fancybox=True, shadow=True, framealpha=0.9)

# Create the combined figure (simplified encoding plot for space)
fig = plt.figure(figsize=(16, 6))
gs = GridSpec(1, 2, figure=fig)

# Create encoding efficiency subplot (simplified for combined view)
ax1 = fig.add_subplot(gs[0, 0])
create_encoding_efficiency_plot(ax1)

# Create gas cost subplot
ax2 = fig.add_subplot(gs[0, 1])
create_gas_cost_plot(ax2)

# Adjust layout
plt.tight_layout(pad=3.0)

# Save the combined figure
plt.savefig('combined_comparison.pdf', format='pdf', dpi=300, bbox_inches='tight')
plt.savefig('combined_comparison.png', format='png', dpi=300, bbox_inches='tight')

# Also create individual figures with consistent styling
def save_individual_figures():
    # Create individual encoding efficiency figure with broken axis
    fig1 = plt.figure(figsize=(8, 8))  # Taller for broken axis
    create_encoding_efficiency_plot(fig1)
    plt.tight_layout(rect=[0.08, 0, 1, 0.95])
    plt.savefig('encoding_efficiency_aligned.pdf', format='pdf', dpi=300, bbox_inches='tight')
    plt.savefig('encoding_efficiency_aligned.png', format='png', dpi=300, bbox_inches='tight')
    plt.close()

    # Create individual gas cost figure  
    fig2, ax2 = plt.subplots(1, 1, figsize=(8, 6))
    create_gas_cost_plot(ax2)
    plt.tight_layout()
    plt.savefig('gas_cost_aligned.pdf', format='pdf', dpi=300, bbox_inches='tight')
    plt.savefig('gas_cost_aligned.png', format='png', dpi=300, bbox_inches='tight')
    plt.close()

save_individual_figures()

print("Generated files:")
print("- combined_comparison.pdf/png: Both plots side-by-side (simplified encoding)")
print("- encoding_efficiency_aligned.pdf/png: Individual encoding plot with broken y-axis")
print("- gas_cost_aligned.pdf/png: Individual gas cost plot")
print("All figures use consistent styling and will align properly in LaTeX.")