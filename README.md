SC_Inventory_Intelligence
Supply chain analytics dashboard built with Databricks SQL and Power BI. The goal was to turn raw order, inventory, and fulfillment data into something useful — specifically, to understand which products actually make money, whether shipments meet SLA targets, and how revenue breaks down across markets.
Dashboard
The Power BI report has two pages:
Page 1 — Sales & Delivery Performance
Show Image
KPI cards for total orders (25.9K), gross sales ($5.13M), net revenue ($4.61M), and average fulfillment days (6.1). Below that: monthly revenue trend (2015–2017), revenue by market, and an SLA Target vs Actual Shipping Days chart that compares scheduled vs real delivery times across shipment modes.
Page 2 — Product Profitability
Show Image
ABC segmentation with a segment selector (A/B/C), total profit ($3.27M), and profit margin (0.71). Three visuals: top products by revenue, profit margin by department, and a donut chart showing revenue split by ABC segment — A products drive 72.6% of revenue.
Data Pipeline
Medallion architecture with three layers:

Bronze — Raw CSV ingestion, no transformations. Three tables loaded as-is from source files.
Silver — Cleaning and standardization. Handles messy column names (spaces, inconsistent formatting), casts date parts into proper dates, calculates net sales, days to ship, late shipment flags, inventory values, and filters out bad records.
Gold — Four business-ready tables, each feeding specific dashboard visuals:

gold_sales_fact — Main fact table joining orders with fulfillment data
gold_abc_segmentation — Pareto-based product classification (A/B/C)
gold_sla_performance — SLA target vs actual shipping days by mode
gold_department_profitability — Revenue, profit, margin, and discount impact by department



Data Sources
Three CSV files (~30K orders, 118 products):
FileRowsDescriptionorders_and_shipments.csv30,871Orders with customer, product, shipment, and financial datainventory.csv4,200Monthly warehouse inventory levels and cost per unitfulfillment.csv118Average fulfillment days per product
Tools

Databricks SQL — Data pipeline (Bronze → Silver → Gold)
Power BI — Dashboard (2 pages)

Repo Structure
SC_Inventory_Intelligence/
├── README.md
├── data/
│   ├── orders_and_shipments.csv
│   ├── inventory.csv
│   └── fulfillment.csv
├── sql/
│   ├── silver.sql
│   └── gold.sql
└── dashboard/
    ├── page1_sales_delivery.png
    └── page2_product_profitability.png
