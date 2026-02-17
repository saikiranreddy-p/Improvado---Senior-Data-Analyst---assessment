# Senior Marketing Analyst – Technical Assignment (BigQuery + Tableau)

## Project Summary
This project unifies raw advertising performance data from **Facebook Ads**, **Google Ads**, and **TikTok Ads** into a single, standardized dataset in **Google BigQuery**, then uses **Tableau** to create a one-page cross-channel performance dashboard.

**Goal:** Transform multi-platform CSV exports into a unified model that enables easy cross-channel comparisons of spend, impressions, clicks, conversions, and efficiency metrics.

---

## Tech Stack
- **Storage / Modeling:** Google BigQuery
- **Visualization:** Tableau (Tableau Public for publishing)
- **Input data:** 3 CSV files

---

## Input Data Files
The project starts from the following raw CSVs:
- `01_facebook_ads.csv` – Facebook campaign/ad set metrics  
- `02_google_ads.csv` – Google Ads campaign/ad group metrics  
- `03_tiktok_ads.csv` – TikTok campaign/ad group engagement + watch metrics  

Each platform exports similar concepts with different column names (example: Facebook uses `spend` while Google/TikTok use `cost`).

---

## Step 1 — BigQuery Setup
1. Created a dataset in BigQuery (example: `marketing_ads`)
2. Uploaded CSVs into 3 raw tables:
   - `facebook_ads_raw`
   - `google_ads_raw`
   - `tiktok_ads_raw`

**Notes**
- BigQuery schema was auto-detected during upload.
- Types are standardized during modeling using `SAFE_CAST` to avoid failures due to formatting issues (e.g., strings imported for numeric fields).

---

## Step 2 — Unified Data Model
A unified dataset is created as a **BigQuery View** named:

- `ads_unified`

This view standardizes the schema across platforms and aligns similar concepts that have different names:
- **Spend mapping**
  - Facebook: `spend` → unified `spend`
  - Google/TikTok: `cost` → unified `spend`
- **Ad group mapping**
  - Facebook: `ad_set_id`, `ad_set_name` → unified `ad_group_id`, `ad_group_name`
  - Google: `ad_group_id`, `ad_group_name` → unified `ad_group_id`, `ad_group_name`
  - TikTok: `adgroup_id`, `adgroup_name` → unified `ad_group_id`, `ad_group_name`

### Common columns used across all platforms (in `ads_unified`)
These fields are consistently present for every row and support cross-platform analysis:
- `date`
- `platform`
- `campaign_id`
- `campaign_name`
- `ad_group_id`
- `ad_group_name`
- `impressions`
- `clicks`
- `spend`
- `conversions`

### Calculated (cross-platform) metrics included
These metrics are derived from common fields and work across all platforms:
- `ctr_calc` = clicks / impressions
- `cpc_calc` = spend / clicks
- `cpm_calc` = (spend * 1000) / impressions
- `cvr_calc` = conversions / clicks

### Platform-specific fields (kept without forcing zeros)
Some metrics exist only in certain platform exports. These are kept as nullable fields to avoid misleading “0” values for platforms that do not report the metric:
- Facebook-specific: `engagement_rate`, `reach`, `frequency`
- Google-specific: `conversion_value`, `ctr_reported`, `avg_cpc_reported`, `quality_score`, `search_impression_share`
- TikTok-specific: `video_watch_25`, `video_watch_50`, `video_watch_75`, `video_watch_100`, `likes`, `shares`, `comments`, `engagements`, `video_views`

**Why nullable instead of default zeros?**
A missing column on a platform usually means “not provided / not tracked in this export,” not “true zero.” Using NULL avoids incorrect comparisons and prevents skew in averages and rate-based metrics.

---

## SQL Script
The SQL used to build the unified view is provided in the companion file in this folder:

- `ads_unified.sql`

This script:
- creates/replaces the `ads_unified` view
- standardizes naming and data types using `SAFE_CAST`
- unions the 3 sources into one dataset
- adds calculated performance metrics (`ctr_calc`, `cpc_calc`, `cpm_calc`, `cvr_calc`)

---

## Step 3 — Tableau Dashboard
Tableau uses the unified dataset to create a one-page dashboard.

### Dashboard Title
**Cross-Channel Ads Performance Dashboard**

### Recommended global filters
- `platform` filter (applies to all charts)
- `date` filter (range selector)
- Optional: `campaign_name` filter/search

### Charts included (one-page dashboard)
1. **KPI Strip**
   - Total Spend, Impressions, Clicks, Conversions
   - CTR, CPC (calculated using aggregated fields)

2. **Spend Trend (Line)**
   - Date vs Spend (optionally colored by platform)

3. **CPC by Platform (Bar)**
   - Compares efficiency across channels

4. **CTR vs CVR (Scatter)**
   - CTR on X-axis, CVR on Y-axis
   - Bubble size by Spend

5. **Top Campaigns by Spend (Bar)**
   - Ranks campaigns by total spend
   - Tooltips include CTR/CPC for quick evaluation

6. **Parameter-driven Metric Chart (Optional)**
   - Parameter lets user switch metric (Spend, CTR, CPC, CPM, etc.)
   - Can be shown by platform or campaign

---

## Data Validation (BigQuery Checks)
After creating the unified view, the following checks were run:
- Row counts by platform
- Date coverage (min/max date)
- Aggregates by platform (spend, impressions, clicks, conversions)

These ensure the union and type casting worked as expected before using the data in Tableau.

---

## Deliverables
[text](https://public.tableau.com/views/UnifiedMulti-PlatformAdvertisingPerformance/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
---

## Notes / Assumptions
- The definition of “conversion” is platform-dependent and comes from each platform’s export.
- If a platform does not provide a metric (e.g., TikTok watch depth in Google export), the value is stored as NULL in the unified model.
- Cross-platform metrics (CTR/CPC/CPM/CVR) are calculated consistently from base fields for fair comparisons.

---

## How to Reproduce
1. Create a dataset in BigQuery (e.g., `marketing_ads`)
2. Upload the three CSVs as raw tables:
   - `facebook_ads_raw`
   - `google_ads_raw`
   - `tiktok_ads_raw`
3. Run `ads_unified.sql` to create the unified view/table (`ads_unified`)
4. **Export the unified dataset from BigQuery** (download as CSV)
5. Save the exported file into this repository under:
   - `data/ads_unified.xlsx`
6. Open **Tableau Public** and connect to the exported XLSX:
   - Data Source → **Text File** → select `data/ads_unified.XLSX`
7. Build the one-page dashboard and publish to Tableau Public to generate the live link
