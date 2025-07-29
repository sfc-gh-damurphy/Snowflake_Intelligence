-- =============================================================================
-- VALIDATION QUERIES FOR Snowflake Intelligence HOL
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Validate Agents were created
-- -----------------------------------------------------------------------------
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA AGENTS;

DESC AGENT snowflake_intelligence.agents."MUSIC_FESTIVAL_AGENT";

SELECT
    util_db.public.se_grader(
        step,
        (actual = expected),
        actual,
        expected,
        description
    ) AS graded_results
FROM (
    SELECT
        'SEDW30' AS step,
        (
            SELECT COUNT(*) 
            FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
        ) AS actual,
        1 AS expected,
        'Agents created for Snowflake Intelligence' AS description
);

-- -----------------------------------------------------------------------------
-- Validate YML and semantic layer were created
-- -----------------------------------------------------------------------------
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA CONFIG;

SELECT
    util_db.public.se_grader(
        step,
        (actual = expected),
        actual,
        expected,
        description
    ) AS graded_results
FROM (
    SELECT
        'SEDW31' AS step,
        (
            SELECT COUNT(*)
            FROM DIRECTORY(@semantic_models)
            WHERE RELATIVE_PATH LIKE 'music_festival.yaml'
        ) AS actual,
        1 AS expected,
        'Semantic Model was created for Snowflake Intelligence' AS description
);
-- -----------------------------------------------------------------------------
-- Validate Cortex Search Service Created
-- -----------------------------------------------------------------------------
USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA CONFIG;

SELECT
    util_db.public.se_grader(
        step,
        (actual = expected),
        actual,
        expected,
        description
    ) AS graded_results
FROM (
    SELECT
        'SEDW32' AS step,
        (
            SELECT COUNT(*) 
            FROM INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES
            WHERE SERVICE_NAME = 'FESTIVAL_CONTRACT_SEARCH'
        ) AS actual,
        1 AS expected,
        'Cortex Search Service Created for Snowflake Intelligence' AS description
);

--If all validations return ✅, you have completed the Snowflake Intelligence Lab 🎉
