/*
================================================================================
  FILE      : medicaid_claims_analysis.sql
  PURPOSE   : Medicaid Claims Quality Audit and Monthly Cost Trend Analysis
  AUTHOR    : Data Analyst Portfolio Sample
  DATABASE  : Standard ANSI SQL (compatible with PostgreSQL, BigQuery, Snowflake)
================================================================================

  BUSINESS PROBLEM SOLVED:
  Medicaid claims data is frequently submitted with duplicate records, missing
  pharmacy codes, and inconsistent provider billing. This script builds a clean
  analytical layer on top of raw claims data by deduplicating records using
  row numbering, flagging incomplete pharmacy entries for downstream review,
  and computing month over month cost trends per provider using window functions.
  The result gives compliance teams and finance analysts a reliable, audit ready
  view of claims activity without touching the source data.

================================================================================
*/


/* ============================================================
   STEP 1: DEDUPLICATE RAW CLAIMS
   Use ROW_NUMBER to keep only the most recent version of each
   claim based on submission date. Duplicates are ranked out.
   ============================================================ */

WITH deduplicated_claims AS (

    SELECT
        claim_id,
        provider_id,
        provider_name,
        patient_id,
        pharmacy_code,
        claim_date,
        claim_amount,
        service_type,

        /* Rank each claim by submission date within the same claim ID.
           Rank 1 = the most recent and valid submission. */
        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY claim_date DESC
        ) AS claim_rank

    FROM raw_medicaid_claims

),


/* ============================================================
   STEP 2: FILTER TO CLEAN RECORDS ONLY
   Keep only rank 1 records (no duplicates) and flag any claim
   that is missing a pharmacy code so analysts can review it.
   ============================================================ */

clean_claims AS (

    SELECT
        claim_id,
        provider_id,
        provider_name,
        patient_id,
        claim_date,
        claim_amount,
        service_type,

        /* Flag missing or blank pharmacy codes for data quality review */
        CASE
            WHEN pharmacy_code IS NULL OR TRIM(pharmacy_code) = ''
                THEN 'MISSING PHARMACY CODE'
            ELSE pharmacy_code
        END AS pharmacy_code_status,

        /* Extract year and month for trend aggregation */
        DATE_TRUNC('month', claim_date) AS claim_month

    FROM deduplicated_claims

    /* Only keep the most recent valid version of each claim */
    WHERE claim_rank = 1

),


/* ============================================================
   STEP 3: AGGREGATE MONTHLY COSTS PER PROVIDER
   Sum total claim amounts per provider per month.
   ============================================================ */

monthly_provider_costs AS (

    SELECT
        provider_id,
        provider_name,
        claim_month,
        COUNT(claim_id)               AS total_claims,
        SUM(claim_amount)             AS total_cost,
        COUNT(CASE WHEN pharmacy_code_status = 'MISSING PHARMACY CODE'
                   THEN 1 END)        AS missing_pharmacy_count

    FROM clean_claims
    GROUP BY provider_id, provider_name, claim_month

)


/* ============================================================
   STEP 4: CALCULATE MONTH OVER MONTH COST TREND PER PROVIDER
   Use LAG window function to compare each month to the prior
   month and compute the percentage change in total billing.
   ============================================================ */

SELECT
    provider_id,
    provider_name,
    claim_month,
    total_claims,
    total_cost,
    missing_pharmacy_count,

    /* Pull the prior month total cost for this provider */
    LAG(total_cost) OVER (
        PARTITION BY provider_id
        ORDER BY claim_month
    ) AS prior_month_cost,

    /* Calculate percentage change from prior month to current month */
    ROUND(
        100.0 * (
            total_cost - LAG(total_cost) OVER (
                PARTITION BY provider_id
                ORDER BY claim_month
            )
        ) / NULLIF(
            LAG(total_cost) OVER (
                PARTITION BY provider_id
                ORDER BY claim_month
            ), 0
        ), 2
    ) AS month_over_month_pct_change

FROM monthly_provider_costs
ORDER BY provider_id, claim_month;
