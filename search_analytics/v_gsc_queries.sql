-- keyword level SEO metrics from Google Search Console, with keyword categories attached

-- GSC search query data
create or replace view personal_space_db.abungsy_stg.v_gsc_queries as
with
gsc_queries as (select kr.*, case when len(keyword) > 50 then concat(left(keyword,50),'..XX') else keyword end as keyword_short from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE" kr
                where search_type = 'web' )
-- markets as  (select country from  (select country, sum(clicks) clicks_total from gsc_queries group by 1 order by  clicks_total desc) limit 25)


select
--  k.date
  to_char(dateadd(day,6,iso_week_start_date),'YYYY-MM-DD') as date -- week ending instead of date (for tableau performance)
, to_char(k.date,'YYYY-MM') YrMonth
, to_char(iso_week_start_date,'YYYY-MM-DD') week_start
, to_char(dateadd(day,6,iso_week_start_date),'YYYY-MM-DD') week_ending
-- , k.country
 , case when  k.country  in ('gbr','usa','aus','can','gha','nga','phl','deu','fra','zaf','nld','swe','nzl','ken','ind','nor','col','bel','esp','pak','zwe','irl','mex','uga','ita'
                                       ,'mys','dnk','che','fin')
                      then geo.country_name else  'Other'end as country_name
--, geo.country_name
, region_name
, sub_region_name
, k.device
--, k.keyword
, case when cat.category is null then 'XX_other'
       when (total_clicks >= 10) then  replace(k.keyword_short , '-', ' ') else   CONCAT(cat.category,'-','tail') end as keyword
, case when t.keyword is null then 'no' else 'yes' end as is_tracked
, COALESCE(cat.category,'other') as category
, sum(k.clicks) as seo_clicks
, sum(k.impressions) as seo_impressions
, sum(k.impressions*k.position) as seo_position_total   -- to calculate weighted position, so can be grouped in different ways
from gsc_queries k
left join (select distinct calendar_date, iso_week_start_date from  "WR_DWH_DB"."DIMENSIONS"."D_CALENDAR") on k.date = calendar_date
left join (select distinct lower(country_iso3_code) country_code, country_name, region_name, sub_region_name  from "WR_DWH_DB"."DIMENSIONS"."D_GEOGRAPHY" where is_active = TRUE) geo on k.country = geo.country_code
left join personal_space_db.abungsy_stg.v_dim_query_cat cat on k.keyword = cat.keyword   -- getting keyword categories
left join personal_space_db.abungsy_stg.v_seo_tracked_keywords t on k.keyword = t.keyword and geo.country_name = t.country
/*-- keyword size
left join (select k.keyword, percent_rank() over (partition by category order by  impressions) as percent_rank_imp
          ,  percent_rank() over (partition by category order by  clicks) as percent_rank_click
          -- , sum(total_clicks) over (order by category desc rows between unbounded preceding and current row) as percent_rank_click
         --  , Sum(total_clicks) OVER( partition BY category ORDER BY total_clicks desc rows UNBOUNDED PRECEDING ) "Cumulative Sum"  -- as percent_rank_click
         -- ,  CUME_DIST() OVER ( PARTITION BY category  ORDER BY  total_clicks asc ) as CUME_DIST
          ,  percent_rank() over (partition by category order by total_clicks ) as percent_rank
          from (select keyword, sum(clicks) clicks, sum(impressions) impressions  from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE"
          where  search_type = 'web' group by 1) k
          left join personal_space_db.abungsy_stg.v_dim_query_cat cat on k.keyword = cat.keyword) size on k.keyword_short = size.keyword   */
where search_type = 'web'
     -- device = 'DESKTOP'
     -- and keyword = 'worldremit'
     -- and country = 'usa'
        and   date >= '2020-07-01'  --first full month of data
group by to_char(dateadd(day,6,iso_week_start_date),'YYYY-MM-DD')
, to_char(k.date,'YYYY-MM')
, to_char(iso_week_start_date,'YYYY-MM-DD')
, to_char(dateadd(day,6,iso_week_start_date),'YYYY-MM-DD')
-- , k.country
 , case when  k.country  in ('gbr','usa','aus','can','gha','nga','phl','deu','fra','zaf','nld','swe','nzl','ken','ind','nor','col','bel','esp','pak','zwe','irl','mex','uga','ita'
                                       ,'mys','dnk','che','fin')
                      then geo.country_name else  'Other'end
--, geo.country_name
, region_name
, sub_region_name
, k.device
--, k.keyword
, case when cat.category is null then 'XX_other'
       when (total_clicks >= 10) then  replace(k.keyword_short , '-', ' ') else   CONCAT(cat.category,'-','tail') end
, case when t.keyword is null then 'no' else 'yes' end
, COALESCE(cat.category,'other');



-- USEFUL CODE

-- count words
-- select  count(1) from personal_space_db.abungsy_stg.v_gsc_queries   -- 6,764,723

-- show head
-- select * from personal_space_db.abungsy_stg.v_gsc_queries limit 100
where keyword like  '%-%' and keyword not like  '%tail' limit 100

-- aggregate
-- select  category, sum(seo_impressions) seo_impressions, sum(seo_clicks) seo_clicks, count(distinct keyword) kw from personal_space_db.abungsy_stg.v_gsc_queries group by category order by  2  desc

/*
-- QA GSC output for a single query
select sum(seo_clicks), sum(seo_impressions), sum(seo_position_total)/sum(seo_impressions) seo_pos
from personal_space_db.abungsy_stg.v_gsc_queries
where   country_name = 'United Kingdom' and device = 'MOBILE' and keyword = 'worldremit' and yrmonth = '2021-10'

--should be for 2021-10: 12,403 Clicks, 27,659 Impressions, 1 Position
*/

/*
-- QA raw data
-- https://search.google.com/search-console/performance/search-analytics?resource_id=sc-domain%3Aworldremit.com&start_date=20210901&end_date=20210930&query=!worldremit&country=usa&device=DESKTOP
select sum(impressions), sum(clicks), sum(impressions*position)/sum(impressions) pos
from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE" where device = 'DESKTOP' and country = 'usa' and keyword = 'worldremit' and (date between  '2021-09-01' and '2021-09-30')
 and search_type = 'web'

 select distinct lower(country_iso3_code) country_code, country_name, region_name, sub_region_name  from "WR_DWH_DB"."DIMENSIONS"."D_GEOGRAPHY" where is_active = TRUE and lower(country_iso3_code) = 'usa'



 select * from personal_space_db.abungsy_stg.v_gsc_queries limit 100

 select count(1) from  personal_space_db.abungsy_stg.v_gsc_queries
*/
