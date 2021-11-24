-- keyword level SEO metrics from Google Search Console, with keyword categories attached

-- GSC search query data
create or replace view personal_space_db.abungsy_stg.v_ppc_queries as
with
ppc_queries as (select kr.date
                ,  case when device = 'Computers' then 'DESKTOP' when device = 'Mobile devices with full browsers' then 'MOBILE' when device = 'Tablets with full browsers' then 'TABLET' end as DEVICE
                ,  case when len(query) > 50 then concat(left(query,50),'..XX') else query end as keyword_short
                , kr.query as keyword
                , lower(kr.campaign_name) as campaign
                , c.country
                , clicks
                , impressions
                , cost
               from  "WR_FIVETRAN_DB"."ADWORDS_ONESEARCH_FIVETRAN_STG"."SEARCH_QUERY_PERFORMANCE_REPORT"  kr
               left join personal_space_db.abungsy_stg.v_dim_googleads_countries c on lower(kr.campaign_name) = c.campaign
              --  limit 100
                )
select
--  k.date
  to_char(dateadd(day,6,iso_week_start_date),'YYYY-MM-DD') as date -- week ending instead of date (for tableau performance)
, to_char(k.date,'YYYY-MM') YrMonth
, to_char(iso_week_start_date,'YYYY-MM-DD') week_start
, to_char(dateadd(day,6,iso_week_start_date),'YYYY-MM-DD') week_ending
-- , k.country
 , case when  lower(country_code)  in ('gbr','usa','aus','can','gha','nga','phl','deu','fra','zaf','nld','swe','nzl','ken','ind','nor','col','bel','esp','pak','zwe','irl','mex','uga','ita'
                                       ,'mys','dnk','che','fin')
                      then geo.country_name else  'Other'end as country_name
--, geo.country_name
, region_name
, sub_region_name
, k.device
--, k.keyword
, case when cat.category is null then 'XX_Uncategorized'
       when (percent_rank_imp >= 0.75 OR percent_rank_click >= 0.50) then  k.keyword_short else   CONCAT(cat.category,'-','tail') end as keyword
, case when t.keyword is null then 'no' else 'yes' end as is_tracked
, COALESCE(cat.category,'Uncategorized') as category
, sum(k.clicks) as ppc_clicks
, sum(k.impressions) as ppc_impressions
, sum(k.cost) as ppc_cost
from ppc_queries k
left join (select distinct calendar_date, iso_week_start_date from  "WR_DWH_DB"."DIMENSIONS"."D_CALENDAR") on k.date = calendar_date
left join (select distinct lower(country_iso3_code) country_code, country_name, region_name, sub_region_name  from "WR_DWH_DB"."DIMENSIONS"."D_GEOGRAPHY" where is_active = TRUE) geo on k.country = geo.country_name
left join personal_space_db.abungsy_stg.v_dim_query_cat cat on k.keyword = cat.keyword   -- getting keyword categories
left join personal_space_db.abungsy_stg.v_seo_tracked_keywords t on k.keyword = t.keyword and k.country = t.country
-- keyword size
left join (select k.keyword, percent_rank() over (partition by category order by  impressions) as percent_rank_imp,  percent_rank() over (partition by category order by  clicks) as percent_rank_click
          from (select keyword, sum(clicks) clicks, sum(impressions) impressions  from ppc_queries
          group by 1) k
          left join personal_space_db.abungsy_stg.v_dim_query_cat cat on k.keyword = cat.keyword) size on k.keyword_short = size.keyword
where --search_type = 'web'
     -- device = 'DESKTOP'
     -- and keyword = 'worldremit'
     -- and country = 'usa'
           date >= '2020-07-01'  --first full month of data
group by 1,2,3,4,5,6,7,8,9,10,11
;


-- USEFUL CODE

-- count rows and queries
-- select  count(1) norows, count(distinct keyword) kw from personal_space_db.abungsy_stg.v_ppc_queries   -- 7,294,532, 325,312

-- show head
-- select * from personal_space_db.abungsy_stg.v_ppc_queries limit 100

-- aggregate
-- select country_name, category, sum(ppc_impressions) ppc_impressions, sum(ppc_clicks) ppc_clicks,sum(ppc_cost) ppc_cost,count(distinct keyword) kw from personal_space_db.abungsy_stg.v_ppc_queries group by 1,2

/*
-- QA PPC output for a single query
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
*/
