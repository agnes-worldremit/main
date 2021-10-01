CREATE SCHEMA personal_space_db.abungsy_stg

-- Create table in personal schema - OPTION 1
DROP TABLE IF EXISTS personal_space_db.abungsy_stg.test_table;
CREATE TABLE personal_space_db.abungsy_stg.test_table

as (select * from WR_FIVETRAN_DB.GA360_WEB_FIVETRAN_STG.GA_SESSION limit 100)


-- create test table in personal schema - OPTION 2
DROP TABLE IF EXISTS personal_space_db.abungsy_stg.test_table;
CREATE TABLE personal_space_db.abungsy_stg.test_table
(
visitor_id varchar
);

-- Insert data into personal schema table
INSERT INTO personal_space_db.abungsy_stg.test_table
WITH CTE AS (
SELECT
s.visitor_id
FROM WR_FIVETRAN_DB.GA360_WEB_FIVETRAN_STG.GA_SESSION as s
WHERE s.visit_start_time::date > '2021-09-14'
LIMIT 10
)
SELECT * FROM CTE;

-- Check data in personal schema table
SELECT * FROM personal_space_db.abungsy_stg.test_table;
