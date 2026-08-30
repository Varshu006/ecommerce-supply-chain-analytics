CREATE DATABASE olist_db;
-- 1. Customers Table
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

SELECT * FROM customers;
-- 2. Sellers Table
CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

SELECT * FROM sellers;

-- 3. Products Table
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

SELECT * FROM products;

-- 4. Orders Table
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

SELECT * FROM orders;

-- 5. Order Items Table
CREATE TABLE order_items (
    order_id VARCHAR(50) REFERENCES orders(order_id),
    order_item_id INT,
    product_id VARCHAR(50) REFERENCES products(product_id),
    seller_id VARCHAR(50) REFERENCES sellers(seller_id),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10, 2),
    freight_value NUMERIC(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);

SELECT * FROM order_items;

DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);



SELECT 
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM sellers) AS total_sellers,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM order_items) AS total_order_items;

-- Over all Delivery Late Rate CAlculate karien

SELECT 
   COUNT(order_id) AS total_delivered_orders,
   COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END)AS late_orders,
   ROUND(
        100.0* COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END)/COUNT(order_id),
		2
   ) AS late_delivery_percentage
 FROM orders
 WHERE order_status = 'delivered'
 AND order_delivered_customer_date IS NOT NULL;
   
-- State-wise delivery bottleneck identify karien(FEGIONAL analysis)
SELECT 
    c.customer_state,
    COUNT(o.order_id) AS total_orders,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS late_orders,
    ROUND(
        100.0 * COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) / COUNT(o.order_id), 
        2
    ) AS state_late_percentage,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)))::numeric, 1) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(o.order_id) > 100
ORDER BY state_late_percentage DESC;

-- CARRIER LAG VS. SELLER LAG ANALYSIS(delay constriant identify karein)
SELECT 
    ROUND(AVG(EXTRACT(DAY FROM (order_approved_at - order_purchase_timestamp)))::numeric, 2) AS avg_approval_days,
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_carrier_date - order_approved_at)))::numeric, 2) AS avg_seller_dispatch_days,
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_delivered_carrier_date)))::numeric, 2) AS avg_carrier_transit_days,
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 2) AS avg_total_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- seller-state to customer-state route bottleneck
 SELECT 
    s.seller_state AS origin_state,
    c.customer_state AS destination_state,
    COUNT(o.order_id) AS total_orders,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS late_orders,
    ROUND(
        100.0 * COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) / COUNT(o.order_id), 
        2
    ) AS route_late_percentage,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)))::numeric, 1) AS avg_transit_days
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(o.order_id) >= 200
ORDER BY route_late_percentage DESC
LIMIT 10;

-- stockout risk7inventory velocity analysis
SELECT 
    p.product_category_name,
    COUNT(oi.order_id) AS total_units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price,
    COUNT(DISTINCT oi.seller_id) AS active_sellers,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)))::numeric, 1) AS avg_delivery_days
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY total_units_sold DESC
LIMIT 10;

-- power bi connection& visual setup
CREATE VIEW vw_supply_chain_analysis AS
SELECT 
    o.order_id,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_state,
    c.customer_city,
    s.seller_id,
    s.seller_state,
    p.product_category_name,
    oi.price,
    oi.freight_value,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
        ELSE 0 
    END AS is_late,
    EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) AS total_delivery_days,
    EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date)) AS carrier_transit_days
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;

COPY (SELECT * FROM vw_supply_chain_analysis) TO 'C:\public\vw_supply_chain_analysis.csv' WITH CSV HEADER;

SELECT * FROM vw_supply_chain_analysis;
  