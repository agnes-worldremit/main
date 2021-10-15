-- keyword level SEO metrics from Google Search Console, with keyword categories attached

-- GSC search query data
create or replace view personal_space_db.abungsy_stg.v_gsc_queries as (
select k.date
, to_char(k.date,'YYYY-MM') YrMonth
, to_char(iso_week_start_date,'YYYY-MM-DD') week_start
, to_char(dateadd(day,6,iso_week_start_date),'YYYY-MM-DD') week_ending
, country
, country_name
, region_name
, sub_region_name
, k.device
, k.keyword
, cat.page_category as category
, k.clicks as seo_clicks
, k.impressions as seo_impressions
, k.impressions*k.position as seo_position_total   -- to calculate weighted position, so can be grouped in different ways
from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE" k
left join (select distinct calendar_date, iso_week_start_date from  "WR_DWH_DB"."DIMENSIONS"."D_CALENDAR") on k.date = calendar_date
left join (select distinct lower(country_iso3_code) country_code, country_name, region_name, sub_region_name  from "WR_DWH_DB"."DIMENSIONS"."D_GEOGRAPHY" where is_active = TRUE) geo on k.country = geo.country_code
left join personal_space_db.abungsy_stg.v_gsc_page_cat cat on k.keyword = top_keyword and row_number_kw = 1  --getting keyword categories
  where search_type = 'web'
     -- device = 'DESKTOP'
     -- and keyword = 'worldremit'
     -- and country = 'usa'
    --    and   -- and date = '2021-09-25'
);
