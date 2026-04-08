-- 1. 对比“回头客”与“新客”的行为差异
SELECT 
    hotel,
    is_repeated_guest,
    COUNT(*) AS total_bookings,
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate,
    ROUND(AVG(adr), 2) AS avg_adr,
    ROUND(AVG(lead_time), 2) AS avg_lead_time
FROM hotel_bookings_cleaned
GROUP BY hotel, is_repeated_guest;

-- 2. 客户类型的生命力对比
SELECT 
    hotel,
    customer_type,
    COUNT(*) AS total_bookings,
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate,
    ROUND(AVG(stays_in_weekend_nights + stays_in_week_nights), 2) AS avg_stay_length,
    ROUND(AVG(adr), 2) AS avg_adr
FROM hotel_bookings_cleaned
GROUP BY hotel, customer_type
ORDER BY hotel, total_bookings DESC;

-- 3. 餐食选择如何影响订单稳定性？
SELECT 
    hotel,
    meal,
    COUNT(*) AS total_bookings,
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate,
    ROUND(AVG(stays_in_weekend_nights + stays_in_week_nights), 2) AS avg_stay_length
FROM hotel_bookings_cleaned
WHERE meal IS NOT 'Undefined'
GROUP BY hotel, meal
ORDER BY hotel, total_bookings DESC;

-- 4. 预订的社交构成分析
SELECT 
    hotel,
    CASE 
        WHEN adults = 1 AND children = 0 AND babies = 0 THEN 'Solo'
        WHEN adults = 2 AND children = 0 AND babies = 0 THEN 'Couple'
        WHEN adults > 2 AND children = 0 AND babies = 0 THEN 'Adult Group'
        ELSE 'Family' 
    END AS social_segment,
    COUNT(*) AS total_bookings,
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate,
    ROUND(AVG(adr), 2) AS avg_adr
FROM hotel_bookings_cleaned
GROUP BY hotel, social_segment
ORDER BY hotel, total_bookings DESC;