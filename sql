/* =============================================================================
PROJECT: E-Commerce Customer Satisfaction & Retention Analysis
TOOLS  : SQL Server, Power BI, Python
AUTHOR : Jatin Rathour

DESCRIPTION:
This project analyzes customer satisfaction, delivery delays,
seller performance, and repeat purchase behavior using
e-commerce transactional data.

KEY ANALYSIS AREAS:

* Customer Retention Analysis
* Delivery Delay Impact
* Bad Review Analysis
* Seller Performance Evaluation
* Product Category Dissatisfaction
* First Order Experience Analysis
  ============================================================================= */

-- =============================================================================
-- SECTION 1: BASIC DATA EXPLORATION
-- =============================================================================

SELECT *
FROM Customer_Fact;

SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM Customer_Satisfaction_Score;

SELECT COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM Customer_Satisfaction_Score;

SELECT COUNT(order_id) AS total_orders
FROM Customer_Satisfaction_Score;

-- =============================================================================
-- SECTION 2: REPEAT PURCHASE ANALYSIS
-- Objective:
-- Identify customers who placed more than one order
-- and calculate repeat purchase rate.
-- =============================================================================

WITH customer_orders AS (

```
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS total_orders

FROM Customer_Fact

GROUP BY customer_unique_id
```

)

SELECT
COUNT(
CASE
WHEN total_orders > 1 THEN 1
END
) * 100.0 / COUNT(*) AS repeat_purchase_rate

FROM customer_orders;

/*
BUSINESS INSIGHT:
The platform shows a relatively low repeat purchase rate,
indicating weak customer retention and limited long-term loyalty.
*/

-- =============================================================================
-- SECTION 3: DO BAD REVIEWS REDUCE CUSTOMER RETENTION?
-- =============================================================================

WITH customer_summary AS (

```
SELECT
    customer_unique_id,

    COUNT(DISTINCT order_id) AS total_orders,

    MAX(is_bad_review) AS had_bad_review

FROM Customer_Satisfaction_Score

GROUP BY customer_unique_id
```

)

SELECT
had_bad_review,

```
COUNT(*) AS total_customers,

COUNT(
    CASE
        WHEN total_orders > 1 THEN 1
    END
) AS repeat_customers,

ROUND(
    COUNT(
        CASE
            WHEN total_orders > 1 THEN 1
        END
    ) * 100.0 / COUNT(*),
    2
) AS repeat_purchase_rate
```

FROM customer_summary

GROUP BY had_bad_review;

/*
BUSINESS INSIGHT:
Customers who experienced bad reviews showed
lower repeat purchase behavior compared to satisfied customers.
*/

-- =============================================================================
-- SECTION 4: DELIVERY DELAY VS CUSTOMER RETENTION
-- =============================================================================

WITH customer_summary AS (

```
SELECT
    customer_unique_id,

    COUNT(DISTINCT order_id) AS total_orders,

    CASE
        WHEN COUNT(DISTINCT order_id) > 1
        THEN 'Repeat Customer'
        ELSE 'Non-Repeat Customer'
    END AS customer_segment

FROM Customer_Satisfaction_Score

GROUP BY customer_unique_id
```

)

SELECT
cs.customer_segment,

```
COUNT(DISTINCT css.order_id) AS total_orders,

COUNT(
    CASE
        WHEN css.Late = 1 THEN css.order_id
    END
) AS delayed_orders,

ROUND(
    COUNT(
        CASE
            WHEN css.Late = 1 THEN css.order_id
        END
    ) * 100.0
    / COUNT(DISTINCT css.order_id),
    2
) AS delayed_order_rate
```

FROM customer_summary cs

JOIN Customer_Satisfaction_Score css
ON cs.customer_unique_id = css.customer_unique_id

GROUP BY cs.customer_segment;

-- =============================================================================
-- SECTION 5: ARE BAD REVIEWS ASSOCIATED WITH DELIVERY DELAYS?
-- =============================================================================

WITH order_summary AS (

```
SELECT
    review_category,

    COUNT(DISTINCT order_id) AS total_orders,

    SUM(Late) AS delayed_orders

FROM Customer_Satisfaction_Score

GROUP BY review_category
```

)

SELECT
review_category,
total_orders,
delayed_orders,

```
ROUND(
    CAST(delayed_orders AS FLOAT)
    * 100 / total_orders,
    2
) AS delay_percentage
```

FROM order_summary;

-- =============================================================================
-- SECTION 6: SELLER PERFORMANCE ANALYSIS
-- =============================================================================

-- Sellers generating highest delays

SELECT
seller_id,

```
MAX(late_delay) AS highest_delay
```

FROM Customer_Satisfaction_Score

GROUP BY seller_id

ORDER BY highest_delay DESC;

-- Sellers with highest cancellation rates

SELECT
seller_id,

```
COUNT(order_status) AS cancelled_orders
```

FROM Customer_Satisfaction_Score

WHERE order_status = 'Cancelled'

GROUP BY seller_id;

-- Sellers receiving worst reviews

WITH seller_review_summary AS (

```
SELECT
    seller_id,

    COUNT(DISTINCT order_id) AS total_orders,

    SUM(is_bad_review) AS bad_reviews

FROM Customer_Satisfaction_Score

GROUP BY seller_id
```

)

SELECT
seller_id,
total_orders,
bad_reviews,

```
ROUND(
    CAST(bad_reviews AS FLOAT)
    * 100 / total_orders,
    2
) AS bad_review_rate
```

FROM seller_review_summary

WHERE total_orders > 20

ORDER BY bad_review_rate DESC;

-- =============================================================================
-- SECTION 7: PRODUCT CATEGORY DISSATISFACTION ANALYSIS
-- =============================================================================

WITH product_category_summary AS (

```
SELECT
    p.product_category_name AS product_category,

    COUNT(DISTINCT c.order_id) AS total_orders,

    SUM(c.is_bad_review) AS bad_reviews

FROM Customer_Satisfaction_Score c

LEFT JOIN order_items o
    ON o.order_id = c.order_id

LEFT JOIN Products p
    ON o.product_id = p.product_id

WHERE c.Late = 0

GROUP BY p.product_category_name
```

)

SELECT
product_category,
total_orders,
bad_reviews,

```
ROUND(
    CAST(bad_reviews AS FLOAT)
    * 100 / total_orders,
    2
) AS bad_review_percentage
```

FROM product_category_summary

ORDER BY bad_review_percentage DESC;

/*
BUSINESS INSIGHT:
Some product categories generated high dissatisfaction
even without delivery delays, indicating product-quality
or expectation-related issues.
*/

-- =============================================================================
-- SECTION 8: DELAY SEVERITY ANALYSIS
-- =============================================================================

SELECT
late_delay,

```
COUNT(DISTINCT order_id) AS total_orders,

SUM(is_bad_review) AS bad_reviews,

ROUND(
    CAST(SUM(is_bad_review) AS FLOAT)
    * 100
    / COUNT(DISTINCT order_id),
    2
) AS bad_review_percentage
```

FROM Customer_Satisfaction_Score

WHERE late_delay >= 1

GROUP BY late_delay

ORDER BY bad_review_percentage DESC;

/*
BUSINESS INSIGHT:
Customer dissatisfaction increased sharply
when delivery delays exceeded 3 days.
*/
