# Executive Summary

## Canadian Labour Market Analysis (2021–2025)
**Tool:** PostgreSQL · **Data:** Statistics Canada Labour Force Survey · **Period:** 2021–2025

---

## Project Purpose

This project was built to demonstrate end-to-end SQL analytics skills using real, publicly available data.
The workflow covers raw data ingestion, a two-table staging/clean pipeline, data cleaning and type transformation,
and five analytical queries that surface employment trends across Canada and Ontario.

---

## What Was Built

A PostgreSQL analytics pipeline consisting of:

- A raw staging table (`lfs_raw`) preserving original Statistics Canada CSV structure
- A clean analytical table (`lfs_clean`) with proper type casting and NULL handling
- Five SQL queries using CTEs, window functions (LAG, SUM OVER), JOINs, RANK, and CASE segmentation
- Documented findings across year-over-year growth, regional share analysis, labour force composition, and demographic segmentation

---

## Key Findings

**1. Ontario outpaced national employment growth in 2022**
Ontario recorded +4.97% year-over-year growth versus +4.11% nationally — the strongest recovery year in the dataset.

**2. Employment growth decelerated by 79% over four years**
Ontario added 686,000 employment units in 2022 but only 146,000 in 2025.
Canada followed the same trajectory, falling from +4.11% to +1.67%.
This is the most analytically significant finding in the dataset.

**3. Ontario held a stable 39.4–39.7% share of national employment across all five years**
The share peaked at 39.74% in 2023 and contracted marginally to 39.37% by 2025 —
indicating Ontario tracks the national economy with no structural divergence during this period.

**4. Full-time employment ran 4.8x higher than part-time in Ontario**
Full-time averaged 1,111,300 versus part-time at 231,300 —
suggesting employment growth in Ontario reflected quality job creation, not precarious work expansion.

**5. Prime working age (25–54) dominates; youth employment shows near gender parity**
The 25–54 cohort leads at 461,600 (Men+) and 423,800 (Women+).
Youth employment (15–24) shows a gender gap of under 5%: 87,000 vs 82,700.

---

## Skills Demonstrated

| Data engineering | Two-table staging/clean pipeline; raw data preserved, transformations isolated |

| SQL window functions | LAG() for YoY growth, SUM OVER() for running totals, RANK() for category ranking |

| CTEs | Multi-step logic broken into readable, testable subqueries |

| Data cleaning | NULL removal, whitespace trimming, datatype casting, duplicate investigation |

| Analytical thinking | Identifying deceleration pattern, share stability, demographic segmentation |

| Documentation | Findings narrative, executive summary, GitHub README |
