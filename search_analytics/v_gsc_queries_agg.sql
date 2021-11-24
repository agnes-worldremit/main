
create or replace view personal_space_db.abungsy_stg.v_gsc_queries_agg as (
select  date
, YrMonth
, week_start
, week_ending
-- , country
, country_name
, region_name
, sub_region_name
, device
--, k.keyword
, is_tracked
, category
, sum(seo_clicks) seo_clicks
, sum(seo_impressions) seo_impressions
, sum(seo_position_total) seo_position_total   -- to calculate weighted position, so can be grouped in different ways
from personal_space_db.abungsy_stg.v_gsc_queries
group by 1,2,3,4,5,6,7,8,9,10);
