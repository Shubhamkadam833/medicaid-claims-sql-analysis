# Medicaid Claims Analysis SQL

## Overview

This SQL script demonstrates production level data analysis techniques applied to a mock Medicaid healthcare claims dataset. It solves a real business problem that compliance teams and healthcare finance analysts face daily: raw claims data arrives with duplicates, incomplete fields, and inconsistent provider submissions that make cost reporting unreliable.

The script builds a clean analytical layer in four logical stages using Common Table Expressions (CTEs) and Window Functions, keeping the logic modular, readable, and easy to extend.

---

## Business Problem It Solves

Medicaid payers and managed care organizations receive thousands of claim submissions per month. These submissions regularly contain:

- **Duplicate records** submitted multiple times for the same claim
- **Missing pharmacy codes** that block reimbursement processing
- **Inconsistent billing** across months that requires trend tracking per provider

This script addresses all three issues in a single, audit ready query.

---

## What the Code Does

| Step | CTE Name | Purpose |
|------|----------|---------|
| 1 | `deduplicated_claims` | Uses `ROW_NUMBER()` to rank each claim by submission date and isolates the most recent valid record |
| 2 | `clean_claims` | Filters to rank 1 records only and flags any missing pharmacy codes using a `CASE` expression |
| 3 | `monthly_provider_costs` | Aggregates total claims, total cost, and missing pharmacy count per provider per month |
| 4 | Final `SELECT` | Applies `LAG()` window function to compute month over month percentage change in provider billing |

---

## Key SQL Techniques Used

- **Common Table Expressions (CTEs)** for clean, readable multi step logic
- **ROW_NUMBER() OVER (PARTITION BY ...)** for deduplication
- **LAG() OVER (PARTITION BY ... ORDER BY ...)** for trend analysis
- **NULLIF()** to safely handle division by zero in percentage calculations
- **DATE_TRUNC()** for monthly time series aggregation
- **CASE expressions** for data quality flagging

---

## Compatibility

Standard ANSI SQL. Compatible with:

- PostgreSQL
- Google BigQuery
- Snowflake
- Amazon Redshift

---

## Files

| File | Description |
|------|-------------|
| `medicaid_claims_analysis.sql` | Main SQL script with full comments |
| `README.md` | This documentation file |

---

## How to Run

1. Load or simulate a `raw_medicaid_claims` table with the columns: `claim_id`, `provider_id`, `provider_name`, `patient_id`, `pharmacy_code`, `claim_date`, `claim_amount`, `service_type`
2. Run the script in your SQL environment of choice
3. The final output gives one row per provider per month with cost totals and month over month trend percentage

---

*Portfolio sample for Data Analyst job applications. All data is mock and for demonstration purposes only.*
