# Redflag-sql-fraud-detection
# 🚩 RedFlag SQL — Financial Fraud Detection

A SQL-based financial fraud detection project that identifies suspicious transaction patterns using **MySQL, aggregation, CTEs, joins, and window functions**.

## 📌 Project Overview

**RedFlag SQL** analyzes financial transaction data to identify potentially fraudulent or anomalous user and merchant behaviour.

The project implements **12 fraud detection patterns**, progressing from basic transaction aggregation to advanced behavioural analysis using SQL window functions.

The objective is to demonstrate how SQL can be applied to real-world **fraud analytics and transaction monitoring**.

---

## 🎯 Objectives

- Identify suspicious transaction behaviour.
- Detect unusual transaction frequency and volume.
- Analyse user transaction patterns.
- Identify potential account takeover behaviour.
- Detect suspicious merchant-user relationships.
- Analyse refund and failed-transaction behaviour.
- Detect geographic inconsistencies.
- Apply advanced SQL techniques to financial data.

---

## 🗃️ Dataset

The project uses a financial transaction dataset containing approximately **200,000 transactions**.

### Key columns

| Column | Description |
|---|---|
| `txn_id` | Unique transaction ID |
| `user_id` | User associated with the transaction |
| `merchant_id` | Merchant associated with the transaction |
| `amount` | Transaction amount |
| `txn_time` | Date and time of transaction |
| `status` | Transaction status |
| `mode` | Transaction method |
| `city` | Transaction location |
| `txn_type` | Transaction type |

---

# 🔍 Fraud Detection Patterns

The project detects the following 12 patterns:

### P1 — Velocity Fraud
Identifies users making **30 or more transactions in a single day**.

**Key SQL concepts:** `GROUP BY`, `DATE()`, `COUNT()`, `HAVING`

---

### P2 — Round-Amount Clustering
Identifies users making **15 or more transactions using predefined round amounts**.

**Key SQL concepts:** `IN`, `GROUP BY`, `COUNT()`, `HAVING`

---

### P3 — Card Testing
Identifies users making **30 or more transactions under ₹10 in a single day**.

**Key SQL concepts:** `WHERE`, `DATE()`, `GROUP BY`, `COUNT()`, `HAVING`

---

### P4 — Failed-Then-Succeeded
Identifies users with **20 or more failed transactions**.

**Key SQL concepts:** `WHERE`, `GROUP BY`, `COUNT()`, `HAVING`

> This implementation uses the simplified version specified in the project brief.

---

### P5 — Odd-Hour Concentration
Identifies users with at least **30 transactions**, where **80% or more** occur between 2 AM and 5 AM.

**Key SQL concepts:** `HOUR()`, `CASE WHEN`, `SUM()`, ratios, `HAVING`

---

### P6 — Mule Accounts
Identifies users with **8 or more CREDIT transactions**.

**Key SQL concepts:** `WHERE`, `GROUP BY`, `COUNT()`, `HAVING`

> This implementation uses the simplified version specified in the project brief.

---

### P7 — Refund Abuse
Identifies users with:

- 20+ total transactions
- More than 40% of transactions being refunds

**Key SQL concepts:** `CASE WHEN`, `SUM()`, `COUNT()`, ratios, `HAVING`

---

### P8 — Merchant Collusion
Identifies merchants where the **top 5 users by transaction volume contribute more than 60% of the merchant's total transaction value**.

**Key SQL concepts:**

- CTEs
- `SUM()`
- `ROW_NUMBER()`
- `PARTITION BY`
- `ORDER BY`
- `JOIN`

**Expected suspects:** 15 merchants

---

### P9 — Just-Under-Threshold Structuring
Identifies users with **10 or more transactions of exactly ₹9,999**.

**Key SQL concepts:** `WHERE`, `GROUP BY`, `COUNT()`, `HAVING`

**Expected suspects:** 20 users

---

### P10 — Dormant-Then-Active
Identifies users who have a **90+ day gap between consecutive transactions**, followed by **15 or more subsequent transactions**.

**Key SQL concepts:**

- `LAG()`
- `PARTITION BY`
- `ORDER BY`
- `DATEDIFF()`
- CTEs
- `JOIN`
- Aggregation

**Result:** 26 suspects

---

### P11 — Velocity Spike
Identifies users whose:

- Peak monthly transaction count is at least **20**
- Peak monthly transaction count is at least **5× their average monthly count**

**Key SQL concepts:**

- CTEs
- `DATE_FORMAT()`
- `COUNT()`
- `AVG()`
- `MAX()`

---

### P12 — Geographic Impossibility
Identifies users making consecutive transactions from **different cities within 60 minutes**.

This pattern can indicate suspicious account access or geographically impossible transaction behaviour.

**Key SQL concepts:**

- `LAG()`
- `PARTITION BY`
- `ORDER BY`
- `TIMESTAMPDIFF()`
- CTEs

**Result:** 15 suspects

---

# 🧠 SQL Techniques Used

This project demonstrates:

### Basic SQL
- `SELECT`
- `WHERE`
- `IN`
- `BETWEEN`
- `GROUP BY`
- `HAVING`
- `ORDER BY`
- `DISTINCT`

### Aggregate Functions
- `COUNT()`
- `SUM()`
- `AVG()`
- `MAX()`
- `MIN()`

### Conditional Aggregation
- `CASE WHEN`
- Conditional `SUM()`

### Date & Time Analysis
- `DATE()`
- `DATE_FORMAT()`
- `HOUR()`
- `DATEDIFF()`
- `TIMESTAMPDIFF()`

### Advanced SQL
- Common Table Expressions (`WITH`)
- Window functions
- `LAG()`
- `ROW_NUMBER()`
- `PARTITION BY`
- `JOIN`

---

# 📂 Repository Structure

```text
redflag-sql-fraud-detection/
│
├── README.md
│
├── fraud_detection_queries.sql
│
└── redflag_transactions.sql
