-- 1. 哪些“窗口期”的订单单价最高？
SELECT 
    hotel,
    CASE 
        WHEN lead_time <= 7 THEN '1. Last Minute (<1W)'
        WHEN lead_time <= 30 THEN '2. 1 Month'
        WHEN lead_time <= 90 THEN '3. 1-3 Months'
        ELSE '4. Long Lead (>3M)'
    END AS booking_window,
    ROUND(AVG(adr), 2) AS avg_adr,
    COUNT(*) AS stay_count
FROM hotel_bookings_cleaned
WHERE is_canceled = 0  -- 只看实际入住的，取消的订单不产生实际收入
GROUP BY hotel, booking_window
ORDER BY hotel, booking_window;

-- 2. 哪个渠道的客人最舍得花钱？
SELECT 
    hotel,
    market_segment,
    ROUND(AVG(adr), 2) AS avg_adr,
    ROUND(AVG(stays_in_weekend_nights + stays_in_week_nights), 2) AS avg_nights
FROM hotel_bookings_cleaned
WHERE is_canceled = 0
GROUP BY hotel, market_segment
ORDER BY avg_adr DESC;

-- 3. 家庭房 vs 纯成人房的价格差异
SELECT 
    hotel,
    CASE WHEN children + babies > 0 THEN 'Family' ELSE 'Adults Only' END AS guest_type,
    ROUND(AVG(adr), 2) AS avg_adr,
    COUNT(*) AS stay_count
FROM hotel_bookings_cleaned
WHERE is_canceled = 0
GROUP BY hotel, guest_type;

-- 4. 预订房型与实际房型不符时，价格如何变化？
SELECT 
    hotel,
    CASE WHEN reserved_room_type = assigned_room_type THEN 'As Reserved' ELSE 'Room Changed' END AS room_status,
    ROUND(AVG(adr), 2) AS avg_adr,
    COUNT(*) AS count
FROM hotel_bookings_cleaned
WHERE is_canceled = 0
GROUP BY hotel, room_status;

-- 5. 寻找平均客单价最高的几个客源国 (样本量 > 100)
WITH base AS (
    SELECT 
        hotel,
        country,
        COUNT(*) AS total_stays,
        AVG(adr) AS avg_adr,
        AVG(stays_in_weekend_nights + stays_in_week_nights) AS avg_stay_nights
    FROM hotel_bookings_cleaned
    WHERE is_canceled = 0
    GROUP BY hotel, country
    HAVING COUNT(*) > 100
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY hotel
            ORDER BY avg_adr DESC
        ) AS rn
    FROM base
)
SELECT 
    hotel,
    country,
    total_stays,
    ROUND(avg_adr, 2) AS avg_adr,
    ROUND(avg_stay_nights, 2) AS avg_stay_nights
FROM ranked
WHERE rn <= 5
ORDER BY hotel, avg_adr DESC;

-- 6. 分别统计总收入贡献前 5 的国家 (ADR * 总间夜)
WITH revenue_by_country AS (
    SELECT 
        hotel,
        country,
        COUNT(*) AS total_stays,
        SUM(adr * (stays_in_weekend_nights + stays_in_week_nights)) AS total_revenue
    FROM hotel_bookings_cleaned
    WHERE is_canceled = 0
    GROUP BY hotel, country
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY hotel 
            ORDER BY total_revenue DESC
        ) AS rn
    FROM revenue_by_country
)
SELECT 
    hotel,
    country,
    total_stays,
    ROUND(total_revenue, 2) AS total_revenue
FROM ranked
WHERE rn <= 5
ORDER BY hotel, total_revenue DESC;