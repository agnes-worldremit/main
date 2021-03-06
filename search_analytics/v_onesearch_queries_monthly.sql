-- combined SEO (gsc) and PPC (Google Ads) query level data

-- GSC search query data
create or replace view personal_space_db.abungsy_stg.v_onesearch_queries_monhtly as
with
 combined  as
  (select  Yrmonth, country_name, region_name, sub_region_name,device, keyword, is_tracked -- , category
         ,0 as seo_clicks, 0 as seo_impressions, 0 as seo_position_total, null as seo_position
          , ppc_impressions ,  ppc_clicks,  ppc_cost
         from personal_space_db.abungsy_stg.v_ppc_queries
         where  datediff(month, date, CURRENT_DATE()) > 0   -- exclude current month
                and datediff(day, date, CURRENT_DATE()) > 3  -- pull data up to 3 days ago only (gsc data usually is available 3 days late)
        UNION ALL
  select Yrmonth, country_name, region_name, sub_region_name,device, keyword, is_tracked -- , category
         , seo_clicks, seo_impressions, seo_position_total, seo_position_total/seo_impressions seo_position
          , 0 as ppc_impressions, 0 as ppc_clicks, 0 as ppc_cost
         from personal_space_db.abungsy_stg.v_gsc_queries
           where  datediff(month, date, CURRENT_DATE()) > 0   -- exclude current month
                and datediff(day, date, CURRENT_DATE()) > 3  -- pull data up to 3 days ago only (gsc data usually is available 3 days late)
        ),
cat as (select  keyword, category, sum(clicks_seo) clicks_seo, sum(clicks_ppc) ppc_click from personal_space_db.abungsy_stg.v_dim_query_cat group by keyword, category),
output as

(select  -- date
--, Yrmonth
  (CASE WHEN (NOT (CAST(TO_TIMESTAMP(Yrmonth, 'YYYY-MM') AS DATE) IS NULL)) THEN CAST(TO_TIMESTAMP(Yrmonth, 'YYYY-MM') AS DATE) WHEN (NOT (TRY_CAST(Yrmonth AS DATE) IS NULL)) THEN TRY_CAST(Yrmonth AS DATE) ELSE NULL END) AS "YRMONTH"

--,week_start
--, week_ending
--  ,(CASE WHEN (NOT (CAST(TO_TIMESTAMP(week_ending, 'YYYY-MM-DD') AS DATE) IS NULL)) THEN CAST(TO_TIMESTAMP(week_ending, 'YYYY-MM-DD') AS DATE) WHEN (NOT (TRY_CAST(week_ending AS DATE) IS NULL)) THEN TRY_CAST(week_ending AS DATE) ELSE NULL END) AS "WEEK_ENDING"

, country_name, region_name, sub_region_name,device, keyword, is_tracked
 --, category
   ,sum(seo_clicks) seo_clicks
   ,sum(seo_impressions) seo_impressions
   ,sum(seo_position_total) seo_position_total
   ,sum(ppc_impressions) ppc_impressions
   ,sum(ppc_clicks) ppc_clicks
   ,sum(ppc_cost) ppc_cost
   ,sum(seo_clicks+ppc_clicks) as combined_clicks
   ,sum(case when seo_position <= 10 and seo_impressions>10 and seo_impressions >= ppc_impressions  then seo_impressions end ) searches_adjusted_v1
   ,sum(case when seo_position <= 10 and seo_impressions>10 and seo_impressions >= ppc_impressions then seo_clicks end ) seo_clicks_adjusted_v1
from combined
group by Yrmonth, country_name, region_name, sub_region_name,device, keyword, is_tracked --, category
      )

select output.*
   ,case when (seo_impressions > 0 and round(seo_position_total/seo_impressions,0) < 10) and seo_impressions >= ppc_impressions then ppc_clicks end  ppc_clicks_adjusted
   ,case when (seo_impressions > 0 and round(seo_position_total/seo_impressions,0) < 10) and seo_impressions >= ppc_impressions then ppc_cost end  ppc_cost_adjusted
   ,case when (seo_impressions > 0 and round(seo_position_total/seo_impressions,0) < 10) and seo_impressions >= ppc_impressions then searches_adjusted_v1 end  searches_adjusted
   ,case when (seo_impressions > 0 and round(seo_position_total/seo_impressions,0) < 10) and seo_impressions >= ppc_impressions then seo_clicks_adjusted_v1 end  seo_clicks_adjusted
       , case when searches_adjusted  >0 then 1 else 0 end blended_data_valid_flag
  , case when seo_impressions > 0 then round(seo_position_total/seo_impressions,1) end  as  seo_position_unweighted
  , cat.category
from output
left join cat on output.keyword = cat.keyword   -- getting keyword categories
          ;



/*

-- USEFUL CODE

-- preview the data
select * from  personal_space_db.abungsy_stg.v_onesearch_queries_monhtly limit 100;

-- show all data for a country, monthly
select *
from personal_space_db.abungsy_stg.v_onesearch_queries_monhtly
where country_name = 'United Kingdom' --  and keyword = 'trustly bank transfer'
order by combined_clicks desc nulls last

*/




-- returns: category = 'generic'
select  category, sum(seo_clicks) as seo_clicks, sum(seo_impressions) from personal_space_db.abungsy_stg.v_gsc_queries  where keyword = 'trustly bank transfer' group by category

-- returns: category = 'competitor'
select  distinct category from personal_space_db.abungsy_stg.v_gsc_queries  where keyword = 'trustly bank transfer'



select distinct category from personal_space_db.abungsy_stg.v_onesearch_queries_monhtly where keyword = 'trustly bank transfer'
