import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# 读取数据
data = {
    'Input KB': [2, 4, 8, 16, 32, 64],
    'Proof Time (s)': [2.443333, 5.69, 9.003333, 14.773333, 34.26, 52.46],
    'Ver Time (s)': [0.56, 0.553333, 0.61, 0.6, 0.516667, 0.63],
    'Prove Mem (GB)': [0.6443862915, 1.111258189, 1.418476105, 2.330669403, 4.398756663, 5.687507629],
    'Ver Mem (GB)': [0.1690953573, 0.1704355876, 0.1697756449, 0.1702613831, 0.1704661051, 0.1704661051]  # 最后一个缺失值用前一个替代
}

# 创建DataFrame
df = pd.DataFrame(data)

# 设置图表参数
fig, ax1 = plt.subplots(figsize=(10, 6))

# 创建第二个y轴
ax2 = ax1.twinx()

# 绘制时间折线图（左y轴）
line1 = ax1.plot(df['Input KB'], df['Proof Time (s)'], 
                 marker='o', linewidth=3, markersize=10, 
                 color='#e74c3c', label='Proof Time', 
                 markerfacecolor='#e74c3c', markeredgecolor='white', markeredgewidth=1.5)

line2 = ax1.plot(df['Input KB'], df['Ver Time (s)'], 
                 marker='s', linewidth=3, markersize=10, 
                 color='#3498db', label='Verification Time',
                 markerfacecolor='#3498db', markeredgecolor='white', markeredgewidth=1.5)

# 绘制内存使用折线图（右y轴）
line3 = ax2.plot(df['Input KB'], df['Prove Mem (GB)'], 
                 marker='^', linewidth=3, markersize=10, 
                 color='#f39c12', label='Proof Memory', 
                 markerfacecolor='#f39c12', markeredgecolor='white', markeredgewidth=1.5,
                 linestyle='--')

line4 = ax2.plot(df['Input KB'], df['Ver Mem (GB)'], 
                 marker='d', linewidth=3, markersize=10, 
                 color='#9b59b6', label='Verification Memory',
                 markerfacecolor='#9b59b6', markeredgecolor='white', markeredgewidth=1.5,
                 linestyle='--')

# 设置左y轴（时间）
ax1.set_xlabel( 'Chunk Size (KB)', fontsize=28, fontweight='bold')
ax1.set_ylabel('Time (s)', fontsize=28, fontweight='bold', color='black')
ax1.tick_params(axis='y', labelcolor='black', labelsize=28)
ax1.tick_params(axis='x', labelsize=28)

# 设置右y轴（内存）
ax2.set_ylabel('Memory Usage (GB)', fontsize=28, fontweight='bold', color='black')
ax2.tick_params(axis='y', labelcolor='black', labelsize=28)


# 设置网格
ax1.grid(True, linestyle=':', alpha=0.6, color='gray')
ax1.set_axisbelow(True)

# 设置x轴为log2刻度
ax1.set_xscale('log', base=2)
ax1.set_xticks(df['Input KB'])
ax1.get_xaxis().set_major_formatter(plt.ScalarFormatter())

# 设置y轴范围
ax1.set_ylim(0, max(df['Proof Time (s)']) * 1.1)
ax2.set_ylim(0, max(df['Prove Mem (GB)']) * 1.1)

# 合并图例
lines1 = line1 + line2
lines2 = line3 + line4
labels1 = [l.get_label() for l in lines1]
labels2 = [l.get_label() for l in lines2]
ax1.legend(lines1 + lines2, labels1 + labels2, fontsize=21, loc='upper left', 
           frameon=True, fancybox=True, shadow=True, framealpha=0.9)

# 设置边框
for spine in ax1.spines.values():
    spine.set_linewidth(1.2)
    spine.set_color('#333333')
for spine in ax2.spines.values():
    spine.set_linewidth(1.2)
    spine.set_color('#333333')

# 调整布局
plt.tight_layout()

# 显示和保存图表

plt.savefig('zkp_efficiency_time_memory.pdf', format='pdf', dpi=300, bbox_inches='tight')
plt.savefig('zkp_efficiency_time_memory.png', format='png', dpi=300, bbox_inches='tight')