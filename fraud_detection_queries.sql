-- =========================================================
-- REDFLAG SQL
-- Financial Fraud Detection & Transaction Risk Analysis
-- =========================================================
--
-- Project: The Unlox Academy Minor Project
-- Database: redflag
-- Table: transactions
--
-- This file contains the final P1-P12 fraud detection
-- queries only. Exploratory/verification queries have
-- been removed.
--
-- =========================================================


-- =========================================================
-- P1: VELOCITY FRAUD
-- =========================================================
-- Signature:
-- A user_id with 30 or more transactions in a single day.
-- =========================================================

SELECT
    user_id,
    DATE(txn_time) AS transaction_date,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY
    user_id,
    DATE(txn_time)
HAVING
    transaction_count >= 30;


-- =========================================================
-- P2: ROUND-AMOUNT CLUSTERING
-- =========================================================
-- Signature:
-- A user making 15 or more transactions using
-- suspicious round amounts.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS round_transaction_count
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY
    user_id
HAVING
    round_transaction_count >= 15;


-- =========================================================
-- P3: CARD TESTING
-- =========================================================
-- Signature:
-- A user making 30 or more transactions under ₹10
-- within a single day.
-- =========================================================

SELECT
    user_id,
    DATE(txn_time) AS transaction_date,
    COUNT(*) AS small_transaction_count
FROM transactions
WHERE amount < 10
GROUP BY
    user_id,
    DATE(txn_time)
HAVING
    small_transaction_count >= 30;


-- =========================================================
-- P4: FAILED-THEN-SUCCEEDED
-- =========================================================
-- Simplified signature:
-- A user with 20 or more FAILED transactions.
--
-- Advanced version requires matching FAILED -> SUCCESS
-- pairs within 2 minutes and is not used here.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS failed_transaction_count
FROM transactions
WHERE status = 'FAILED'
GROUP BY
    user_id
HAVING
    failed_transaction_count >= 20;


-- =========================================================
-- P5: ODD-HOUR CONCENTRATION
-- =========================================================
-- Signature:
-- A user with at least 30 total transactions where
-- 80% or more occur between 2 AM and 5 AM
-- (hours 2, 3 and 4).
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) AS odd_hour_transactions
FROM transactions
GROUP BY
    user_id
HAVING
    total_transactions >= 30
    AND odd_hour_transactions / total_transactions >= 0.80;


-- =========================================================
-- P6: MULE ACCOUNTS
-- =========================================================
-- Simplified signature:
-- A user with 8 or more CREDIT transactions.
--
-- Advanced version uses a correlated subquery to detect
-- rapid CREDIT -> DEBIT movement and is not used here.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS credit_transactions_count
FROM transactions
WHERE txn_type = 'CREDIT'
GROUP BY
    user_id
HAVING
    credit_transactions_count >= 8;


-- =========================================================
-- P7: REFUND ABUSE
-- =========================================================
-- Signature:
-- A user with 20+ total transactions and a refund ratio
-- greater than 40%.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS total_transactions,
    SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) AS refund_transactions
FROM transactions
GROUP BY
    user_id
HAVING
    total_transactions >= 20
    AND refund_transactions / total_transactions > 0.40;


-- =========================================================
-- P8: MERCHANT COLLUSION
-- =========================================================
-- Signature:
-- The top 5 users by transaction volume account for
-- more than 60% of a merchant's total transaction value.
--
-- Steps:
-- 1. Calculate volume per merchant + user.
-- 2. Rank users within each merchant.
-- 3. Calculate Top-5 volume.
-- 4. Calculate merchant total volume.
-- 5. Compare Top-5 volume with merchant total.
-- =========================================================

WITH user_volumes AS (

    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_volume
    FROM transactions
    GROUP BY
        merchant_id,
        user_id
),

ranked_users AS (

    SELECT
        merchant_id,
        user_id,
        user_volume,

        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_volume DESC
        ) AS user_rank

    FROM user_volumes
),

top5_totals AS (

    SELECT
        merchant_id,
        SUM(user_volume) AS top5_volume
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY
        merchant_id
),

merchant_totals AS (

    SELECT
        merchant_id,
        SUM(amount) AS merchant_total_volume
    FROM transactions
    GROUP BY
        merchant_id
)

SELECT
    t.merchant_id,
    t.top5_volume,
    m.merchant_total_volume,
    ROUND(
        t.top5_volume / m.merchant_total_volume * 100,
        2
    ) AS top5_percentage
FROM top5_totals t
JOIN merchant_totals m
    ON t.merchant_id = m.merchant_id
WHERE
    t.top5_volume / m.merchant_total_volume > 0.60
ORDER BY
    top5_percentage DESC;


-- =========================================================
-- P9: JUST-UNDER-THRESHOLD / STRUCTURING
-- =========================================================
-- Signature:
-- A user with 10 or more transactions at exactly ₹9,999.
-- =========================================================

SELECT
    user_id,
    COUNT(*) AS structuring_transaction_count
FROM transactions
WHERE amount = 9999.00
GROUP BY
    user_id
HAVING
    structuring_transaction_count >= 10;


-- =========================================================
-- P10: DORMANT-THEN-ACTIVE
-- =========================================================
-- Signature:
-- A user has a 90+ day gap between consecutive
-- transactions and then has 15+ transactions after
-- the dormant period.
-- =========================================================

WITH transaction_gaps AS (

    SELECT
        user_id,
        txn_time,

        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time

    FROM transactions
),

dormant_points AS (

    SELECT
        user_id,
        txn_time AS restart_time

    FROM transaction_gaps

    WHERE DATEDIFF(
        txn_time,
        previous_txn_time
    ) >= 90
),

post_gap_activity AS (

    SELECT
        d.user_id,
        COUNT(*) AS post_gap_transactions

    FROM dormant_points d

    JOIN transactions t
        ON t.user_id = d.user_id
        AND t.txn_time > d.restart_time

    GROUP BY
        d.user_id
)

SELECT
    user_id,
    post_gap_transactions
FROM post_gap_activity
WHERE
    post_gap_transactions >= 15
ORDER BY
    user_id;


-- =========================================================
-- P11: VELOCITY SPIKE
-- =========================================================
-- Signature:
-- Peak monthly transaction count is at least 20 AND
-- the peak is at least 5x the user's average monthly count.
-- =========================================================

WITH monthly_counts AS (

    SELECT
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS transaction_month,
        COUNT(*) AS monthly_transaction_count

    FROM transactions

    GROUP BY
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m')
),

user_statistics AS (

    SELECT
        user_id,
        AVG(monthly_transaction_count)
            AS average_monthly_transactions,
        MAX(monthly_transaction_count)
            AS peak_monthly_transactions

    FROM monthly_counts

    GROUP BY
        user_id
)

SELECT
    user_id,
    ROUND(
        average_monthly_transactions,
        2
    ) AS average_monthly_transactions,
    peak_monthly_transactions,
    ROUND(
        peak_monthly_transactions
        / average_monthly_transactions,
        2
    ) AS spike_ratio

FROM user_statistics

WHERE
    peak_monthly_transactions >= 20
    AND peak_monthly_transactions
        / average_monthly_transactions >= 5

ORDER BY
    spike_ratio DESC;


-- =========================================================
-- P12: GEOGRAPHIC IMPOSSIBILITY
-- =========================================================
-- Signature:
-- A user makes consecutive transactions from different
-- cities within 60 minutes.
-- =========================================================

WITH transaction_history AS (

    SELECT
        user_id,
        txn_time,
        city,

        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_city,

        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time

    FROM transactions
)

SELECT DISTINCT
    user_id

FROM transaction_history

WHERE
    previous_city IS NOT NULL
    AND city <> previous_city
    AND TIMESTAMPDIFF(
        MINUTE,
        previous_txn_time,
        txn_time
    ) <= 60

ORDER BY
    user_id;