-- Use the 'magist' database for the queries
USE magist;

-- Count the total number of orders in the dataset
SELECT 
    COUNT(order_id) AS number_orders
FROM
    orders;

-- Count the number of delivered orders
SELECT 
    COUNT(order_status)
FROM
    orders
WHERE
    order_status = 'delivered';

-- Count the number of canceled orders
SELECT 
    COUNT(order_status)
FROM
    orders
WHERE
    order_status = 'canceled';

-- Retrieve the number of orders grouped by year and month
SELECT 
    YEAR(order_purchase_timestamp) AS order_year, -- Extract the year
    MONTH(order_purchase_timestamp) AS order_month, -- Extract the month
    COUNT(*) AS total_orders -- Total orders for the period
FROM
    orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

-- Count the total number of unique products in the dataset
SELECT 
    COUNT(DISTINCT product_id) AS products_count
FROM
    products;

-- Count the number of products per category, sorted by the number of products in descending order
SELECT 
    product_category_name,
    COUNT(product_category_name) AS n_products
FROM
    products
GROUP BY product_category_name
ORDER BY n_products DESC;

-- Count the number of distinct products present in transactions (order_items)
SELECT 
    COUNT(DISTINCT product_id)
FROM
    order_items;

-- Find the most expensive and the cheapest product price
SELECT DISTINCT
    product_id, price
FROM
    order_items
WHERE
    price IN (
        (SELECT MAX(price) FROM order_items), -- Maximum price
        (SELECT MIN(price) FROM order_items)  -- Minimum price
    );

-- Retrieve the highest and lowest payment values
SELECT 
    MAX(payment_value) AS max_payment,
    MIN(payment_value) AS min_payment
FROM
    order_payments;

-- Count the number of product categories related to tech keywords
SELECT 
   COUNT(product_category_name_english) AS categories_number
FROM
    product_category_name_translation
WHERE
    LOWER(product_category_name_english) LIKE '%audio%' 
    OR LOWER(product_category_name_english) LIKE '%pc%' 
    OR LOWER(product_category_name_english) LIKE '%computer%'
    OR LOWER(product_category_name_english) LIKE '%tablet%'
    OR LOWER(product_category_name_english) LIKE '%telephon%';

-- Analyze sold items and their average price for tech-related categories, showing percentage of total sales and average price
SELECT 
    product_category_name_english AS category, -- Tech product category name
    COUNT(order_items.product_id) AS quantity_items_sold, -- Total sold items in the category
    (COUNT(order_items.product_id) / (SELECT COUNT(product_id) FROM order_items)) * 100 AS percentage, -- Percentage of total sold items
    ROUND(AVG(price)) AS avg_price -- Average price of sold items
FROM
    product_category_name_translation
    JOIN products ON products.product_category_name = product_category_name_translation.product_category_name
    JOIN order_items ON products.product_id = order_items.product_id
    JOIN orders ON order_items.order_id = orders.order_id
WHERE
    product_category_name_english LIKE '%audio%' 
    OR product_category_name_english LIKE '%computer%' 
    OR product_category_name_english LIKE '%tablet%' 
    OR product_category_name_english LIKE '%telephon%' 
    OR product_category_name_english LIKE '%electronics%'
    AND order_status = 'delivered' -- Only include delivered orders
GROUP BY product_category_name_english
ORDER BY avg_price DESC; -- Sort by average price in descending order

-- Analyze sales and satisfaction data for tech products
SELECT 
    SUM(products_per_order) AS tech_items_sold, -- Total tech items sold
    ROUND(AVG(items_price_per_order)) AS avg_item_price, -- Average price per item
    ROUND(AVG(payment_value)) AS avg_order_price, -- Average order price
    ROUND((SUM(products_per_order) / (SELECT COUNT(product_id) FROM order_items)) * 100) AS percentage_sell, -- Percentage of tech sales
    ROUND(AVG(review_score)) AS avg_review_score -- Average review score for tech products
FROM
    (SELECT 
        COUNT(order_items.product_id) AS products_per_order, -- Count products per order
        SUM(price) AS items_price_per_order, -- Total item price per order
        AVG(payment_value) AS payment_value, -- Average payment value per order
        AVG(review_score) AS review_score -- Average review score per order
    FROM
        product_category_name_translation
    JOIN products ON products.product_category_name = product_category_name_translation.product_category_name
    JOIN order_items ON products.product_id = order_items.product_id
    JOIN order_payments ON order_items.order_id = order_payments.order_id
    JOIN order_reviews ON order_payments.order_id = order_reviews.order_id
    JOIN orders ON order_reviews.order_id = orders.order_id
    WHERE
        product_category_name_english LIKE '%audio%' 
        OR product_category_name_english LIKE '%computer%' 
        OR product_category_name_english LIKE '%tablet%' 
        OR product_category_name_english LIKE '%telephon%' 
        OR product_category_name_english LIKE '%electronics%' 
        AND order_status = 'delivered'
    GROUP BY orders.order_id) AS tech_tab;

-- Calculate the average order price for all categories, excluding unavailable or canceled orders
SELECT 
    ROUND(AVG(prices))
FROM
    (SELECT 
        SUM(price) AS prices
    FROM
        order_items
        JOIN orders ON order_items.order_id = orders.order_id
        WHERE orders.order_status NOT IN ("unavailable","canceled")
    GROUP BY order_items.order_id) AS price_orders;

-- Calculate the average client satisfaction level (review score) across all orders
SELECT 
    ROUND(AVG(rev_score)) AS rev_score
FROM
    (SELECT 
        AVG(review_score) AS rev_score
    FROM
        order_reviews
        LEFT JOIN orders ON order_reviews.order_id = orders.order_id
        WHERE orders.order_status NOT IN ('unavailable', 'canceled')
    GROUP BY orders.order_id) AS review_orders;

-- Calculate the average client satisfaction level for tech-related products
SELECT 
    ROUND(AVG(rev_score)) AS rev_score
FROM
    (SELECT 
        AVG(review_score) AS rev_score
    FROM
        order_reviews
        LEFT JOIN orders ON order_reviews.order_id = orders.order_id
        LEFT JOIN order_items ON order_reviews.order_id = order_items.order_id
        LEFT JOIN products ON order_items.product_id = products.product_id
        LEFT JOIN product_category_name_translation USING (product_category_name)
        WHERE
            orders.order_status NOT IN ('unavailable', 'canceled')
            AND product_category_name_english IN ('audio', 'electronics', 'computers_accessories', 'pc_gamer', 'computers', 'tablets_printing_image', 'telephony')
        GROUP BY orders.order_id) AS review_orders;

-- Calculate the average response time to customer reviews in days
SELECT 
    ROUND(AVG(reply_time)) AS reply_time
FROM
    (SELECT 
        AVG(DATEDIFF(review_answer_timestamp, review_creation_date)) AS reply_time
    FROM
        order_reviews
        LEFT JOIN orders ON order_reviews.order_id = orders.order_id
        WHERE orders.order_status NOT IN ('unavailable', 'canceled')
    GROUP BY orders.order_id) AS review_orders;

-- Calculate the delivery time (in days) for high-value products (>800)
SELECT 
    ROUND(AVG(reply_time)) AS reply_time
FROM
    (SELECT 
        AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)) AS reply_time
    FROM
        order_items
        LEFT JOIN orders ON order_items.order_id = orders.order_id
        WHERE orders.order_status = "delivered" AND price > 800
    GROUP BY orders.order_id) AS review_orders;

-- Analyze total orders and average review scores grouped by year and month
SELECT 
    YEAR(order_purchase_timestamp) AS order_year, -- Extract year
    MONTH(order_purchase_timestamp) AS order_month, -- Extract month
    COUNT(*) AS total_orders, -- Total orders for the period
    AVG(review_score) -- Average review score
FROM
    orders
    JOIN order_reviews ON orders.order_id = order_reviews.order_id
GROUP BY order_year, order_month
ORDER BY order_year, order_month;
