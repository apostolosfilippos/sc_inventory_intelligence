-- ============================================================
-- GOLD LAYER (Databricks SQL)
-- 4 tables, each one feeds a specific Power BI visual
-- ============================================================


-- 1. SALES FACT
--    Feeds: KPI cards, monthly revenue trend, revenue by market

DROP TABLE IF EXISTS sc_inventory_intelligence_esg.default.gold_sales_fact;

CREATE TABLE sc_inventory_intelligence_esg.default.gold_sales_fact AS
SELECT
  s.order_id,
  s.order_item_id,
  s.order_quantity,
  s.product_department,
  s.product_category,
  s.product_name,
  s.customer_id,
  s.customer_market,
  s.customer_region,
  s.customer_country,
  s.warehouse_country,
  s.shipment_mode,
  s.shipment_days_scheduled,
  s.gross_sales,
  s.discount_pct,
  s.net_sales,
  s.profit,
  s.order_date,
  s.shipment_date,
  s.days_to_ship,
  s.late_shipment_flag,
  f.fulfillment_days
FROM sc_inventory_intelligence_esg.default.silver_orders_and_shipments s
LEFT JOIN sc_inventory_intelligence_esg.default.silver_fulfillment f
  ON s.product_name = f.product_name
WHERE s.clean_record_flag = 1;


-- 2. ABC SEGMENTATION
--    Feeds: Pareto chart (Page 2)

DROP TABLE IF EXISTS sc_inventory_intelligence_esg.default.gold_abc_segmentation;

CREATE TABLE sc_inventory_intelligence_esg.default.gold_abc_segmentation AS
SELECT
  product_name,
  total_revenue,
  cumulative_pct,
  CASE
    WHEN cumulative_pct <= 0.80 THEN 'A'
    WHEN cumulative_pct <= 0.95 THEN 'B'
    ELSE 'C'
  END AS abc_segment
FROM (
  SELECT
    product_name,
    total_revenue,
    SUM(total_revenue) OVER (ORDER BY total_revenue DESC)
      / SUM(total_revenue) OVER () AS cumulative_pct
  FROM (
    SELECT
      product_name,
      SUM(net_sales) AS total_revenue
    FROM sc_inventory_intelligence_esg.default.gold_sales_fact
    GROUP BY product_name
  )
);


-- 3. SLA PERFORMANCE
--    Feeds: SLA vs Reality bar chart (Page 1)

DROP TABLE IF EXISTS sc_inventory_intelligence_esg.default.gold_sla_performance;

CREATE TABLE sc_inventory_intelligence_esg.default.gold_sla_performance AS
SELECT
  shipment_mode,
  shipment_days_scheduled AS sla_target_days,
  COUNT(*) AS total_orders,
  ROUND(AVG(days_to_ship), 1) AS avg_actual_days,
  SUM(late_shipment_flag) AS late_orders,
  ROUND(SUM(late_shipment_flag) * 100.0 / COUNT(*), 1) AS late_pct,
  ROUND(AVG(days_to_ship) - shipment_days_scheduled, 1) AS avg_sla_gap
FROM sc_inventory_intelligence_esg.default.gold_sales_fact
GROUP BY shipment_mode, shipment_days_scheduled;


-- 4. DEPARTMENT PROFITABILITY
--    Feeds: Margin by department bar chart (Page 2)

DROP TABLE IF EXISTS sc_inventory_intelligence_esg.default.gold_department_profitability;

CREATE TABLE sc_inventory_intelligence_esg.default.gold_department_profitability AS
SELECT
  product_department,
  COUNT(*) AS total_orders,
  ROUND(SUM(net_sales), 2) AS net_revenue,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND(SUM(profit) / SUM(net_sales) * 100, 1) AS profit_margin_pct,
  ROUND(AVG(discount_pct) * 100, 1) AS avg_discount_pct,
  ROUND(SUM(gross_sales) - SUM(net_sales), 2) AS revenue_lost_to_discount
FROM sc_inventory_intelligence_esg.default.gold_sales_fact
GROUP BY product_department;
