-- What was the total quantity sold for all products?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    product_name,
    SUM(qty)
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
GROUP BY
    product_name;


-- What is the total generated revenue for all products before discounts?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    product_name,
    SUM(s.qty * s.price) AS "total"
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
GROUP BY
    product_name;

-- What was the total discount amount for all products?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    product_name,
    ROUND(SUM(((s.discount / 100.00) * s.price) * s.qty), 2) AS "total discount"
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
GROUP BY
    product_name;


--How many unique transactions were there?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    COUNT(DISTINCT txn_id) AS "Unique Transactions"
FROM
    filtered_sales;


--What is the average unique products purchased in each transaction?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    CAST(AVG(unique_products) AS int) AS "avg unique products"
FROM
    (
        SELECT
            txn_id,
            COUNT(DISTINCT prod_id) AS "unique_products"
        FROM
            filtered_sales
        GROUP BY
            txn_id
    ) AS sub_query;

--What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY
            revenue
    ) AS p25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY
            revenue
    ) AS p50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY
            revenue
    ) AS p75
FROM
    (
        SELECT
            txn_id,
            ROUND(
                SUM(
                    (qty * price) - ((discount * qty) / 100.00) * price
                ),
                2
            ) AS "revenue"
        FROM
            filtered_sales
        GROUP BY
            txn_id
    ) as sub_query;

--What is the average discount value per transaction?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    ROUND(AVG(avg_discount), 2) AS "avg_transaction_discount"
FROM
    (
        SELECT
            txn_id,
            AVG(((discount / 100.00) * price) * qty) AS "avg_discount"
        FROM
            filtered_sales
        GROUP BY
            txn_id
    ) AS sub_query;

--What is the percentage split of all transactions for members vs non-members?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    member,
    (
        CAST(COUNT(member) AS FLOAT) / (
            SELECT
                COUNT(*)
            FROM
                filtered_sales
        )
    ) * 100 as member_percentages
FROM
    filtered_sales
GROUP BY
    member;

--What is the average revenue for member transactions and non-member transactions?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    member,
    ROUND(
        AVG(
            (qty * price) - ((discount * qty) / 100.00) * price
        ),
        2
    ) AS "revenue"
FROM
    filtered_sales
GROUP BY
    member;
    
--What are the top 3 products by total revenue before discount?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    product_name,
    ROUND(SUM(s.qty * s.price), 2) AS "revenue"
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
GROUP BY
    product_name
ORDER BY
    revenue DESC
LIMIT
    3;

--What is the total quantity, revenue and discount for each segment?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            filtered_sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    segment_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(((s.discount / 100.00) * s.price) * s.qty), 2) AS total_discount
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
GROUP BY
    segment_name;

--What is the top selling product for each segment?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    ),
    my_temp AS (
        SELECT
            product_name,
            segment_name,
            SUM(s.qty) AS sales
        FROM
            filtered_sales AS s
            JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
        GROUP BY
            product_name,
            segment_name
    ),
    ranked AS (
        SELECT
            product_name,
            segment_name,
            sales,
            ROW_NUMBER() OVER (
                PARTITION BY
                    segment_name
                ORDER BY
                    sales DESC
            ) as ranking
        FROM
            my_temp
    )
SELECT
    segment_name,
    product_name,
    sales
FROM
    ranked
WHERE
    ranking = 1;

--What is the total quantity, revenue and discount for each category?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    category_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    ROUND(SUM(((s.discount / 100.00) * s.price) * s.qty), 2) AS total_discount
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
GROUP BY
    category_name;

--What is the top selling product for each category?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    ),
    my_temp AS (
        SELECT
            category_name,
            product_name,
            SUM(s.qty) AS sales
        FROM
            filtered_sales AS s
            JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
        GROUP BY
            category_name,
            product_name
    ),
    ranked AS (
        SELECT
            category_name,
            product_name,
            sales,
            ROW_NUMBER() OVER (
                PARTITION BY
                    category_name
                ORDER BY
                    sales DESC
            ) AS ranking
        FROM
            my_temp
    )
SELECT
    category_name,
    product_name,
    sales
FROM
    ranked
WHERE
    ranking = 1;

--What is the percentage split of revenue by product for each segment?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    ),
    temp_table AS (
        SELECT
            segment_name,
            SUM(s.qty * s.price) AS total
        FROM
            filtered_sales AS s
            JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
        GROUP BY
            segment_name
    )
SELECT
    d.segment_name,
    d.product_name,
    SUM(s.qty * s.price) AS sales,
    MAX(t.total) AS total,
    CAST(
        (
            SUM(s.qty * s.price) / CAST(MAX(t.total) AS FLOAT)
        ) * 100.00 AS INT
    ) AS percentage_split
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
    LEFT JOIN temp_table AS t ON d.segment_name = t.segment_name
GROUP BY
    d.segment_name,
    d.product_name
ORDER BY
    d.segment_name;

--What is the percentage split of revenue by segment for each category?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    ),
    temp_table AS (
        SELECT
            category_name,
            SUM(s.qty * s.price) AS total
        FROM
            filtered_sales AS s
            JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
        GROUP BY
            category_name
    )
SELECT
    d.category_name,
    d.product_name,
    SUM(s.qty * s.price) AS sales,
    MAX(t.total) AS total,
    CAST(
        (
            SUM(s.qty * s.price) / CAST(MAX(t.total) AS FLOAT)
        ) * 100.00 AS INT
    ) AS percentage_split
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
    LEFT JOIN temp_table AS t ON d.category_name = t.category_name
GROUP BY
    d.category_name,
    d.product_name
ORDER BY
    d.category_name;

--What is the percentage split of total revenue by category?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    d.category_name,
    SUM(s.qty * s.price) AS sales,
    (
        SELECT
            SUM(qty * price) AS total
        FROM
            balanced_tree.sales
    ) AS total,
    CAST(
        (
            SUM(s.qty * s.price) / CAST(
                (
                    SELECT
                        SUM(qty * price) AS total
                    FROM
                        balanced_tree.sales
                ) AS FLOAT
            )
        ) * 100.00 AS INT
    ) AS percentage_split
FROM
    balanced_tree.sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
GROUP BY
    d.category_name
ORDER BY
    d.category_name;

--What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    )
SELECT
    d.product_name,
    COUNT(DISTINCT s.txn_id) AS product_transactions,
    total_transactions.total AS total_transactions,
    (
        COUNT(DISTINCT s.txn_id)::FLOAT / total_transactions.total
    ) AS penetration
FROM
    filtered_sales AS s
    JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
    JOIN (
        SELECT
            COUNT(DISTINCT txn_id) AS total
        FROM
            filtered_sales
    ) AS total_transactions ON true
WHERE
    s.qty > 0
GROUP BY
    d.product_name,
    total_transactions.total
ORDER BY
    penetration DESC;

--What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH
    date_range AS (
        SELECT
            DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
            DATE_TRUNC ('month', CURRENT_DATE) - INTERVAL '1 second' AS end_date
    ),
    filtered_sales AS (
        SELECT
            *
        FROM
            balanced_tree.sales
        WHERE
            start_txn_time >= (
                SELECT
                    start_date
                FROM
                    date_range
            )
            AND start_txn_time <= (
                SELECT
                    end_date
                FROM
                    date_range
            )
    ),
    transaction_products AS (
        SELECT
            txn_id,
            product_name
        FROM
            filtered_sales AS s
            JOIN balanced_tree.product_details AS d ON s.prod_id = d.product_id
        WHERE
            s.qty > 0
    ),
    combinations AS (
        SELECT
            tp1.product_name AS product1,
            tp2.product_name AS product2,
            tp3.product_name AS product3,
            tp1.txn_id
        FROM
            transaction_products AS tp1
            JOIN transaction_products AS tp2 ON tp1.txn_id = tp2.txn_id
            AND tp1.product_name < tp2.product_name
            JOIN transaction_products AS tp3 ON tp1.txn_id = tp3.txn_id
            AND tp2.product_name < tp3.product_name
    )
SELECT
    product1,
    product2,
    product3,
    COUNT(*) AS combination_count
FROM
    combinations
GROUP BY
    product1,
    product2,
    product3
ORDER BY
    combination_count DESC
LIMIT
    1;
---