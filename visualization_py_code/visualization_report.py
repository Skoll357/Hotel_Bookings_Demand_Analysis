import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 1. 数据库连接
conn = sqlite3.connect('C:\\Users\\Lenovo\\Desktop\\US graduate study\\Preparations\\2 - personal projects\\2.3 - completed case studies\\Hotel Bookings Analysis\\data\\hotel_booking.db') 

# 2. 全局字体设置：Times New Roman
plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["Times New Roman"]
plt.rcParams['axes.unicode_minus'] = False # 解决负号显示问题

# 3. 数据提取 (SQL)
# 注意：我在标签里加了序号，确保柱状图横轴按顺序排列
query = """
SELECT 
    hotel,
    CASE 
        WHEN lead_time <= 7 THEN '1. < 1 Week'
        WHEN lead_time <= 30 THEN '2. 1 Month'
        WHEN lead_time <= 90 THEN '3. 1-3 Months'
        WHEN lead_time <= 180 THEN '4. 3-6 Months'
        ELSE '5. > 6 Months'
    END AS lead_time_range,
    AVG(is_canceled) * 100 AS cancellation_rate
FROM hotel_bookings_cleaned
GROUP BY hotel, lead_time_range;
"""
df = pd.read_sql(query, conn)

# 4. 绘图
plt.figure(figsize=(12, 7), dpi=300) # 调高分辨率，适合Word打印

# 使用专业色调：深蓝色代表 City，珊瑚橘代表 Resort
palette = {"City Hotel": "#4E79A7", "Resort Hotel": "#F28E2B"}

ax = sns.barplot(
    data=df, 
    x='lead_time_range', 
    y='cancellation_rate', 
    hue='hotel',
    palette=palette,
    edgecolor="black", # 给柱子加个黑边，看起来更锐利
    linewidth=0.8
)

# 5. 细节美化 (英文标签)
plt.title('Impact of Lead Time on Cancellation Rates', fontsize=18, fontweight='bold', pad=20)
plt.xlabel('Booking Lead Time', fontsize=14)
plt.ylabel('Cancellation Rate (%)', fontsize=14)
plt.legend(title='Hotel Type', title_fontsize='13', fontsize='11', loc='upper left')

# 在柱子上方添加百分比标签（这是专业报告的加分项）
for p in ax.patches:
    if p.get_height() > 0: # 避免标注为0的情况
        ax.annotate(f'{p.get_height():.1f}%', 
                    (p.get_x() + p.get_width() / 2., p.get_height()), 
                    ha = 'center', va = 'center', 
                    xytext = (0, 9), 
                    textcoords = 'offset points',
                    fontsize=10,
                    fontweight='bold')

# 调整Y轴范围，给顶部的标签留出空间
plt.ylim(0, 80)

plt.tight_layout()
plt.savefig('C:\\Users\\Lenovo\\Desktop\\US graduate study\\Preparations\\2 - personal projects\\2.3 - completed case studies\\Hotel Bookings Analysis\\01_lead_time_cancellation_bar.png')

# ==========================================
# 图表 2: 临期定价逻辑 (ADR 趋势)
# ==========================================
# --- 数据提取与处理 ---
query2 = """
SELECT 
    hotel,
    CASE 
        WHEN lead_time <= 7 THEN 'Last Minute'
        WHEN lead_time <= 30 THEN '1 Month'
        WHEN lead_time <= 90 THEN '1-3 Months'
        ELSE 'Long Lead'
    END AS booking_window,
    AVG(adr) AS avg_adr
FROM hotel_bookings_cleaned
WHERE is_canceled = 0 -- Only focus on successful stays
GROUP BY hotel, booking_window;
"""
df2 = pd.read_sql(query2, conn)

# 确保 X 轴按逻辑顺序排列
window_order = ['Last Minute', '1 Month', '1-3 Months', 'Long Lead']

# --- 绘图逻辑 ---
plt.figure(figsize=(12, 7), dpi=300)

# 设置 Times New Roman
plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["Times New Roman"]

# 颜色与第一张图保持一致
palette = {"City Hotel": "#4E79A7", "Resort Hotel": "#F28E2B"}

ax = sns.barplot(
    data=df2, 
    x='booking_window', 
    y='avg_adr', 
    hue='hotel',
    order=window_order,
    palette=palette,
    edgecolor="black",
    linewidth=0.8
)

# --- 标签汉化转英文 ---
plt.title('Pricing Strategy Comparison across Booking Windows', fontsize=18, fontweight='bold', pad=20)
plt.xlabel('Booking Window (Lead Time)', fontsize=14)
plt.ylabel('Average Daily Rate (ADR)', fontsize=14)
plt.legend(title='Hotel Type', title_fontsize='13', fontsize='11', loc='upper right')

# 添加数值标注 (Data Labels)
for p in ax.patches:
    if p.get_height() > 0:
        ax.annotate(f'€{p.get_height():.1f}', 
                    (p.get_x() + p.get_width() / 2., p.get_height()), 
                    ha = 'center', va = 'center', 
                    xytext = (0, 9), 
                    textcoords = 'offset points',
                    fontsize=10,
                    fontweight='bold')

# 调整 Y 轴上限，防止标签被标题遮挡
plt.ylim(0, 130)

plt.tight_layout()
plt.savefig('C:\\Users\\Lenovo\\Desktop\\US graduate study\\Preparations\\2 - personal projects\\2.3 - completed case studies\\Hotel Bookings Analysis\\02_pricing_strategy_en.png')

# ==========================================
# 图表 3: 皇冠客户得分排行 (Top 10)
# ==========================================
query3 = """
WITH SegmentMetrics AS (
    SELECT 
        hotel,
        country || ' - ' || customer_type AS segment_name,
        COUNT(*) * (1.0 - AVG(is_canceled)) * AVG(CASE WHEN is_canceled = 0 THEN adr END) AS crown_score
    FROM hotel_bookings_cleaned
    GROUP BY hotel, country, customer_type
    HAVING COUNT(*) > 50
),
RankedSegments AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY hotel ORDER BY crown_score DESC) as rn
    FROM SegmentMetrics
)
SELECT * FROM RankedSegments WHERE rn <= 5;
"""
df = pd.read_sql(query3, conn)

# 创建画布：2 行 1 列
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10), dpi=300)

# 定义颜色 (统一风格)
city_color = "#4E79A7"
resort_color = "#F28E2B"

# --- 子图 1: City Hotel ---
city_df = df[df['hotel'] == 'City Hotel'].sort_values('crown_score', ascending=True)
sns.barplot(data=city_df, x='crown_score', y='segment_name', ax=ax1, color=city_color, edgecolor="black")
ax1.set_title('Top 5 Crown Segments: City Hotel', fontsize=16, fontweight='bold', pad=15)
ax1.set_xlabel('') # 隐藏中间的 X 轴标签
ax1.set_ylabel('Country - Segment Type', fontsize=12)

# --- 子图 2: Resort Hotel ---
resort_df = df[df['hotel'] == 'Resort Hotel'].sort_values('crown_score', ascending=True)
sns.barplot(data=resort_df, x='crown_score', y='segment_name', ax=ax2, color=resort_color, edgecolor="black")
ax2.set_title('Top 5 Crown Segments: Resort Hotel', fontsize=16, fontweight='bold', pad=15)
ax2.set_xlabel('Crown Score (Volume × Success Rate × ADR)', fontsize=12)
ax2.set_ylabel('Country - Segment Type', fontsize=12)

# --- 细节优化 ---
# 给柱子加上数值标签 (在柱子末端显示分数)
for ax in [ax1, ax2]:
    for p in ax.patches:
        ax.annotate(f' {int(p.get_width()):,}', 
                    (p.get_width(), p.get_y() + p.get_height()/2),
                    va='center', fontsize=10, fontweight='bold')

# 自动调整布局，防止左侧标签被切掉
plt.tight_layout()

# 重点：通过 subplots_adjust 给左侧留出更多空间
plt.subplots_adjust(left=0.25) # 0.25 表示左侧留出 25% 的宽度给标签

# 5. 保存并显示
plt.savefig('C:\\Users\\Lenovo\\Desktop\\US graduate study\\Preparations\\2 - personal projects\\2.3 - completed case studies\\Hotel Bookings Analysis\\03_crown_segments_subplots.png', bbox_inches='tight') # bbox_inches='tight' 确保保存时不切边

conn.close()