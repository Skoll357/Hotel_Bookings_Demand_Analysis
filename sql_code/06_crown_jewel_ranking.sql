WITH SegmentMetrics AS (
    -- 第一步：按酒店、国家、客户类型聚合核心指标
    SELECT 
        hotel,
        country,
        customer_type,
        COUNT(*) AS total_bookings,
        (1.0 - AVG(is_canceled)) AS success_rate, -- 入住率 (1 - 取消率)
        AVG(CASE WHEN is_canceled = 0 THEN adr END) AS avg_adr_stayed -- 仅计算实际入住的单价
    FROM hotel_bookings_cleaned
    GROUP BY hotel, country, customer_type
    HAVING COUNT(*) > 50 -- 过滤掉样本量太小的组合，保证得分有代表性
),
Scoring AS (
    -- 第二步：计算综合得分 (Score = 订单量 * 入住率 * ADR)
    -- 这个得分反映了该细分市场为酒店带来的“实际稳健收入贡献”
    SELECT 
        *,
        ROUND(total_bookings * success_rate * avg_adr_stayed, 2) AS crown_score
    FROM SegmentMetrics
),
RankedSegments AS (
    -- 第三步：在每个酒店内部进行排名
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY hotel ORDER BY crown_score DESC) as rank
    FROM Scoring
)
-- 最终输出
SELECT 
    hotel,
    rank,
    country,
    customer_type,
    total_bookings,
    ROUND(success_rate * 100, 2) || '%' AS success_rate_pct,
    ROUND(avg_adr_stayed, 2) AS avg_adr,
    crown_score
FROM RankedSegments
WHERE rank <= 10
ORDER BY hotel, crown_score DESC;