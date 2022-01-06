-- combined SEO (gsc) and PPC (Google Ads) query level data, monhtly, with only volume metrics shown, to be used for Venn diagram (overlap between ppc and seo)

-- GSC search query data
create or replace view personal_space_db.abungsy_stg.v_onesearch_queries_overlap as
with
 combined  as
  (select  Yrmonth, country_name, region_name, sub_region_name,device, keyword -- , category
         ,0 as seo_clicks, 0 as seo_impressions, 0 as seo_position_total, null as seo_position
          , ppc_impressions ,  ppc_clicks,  ppc_cost, 'ppc' as search_channel
         from personal_space_db.abungsy_stg.v_ppc_queries
         where  datediff(month, date, CURRENT_DATE()) > 0   -- exclude current month
                and datediff(day, date, CURRENT_DATE()) > 3  -- pull data up to 3 days ago only (gsc data usually is available 3 days late)
        UNION ALL
  select Yrmonth, country_name, region_name, sub_region_name,device, keyword -- , category
         , seo_clicks, seo_impressions, seo_position_total, seo_position_total/seo_impressions seo_position
          , 0 as ppc_impressions, 0 as ppc_clicks, 0 as ppc_cost, 'seo' as search_channel
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

, search_channel, country_name, region_name, sub_region_name, keyword
 --, category
   ,sum(seo_clicks) seo_clicks
   ,sum(seo_impressions) seo_impressions
   ,sum(seo_position_total) seo_position_total
   ,sum(ppc_impressions) ppc_impressions
   ,sum(ppc_clicks) ppc_clicks
   ,sum(seo_clicks+ppc_clicks) as combined_clicks
from combined
group by Yrmonth, search_channel, country_name, region_name, sub_region_name, keyword --, category
      )

select output.*
  , cat.category
from output

left join cat on output.keyword = cat.keyword   -- getting keyword categories
where yrmonth in ('2021-09-01', '2021-10-01','2021-11-01')
          ;



/*

-- USEFUL CODE

-- preview the data
select * from  personal_space_db.abungsy_stg.v_onesearch_queries_overlap limit 100;



select count(1) from personal_space_db.abungsy_stg.v_onesearch_queries_overlap

-- show all data for a country, monthly
select *
from personal_space_db.abungsy_stg.v_onesearch_queries_overlap
where country_name = 'United Kingdom'   and keyword = 'trustly bank transfer'
order by combined_clicks desc nulls last

*/
