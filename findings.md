# Canadian Labour Market Analysis Findings

## Overview

This project analyzes Canadian labour market trends using Statistics Canada Labour Force Survey (LFS) data imported into PostgreSQL.

The dataset was cleaned and transformed using SQL and Python before analytical queries were conducted.

---

## Key Findings

### 1. Ontario Outpaced National Employment Growth in 2022
Ontario recorded +4.97% year-over-year employment growth in 2022, compared to +4.11%
nationally — suggesting Ontario's labour market recovered more strongly coming out of
the pandemic period.

### 2. Employment Growth Decelerated Sharply Across Both Regions
Annual employment growth slowed dramatically between 2022 and 2025. Ontario added
approximately 686,000 employment units in 2022 but only 146,000 in 2025 — a 79%
decline in annual growth over four years. Canada showed the same pattern, dropping
from +4.11% to +1.67% over the same period.

### 3. Ontario Holds a Stable ~39.4–39.7% Share of National Employment
Ontario's contribution to national employment remained remarkably consistent across
all five years, peaking at 39.74% in 2023. This stability suggests Ontario tracks the
national economy closely with no structural divergence during this period.

### 4. Full-Time Employment Dominates Ontario's Labour Market
Full-time employment (1,111,300) ran nearly 4.8x higher than part-time (231,300) in
Ontario across the observed period, indicating strong labour market attachment among
employed Ontarians.

### 5. Prime Working Age (25–54) Drives Ontario Employment
The 25–54 cohort accounts for the highest employment levels by a wide margin —
Men+ at 461,600 and Women+ at 423,800 (High tier). Youth employment (15–24)
shows near gender parity at 87,000 vs 82,700, while the 55+ cohort remains
in the Medium tier at 157,300 and 130,200 respectively.

---

## Technical Workflow

Tools used:
- PostgreSQL
- pgAdmin
- SQL
- Python
- Terminal/psql

Processes completed:
- Data ingestion
- CSV import troubleshooting
- Data cleaning
- Datatype transformation
- Exploratory data analysis
- Aggregate trend analysis
