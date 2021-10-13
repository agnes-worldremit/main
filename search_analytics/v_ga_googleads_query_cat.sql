-- list of targeted ppc keywords, with top category (based on Campaig names)
-- this is then used to categorise also SEO landing pages, and effectively also SEO queries
create or replace view personal_space_db.abungsy_stg.v_ga_googleads_query_cat as
with

base as (

select lower(traffic_source_keyword) keyword,
case when lower(traffic_source_campaign) like '%competitor%' then 'competitor'
     when lower(traffic_source_campaign) like '%_tm_%' then 'brand'
     when lower(traffic_source_campaign) like '%_generic_%' then 'generic'
     when lower(traffic_source_campaign) like '%_provider_%' then 'provider'
     when  traffic_source_campaign like '%_DSA%' then 'dsa'
     else 'other' end as campaign_category, sum(visits) visits_ppc, sum(trx) trx_ppc
from personal_space_db.abungsy_stg.v_ga_googleads_query
   -- where traffic_source_keyword = 'money transfers'
group by 1,2),

grouped  as (select b.*, row_number() over (partition by keyword order by visits_ppc desc) as row_number
from base b
where keyword not like '%+%' )

select keyword, campaign_category, visits_ppc, trx_ppc from grouped where row_number = 1;
