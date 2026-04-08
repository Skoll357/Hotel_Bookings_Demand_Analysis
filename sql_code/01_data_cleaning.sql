-- 1. 数据清洗前检查
-- 1.1 检查总行数
SELECT COUNT(*) FROM hotel_bookings;

-- 1.2 检查缺失值情况（重点检查 children, country, agent, company）
SELECT 
    SUM(CASE WHEN children IS NULL OR children = '' THEN 1 ELSE 0 END) AS missing_children,
    SUM(CASE WHEN country IS NULL OR country = '' THEN 1 ELSE 0 END) AS missing_country,
    SUM(CASE WHEN agent IS NULL OR agent = 'NULL' THEN 1 ELSE 0 END) AS missing_agent,
    SUM(CASE WHEN company IS NULL OR company = 'NULL' THEN 1 ELSE 0 END) AS missing_company
FROM hotel_bookings;

-- 1.3 检查逻辑错误：成人、小孩、婴儿全是 0 的订单
SELECT COUNT(*) 
FROM hotel_bookings 
WHERE adults = 0 AND children = 0 AND babies = 0;

-- 1.4 检查异常价格：ADR 小于等于 0 的情况（通常免费房或数据错误）
SELECT COUNT(*) FROM hotel_bookings WHERE adr <= 0;

-- 2. 创建清洗后的表
DROP TABLE IF EXISTS hotel_bookings_cleaned;
CREATE TABLE hotel_bookings_cleaned AS
SELECT
    hotel,
    is_canceled,
    lead_time,
    arrival_date_year,
    arrival_date_month,
    arrival_date_week_number,
    arrival_date_day_of_month,
    stays_in_weekend_nights,
    stays_in_week_nights,
    -- 2.1 处理 adults, children 和 babies 的缺失值
    COALESCE(adults, 0) AS adults,
    COALESCE(children, 0) AS children,
    COALESCE(babies, 0) AS babies,
    meal,
    -- 2.2 处理 country 缺失值
    CASE 
        WHEN country IS NULL OR country = '' OR country = 'NULL' THEN 'Unknown' 
        ELSE country 
    END AS country,
    market_segment,
    distribution_channel,
    is_repeated_guest,
    previous_cancellations,
    previous_bookings_not_canceled,
    reserved_room_type,
    assigned_room_type,
    booking_changes,
    deposit_type,
    -- 2.3 处理 agent 和 company (将字符串 'NULL' 转为数值 0)
    CASE WHEN agent = 'NULL' OR agent IS NULL THEN 0 ELSE CAST(agent AS INTEGER) END AS agent,
    CASE WHEN company = 'NULL' OR company IS NULL THEN 0 ELSE CAST(company AS INTEGER) END AS company,
    days_in_waiting_list,
    customer_type,
    adr,
    required_car_parking_spaces,
    total_of_special_requests,
    reservation_status,
    reservation_status_date
FROM hotel_bookings
WHERE 
    -- 2.4 剔除人数为 0 的异常
    (NOT (adults = 0 AND children = 0 AND babies = 0))
    -- 2.5 剔除负房价
    AND ROUND(adr, 2) > 0;