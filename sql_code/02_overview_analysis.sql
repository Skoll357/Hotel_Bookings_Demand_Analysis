-- 核心看板：规模、风险、价值、行为
SELECT 
    hotel,
    COUNT(*) AS total_bookings, -- 规模：总预订量
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate, -- 风险：取消率
    ROUND(AVG(adr), 2) AS avg_adr, -- 价值：日均单价
    ROUND(AVG(lead_time), 1) AS avg_lead_time, -- 行为：平均提前多久预订
    ROUND(AVG(stays_in_weekend_nights + stays_in_week_nights), 2) AS avg_stay_nights -- 行为：平均住几晚
FROM hotel_bookings_cleaned
GROUP BY hotel;