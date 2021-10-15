create or replace view personal_space_db.abungsy_stg.v_seo_tracked_keywords as
(
  -- country level list of tracked keywords
select keyword,'Australia' as country, 'country' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."AU"
UNION ALL
select keyword,'Canada'as country, 'country' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."CA"
UNION ALL
select keyword,'Germany'as country, 'country' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."DE"
UNION ALL
select keyword,'Spain'as country, 'country' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."ES"
UNION ALL
select keyword,'France'as country, 'country' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."FR"
UNION ALL
select keyword,'Mexico'as country, 'country' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."MX"
UNION ALL
select keyword,'United Kingdom'as country, 'country' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."UK"
UNION ALL
select keyword,'United States'as country, 'country' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."US"
UNION ALL
-- combined unique list of tracked keywords
select keyword,'ALL' as country, 'ALL' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."AU"
UNION DISTINCT
select keyword,'ALL'as country, 'ALL' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."CA"
UNION DISTINCT
select keyword,'ALL'as country, 'ALL' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."DE"
UNION DISTINCT
select keyword,'ALL'as country, 'ALL' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."ES"
UNION DISTINCT
select keyword,'ALL'as country, 'ALL' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."FR"
UNION DISTINCT
select keyword,'ALL'as country, 'ALL' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."MX"
UNION DISTINCT
select keyword,'ALL'as country, 'ALL' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."UK"
UNION DISTINCT
select keyword,'ALL'as country, 'ALL' as grouping from "WR_FIVETRAN_DB"."GSHEET_SEO_TRACKED_KEYWORDS"."US");
