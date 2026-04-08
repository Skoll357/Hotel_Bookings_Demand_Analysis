-- 1.1 不同分销渠道的取消情况
SELECT 
    hotel,
    distribution_channel,
    COUNT(*) AS total_bookings,
    SUM(is_canceled) AS canceled_bookings,
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate
FROM hotel_bookings_cleaned
WHERE distribution_channel IS NOT 'Undefined' -- 排除掉未定义的渠道，聚焦主要渠道
GROUP BY hotel, distribution_channel
ORDER BY hotel, cancel_rate DESC;

-- 1.2 预订提前量与取消率的关系 (按月分桶)
SELECT
hotel, 
    CASE 
        WHEN lead_time <= 7 THEN '1. < 1 Week'
        WHEN lead_time <= 30 THEN '2. 1 Month'
        WHEN lead_time <= 90 THEN '3. 1-3 Months'
        WHEN lead_time <= 180 THEN '4. 3-6 Months'
        ELSE '5. Over 6 Months'
    END AS lead_time_bucket,
    COUNT(*) AS total_bookings,
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate
FROM hotel_bookings_cleaned
GROUP BY hotel, lead_time_bucket
ORDER BY hotel, lead_time_bucket;

-- 1.3 押金类型对取消行为的影响
SELECT 
    hotel,
    deposit_type,
    COUNT(*) AS total_bookings,
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate
FROM hotel_bookings_cleaned
GROUP BY hotel, deposit_type;

-- 1.4 特殊要求数量与取消率
SELECT 
    hotel,
    total_of_special_requests,
    COUNT(*) AS total_bookings,
    ROUND(AVG(is_canceled) * 100, 2) AS cancel_rate
FROM hotel_bookings_cleaned
GROUP BY hotel, total_of_special_requests
ORDER BY hotel, total_of_special_requests;