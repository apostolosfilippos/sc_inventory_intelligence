-- ============================================================
-- SILVER LAYER (Databricks SQL)
-- Cleaning, type casting, calculated fields, data quality flags
-- ============================================================


-- 1. ORDERS AND SHIPMENTS

DROP TABLE IF EXISTS sc_inventory_intelligence_esg.default.silver_orders_and_shipments;

CREATE TABLE sc_inventory_intelligence_esg.default.silver_orders_and_shipments AS
SELECT
  `Order ID ` AS order_id,
  ` Order Item ID ` AS order_item_id,
  `Order Quantity` AS order_quantity,
  `Product Department` AS product_department,
  `Product Category` AS product_category,
  `Product Name` AS product_name,
  ` Customer ID ` AS customer_id,
  `Customer Market` AS customer_market,
  `Customer Region` AS customer_region,
  `Customer Country` AS customer_country,
  `Warehouse Country` AS warehouse_country,
  `Shipment Mode` AS shipment_mode,
  ` Gross Sales ` AS gross_sales,
  CASE
    WHEN TRIM(` Discount % `) = '-' THEN 0
    ELSE CAST(TRIM(` Discount % `) AS DECIMAL(5,4))
  END AS discount_pct,
  ` Profit ` AS profit,
  MAKE_DATE(` Order Year `, ` Order Month `, ` Order Day `) AS order_date,
  MAKE_DATE(`Shipment Year`, `Shipment Month`, `Shipment Day`) AS shipment_date,
  ` Shipment Days - Scheduled ` AS shipment_days_scheduled,
  ROUND(` Gross Sales ` * (1 -
    CASE
      WHEN TRIM(` Discount % `) = '-' THEN 0
      ELSE CAST(TRIM(` Discount % `) AS DECIMAL(5,4))
    END
  ), 2) AS net_sales,
  DATEDIFF(
    MAKE_DATE(`Shipment Year`, `Shipment Month`, `Shipment Day`),
    MAKE_DATE(` Order Year `, ` Order Month `, ` Order Day `)
  ) AS days_to_ship,
  CASE
    WHEN DATEDIFF(
      MAKE_DATE(`Shipment Year`, `Shipment Month`, `Shipment Day`),
      MAKE_DATE(` Order Year `, ` Order Month `, ` Order Day `)
    ) > ` Shipment Days - Scheduled ` THEN 1
    ELSE 0
  END AS late_shipment_flag,
  CASE
    WHEN DATEDIFF(
      MAKE_DATE(`Shipment Year`, `Shipment Month`, `Shipment Day`),
      MAKE_DATE(` Order Year `, ` Order Month `, ` Order Day `)
    ) BETWEEN 0 AND 30 THEN 1
    ELSE 0
  END AS clean_record_flag
FROM sc_inventory_intelligence_esg.default.orders_and_shipments;


-- 2. INVENTORY

DROP TABLE IF EXISTS sc_inventory_intelligence_esg.default.silver_inventory;

CREATE TABLE sc_inventory_intelligence_esg.default.silver_inventory AS
SELECT
  `Product Name` AS product_name,
  ` Year Month ` AS year_month,
  CAST(
    CONCAT(
      SUBSTR(CAST(` Year Month ` AS STRING), 1, 4), '-',
      SUBSTR(CAST(` Year Month ` AS STRING), 5, 2), '-01'
    )
  AS DATE) AS month_date,
  ` Warehouse Inventory ` AS warehouse_inventory,
  `Inventory Cost Per Unit` AS cost_per_unit,
  ROUND(` Warehouse Inventory ` * `Inventory Cost Per Unit`, 2) AS inventory_value
FROM sc_inventory_intelligence_esg.default.inventory;


-- 3. FULFILLMENT

DROP TABLE IF EXISTS sc_inventory_intelligence_esg.default.silver_fulfillment;

CREATE TABLE sc_inventory_intelligence_esg.default.silver_fulfillment AS
SELECT
  `Product Name` AS product_name,
  ` Warehouse Order Fulfillment (days) ` AS fulfillment_days
FROM sc_inventory_intelligence_esg.default.fulfillment;
