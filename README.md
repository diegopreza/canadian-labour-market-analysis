# Canadian Labour Market Analysis
**A PostgreSQL analytics project using Statistics Canada Labour Force Survey data (2021–2025)**

---

## Project Overview

This project analyzes Canadian and Ontario employment trends using publicly available Labour Force Survey (LFS) data from Statistics Canada. The goal was to build a portfolio-quality SQL analytics workflow — from raw data ingestion and cleaning, through multi-dimensional querying, to documented findings.

The project demonstrates end-to-end data engineering and analytics skills including:
- Raw data staging and type-safe transformation pipelines
- Complex SQL queries using CTEs, window functions, JOINs, RANK, and CASE segmentation
- Real-world data cleaning and troubleshooting workflows
- Structured documentation of analytical findings

**Tools used:** PostgreSQL · pgAdmin · psql · Python · VS Code

---

## Data Source

**Statistics Canada — Labour Force Survey (LFS)**
- Source: [Statistics Canada Table 14-10-0023-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410002301)
- Coverage: Canada and Ontario
- Period: 2021–2025 (annual)
- Dimensions: Labour force category, gender, age group, geography

---

## Repository Structure

```
canadian-labour-market-analysis/
│
├── data/                        # Raw source CSVs (not tracked in git)
├── schema/
│   └── create_tables.sql        # Table definitions (lfs_raw + lfs_clean)
├── queries/
│   └── analysis_queries.sql     # All 5 analytical queries
├── results/                     # Screenshots of query outputs
├── images/                      # Charts and visualizations
│
├── findings.md                  # Detailed findings narrative
├── executive_summary.md         # High-level summary
└── README.md
```

---

## Database Architecture

### Two-Table Pipeline

**`lfs_raw`** — Staging table. All columns imported as TEXT to avoid import errors from mixed or unexpected formats. Preserves the original StatsCan data structure including metadata columns (vector, coordinate, scalar_factor, symbol).

**`lfs_clean`** — Analytical table. Created by selecting and casting from `lfs_raw`:
- `ref_date` → `ref_year INTEGER`
- `value` → `NUMERIC(10,1)`
- NULL and empty values excluded

```sql
CREATE TABLE lfs_clean AS
SELECT
    CAST(ref_date AS INTEGER) AS ref_year,
    geo,
    labour_force,
    gender,
    age_group,
    CAST(value AS NUMERIC(10,1)) AS value
FROM lfs_raw
WHERE value IS NOT NULL
  AND value <> '';
```

This staging → clean pattern is intentional. It mirrors production data engineering workflows where raw data is preserved and transformations are applied in a separate layer.

### Schema — lfs_clean

| Column | Type | Values |
|---|---|---|
| ref_year | INTEGER | 2021–2025 |
| geo | TEXT | Canada, Ontario |
| labour_force | TEXT | Employment, Full-time employment, Part-time employment, Unemployment |
| gender | TEXT | Total - Gender, Men+, Women+ |
| age_group | TEXT | 15 years and over, 15 to 24 years, 25 to 54 years, 55 years and over |
| value | NUMERIC(10,1) | Employment figures in thousands |

---

## Data Cleaning Steps

Before analysis, the following cleaning operations were applied to `lfs_raw`:

**1. Remove NULL core fields**
```sql
DELETE FROM lfs_raw
WHERE ref_date IS NULL
   OR geo IS NULL
   OR value IS NULL;
```

**2. Trim whitespace across key dimensions**
```sql
UPDATE lfs_raw
SET geo = TRIM(geo),
    labour_force = TRIM(labour_force),
    gender = TRIM(gender),
    age_group = TRIM(age_group);
```
Result: 5,162 rows updated.

**Note on duplicates:** Duplicate investigation revealed that duplicate rows correspond to distinct StatsCan metadata dimensions (vector, coordinate) rather than true data entry errors. These were preserved intentionally to avoid destroying valid observations.

---

## Analytical Queries

### Query 1 — Year-over-Year Employment Growth by Region
*Techniques: CTE, LAG window function, PARTITION BY, ROUND, NULLIF*

Calculates annual percentage change in employment for Canada and Ontario separately, using `LAG()` to compare each year against the prior year.

```sql
WITH yearly_avg AS (
    SELECT
        ref_year,
        geo,
        AVG(value) AS avg_employment
    FROM lfs_clean
    WHERE labour_force = 'Employment'
      AND gender = 'Total - Gender'
      AND age_group = '15 years and over'
    GROUP BY ref_year, geo
),
yoy AS (
    SELECT
        geo,
        ref_year,
        avg_employment,
        LAG(avg_employment) OVER (PARTITION BY geo ORDER BY ref_year) AS prev_year,
        ROUND(
            ((avg_employment - LAG(avg_employment) OVER (PARTITION BY geo ORDER BY ref_year))
            / NULLIF(LAG(avg_employment) OVER (PARTITION BY geo ORDER BY ref_year), 0)) * 100,
        2) AS yoy_pct_change
    FROM yearly_avg
)
SELECT * FROM yoy
WHERE yoy_pct_change IS NOT NULL
ORDER BY geo, ref_year;
```

---

### Query 2 — Ontario's Share of National Employment
*Techniques: Multiple CTEs, JOIN on year key, calculated ratio*

Splits Canada and Ontario into separate CTEs then joins them to compute Ontario's proportional share of national employment each year.

```sql
WITH canada AS (
    SELECT ref_year, AVG(value) AS canada_employment
    FROM lfs_clean
    WHERE geo = 'Canada'
      AND labour_force = 'Employment'
      AND gender = 'Total - Gender'
      AND age_group = '15 years and over'
    GROUP BY ref_year
),
ontario AS (
    SELECT ref_year, AVG(value) AS ontario_employment
    FROM lfs_clean
    WHERE geo = 'Ontario'
      AND labour_force = 'Employment'
      AND gender = 'Total - Gender'
      AND age_group = '15 years and over'
    GROUP BY ref_year
)
SELECT
    c.ref_year,
    c.canada_employment,
    o.ontario_employment,
    ROUND((o.ontario_employment / NULLIF(c.canada_employment, 0)) * 100, 2) AS ontario_share_pct
FROM canada c
JOIN ontario o ON c.ref_year = o.ref_year
ORDER BY c.ref_year;
```

---

### Query 3 — Labour Force Category Rankings
*Techniques: Aggregate with RANK window function*

Ranks Ontario's labour force categories (Employment, Full-time, Part-time, Unemployment) by average value to surface the relative size of each category.

```sql
SELECT
    labour_force,
    ROUND(AVG(value), 1) AS avg_value,
    RANK() OVER (ORDER BY AVG(value) DESC) AS rank
FROM lfs_clean
WHERE geo = 'Ontario'
  AND gender = 'Total - Gender'
  AND age_group = '15 years and over'
GROUP BY labour_force
ORDER BY rank;
```

---

### Query 4 — Running Totals and Year-over-Year Change (Ontario)
*Techniques: CTE, SUM running total window, LAG, calculated YoY change*

Generates a cumulative running total of Ontario employment alongside annual incremental change and percentage change — revealing the deceleration trend across the observation window.

```sql
WITH yearly_totals AS (
    SELECT
        ref_year,
        geo,
        SUM(value) AS total_employment
    FROM lfs_clean
    WHERE labour_force = 'Employment'
      AND gender = 'Total - Gender'
      AND age_group = '15 years and over'
      AND geo = 'Ontario'
    GROUP BY ref_year, geo
)
SELECT
    ref_year,
    total_employment,
    SUM(total_employment) OVER (ORDER BY ref_year) AS running_total,
    total_employment - LAG(total_employment) OVER (ORDER BY ref_year) AS yoy_change,
    ROUND(
        ((total_employment - LAG(total_employment) OVER (ORDER BY ref_year))
        / NULLIF(LAG(total_employment) OVER (ORDER BY ref_year), 0)) * 100,
    2) AS yoy_pct_change
FROM yearly_totals
ORDER BY ref_year;
```

---

### Query 5 — Demographic Segmentation with CASE Tiering
*Techniques: GROUP BY multi-dimension, CASE classification, aggregate filtering*

Segments Ontario employment by age group and gender, then classifies each segment into employment tiers (High / Medium / Low) using CASE — allowing rapid identification of the dominant labour force demographics.

```sql
SELECT
    age_group,
    gender,
    ROUND(AVG(value), 1) AS avg_value,
    CASE
        WHEN AVG(value) > 400  THEN 'High'
        WHEN AVG(value) BETWEEN 100 AND 400 THEN 'Medium'
        ELSE 'Low'
    END AS employment_tier
FROM lfs_clean
WHERE geo = 'Ontario'
  AND labour_force = 'Employment'
  AND age_group != '15 years and over'
  AND gender != 'Total - Gender'
GROUP BY age_group, gender
ORDER BY avg_value DESC;
```

---

## Key Findings

### Finding 1 — Ontario Outpaced National Employment Growth in 2022
Ontario recorded **+4.97% year-over-year employment growth in 2022**, compared to **+4.11% nationally** — the strongest growth year for both regions in the dataset and an indication that Ontario's labour market recovered more strongly coming out of the pandemic period.

### Finding 2 — Employment Growth Decelerated Sharply Across Both Regions
Annual employment growth slowed dramatically between 2022 and 2025. Ontario added approximately **686,000 employment units in 2022** but only **146,000 in 2025** — a **79% decline in annual growth** over four years. Canada followed the same pattern, dropping from +4.11% to +1.67% over the same period. This deceleration pattern is consistent across both geographies, suggesting a structural shift rather than a regional anomaly.

| Year | Ontario YoY Growth | Canada YoY Growth |
|---|---|---|
| 2022 | +4.97% | +4.11% |
| 2023 | +3.05% | +2.97% |
| 2024 | +1.77% | +2.02% |
| 2025 | +0.96% | +1.67% |

### Finding 3 — Ontario Holds a Stable ~39.4–39.7% Share of National Employment
Ontario's share of national employment remained remarkably consistent across all five years, ranging from **39.37% to 39.74%** and peaking in 2023. This stability indicates Ontario tracks the national economy closely with no structural divergence during this period — a notable finding given macroeconomic pressures (interest rate cycles, housing costs) that might have been expected to shift Ontario's relative position.

| Year | Ontario Share |
|---|---|
| 2021 | 39.38% |
| 2022 | 39.71% |
| 2023 | 39.74% |
| 2024 | 39.64% |
| 2025 | 39.37% |

### Finding 4 — Full-Time Employment Runs Nearly 5x Higher Than Part-Time in Ontario
Full-time employment averaged **1,111,300** compared to part-time at **231,300** — a ratio of approximately 4.8:1. This indicates strong labour market attachment among employed Ontarians and suggests the majority of employment growth reflects quality job creation rather than precarious work expansion.

### Finding 5 — Prime Working Age (25–54) Dominates; Youth Employment Shows Near Gender Parity
The 25–54 cohort drives Ontario employment by a wide margin (Men+: 461,600 — High tier; Women+: 423,800 — High tier). The 55+ cohort falls into the Medium tier (Men+: 157,300; Women+: 130,200). Youth employment (15–24) lands in the Low tier but shows near gender parity: **Men+ at 87,000 vs Women+ at 82,700** — a gap of under 5%.

---

## How to Reproduce This Analysis

1. Download LFS data from [Statistics Canada Table 14-10-0023-01](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410002301)
2. Create the PostgreSQL database: `createdb labour_market_analysis`
3. Run `schema/create_tables.sql` to create `lfs_raw` and `lfs_clean`
4. Load CSVs into `lfs_raw` using `COPY` or pgAdmin's import tool
5. Run cleaning steps (see `schema/create_tables.sql`)
6. Run `queries/analysis_queries.sql` to reproduce all five analyses

---

## Author

**Diego Preza**
Senior Administrative Assistant → Business Analyst (in transition)
Toronto, ON · [LinkedIn](https://www.linkedin.com/in/diego-preza/) · [GitHub](https://github.com)

*Built as part of a portfolio project to demonstrate SQL analytics and data engineering skills.*
