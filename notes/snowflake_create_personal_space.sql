-- Create personal schema
CREATE SCHEMA personal_space_db.wsutton_stg

-- Create table in personal schema
DROP TABLE IF EXISTS personal_space_db.wsutton_stg.test_table;
CREATE TABLE personal_space_db.wsutton_stg.test_table
(
visitor_id varchar
);

-- Insert data into personal schema table
INSERT INTO personal_space_db.wsutton_stg.test_table
WITH CTE AS (
SELECT
s.visitor_id
FROM wr_fivetran_db.ga360_app_fivetran_stg.ga_session as s
WHERE s.visit_start_time::date > '2021-09-14'
LIMIT 10
)
SELECT * FROM CTE;

-- Check data in personal schema table
SELECT * FROM personal_space_db.wsutton_stg.test_table;
