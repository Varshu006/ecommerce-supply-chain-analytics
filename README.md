# E-Commerce Supply Chain & Regional Logistics Analytics
![Dashboard View](<img width="1326" height="741" alt="Screenshot 2026-08-30 144611" src="https://github.com/user-attachments/assets/17e8b27c-4ed2-4738-9822-9ee4db55ed14" />

)
## Executive Summary
This project analyzes 100k+ Brazilian e-commerce orders (Olist dataset) to identify logistics bottlenecks and regional fulfillment failures. By engineering SQL views in PostgreSQL and visualizing metrics in Power BI, the analysis uncovered critical transit delays on inter-state shipping routes despite a stable national baseline.

## Key Insights & Findings
* **National Performance:** Overall Late Delivery Rate stands at **9.03%** with an average transit time of **12.01 days**.
* **Regional Bottlenecks:** Specific long-distance inter-state routes (e.g., MA $\rightarrow$ ES at 53.85%, SP $\rightarrow$ AL at 26.95%) experience delivery failure rates 2x to 5x higher than the national average.
* **Fulfillment Strategy:** Proposed a decentralized fulfillment hub distribution to cut transit days and mitigate regional seller-to-customer transit spikes.

## Tech Stack
* **Database:** PostgreSQL (Data aggregation, joins, SQL Views)
* **Visualization:** Power BI Desktop (DAX Measures, Matrix Heatmaps, Dynamic Drill-downs)
* **Dataset:** Olist E-Commerce Public Dataset

## Project Architecture
1. **Raw Data Ingestion:** Normalized relational schemas.
2. **SQL Transformation:** Built `vw_supply_chain_analysis` combining orders, logistics transit time, and customer-seller geo-locations.
3. **Power BI Reporting:** Designed executive KPI scorecard and matrix heatmap analysis.
