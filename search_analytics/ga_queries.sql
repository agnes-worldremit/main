
-- Google Ads targetted keywords from Google Analytics (this is to be used for clategorising search terms)
create or replace view personal_space_db.abungsy_stg.v_ga_googleads_queries as
(select  -- date
device_device_category
, traffic_source_keyword    -- = 'Dynamic Search Ads' (which overall is 3% of all PPC Visits)
, traffic_source_adwords_click_info_criteria_parameters
, traffic_source_ad_content
, traffic_source_campaign
, traffic_source_adwords_click_info_ad_network_type
, geo_network_continent
, geo_network_sub_continent
, geo_network_country
, sum(total_visits) visits
, sum(total_transactions) trx
from WR_FIVETRAN_DB.GA360_WEB_FIVETRAN_STG.GA_SESSION
where channel_grouping = 'Paid Search' and traffic_source_source = 'google' and traffic_source_campaign is not null and traffic_source_adwords_click_info_ad_network_type <> 'NULL'
group by 1,2,3,4,5,6,7,8,9 )


-- list of targeted keywords, with top category (based on Campaig names)
-- gives 21.1k categorised keywords (that is excluding of the ones including +)
create or replace view personal_space_db.abungsy_stg.v_ga_googleads_query_category as
with

base as (

select lower(traffic_source_keyword) keyword,
case when lower(traffic_source_campaign) like '%competitor%' then 'competitor'
     when lower(traffic_source_campaign) like '%_tm_%' then 'brand'
     when lower(traffic_source_campaign) like '%_generic_%' then 'generic'
     when lower(traffic_source_campaign) like '%_provider_%' then 'provider'
     when  traffic_source_campaign like '%_DSA%' then 'dsa'
     else 'other' end as campaign_category, sum(visits) visits, sum(trx) trx
from personal_space_db.abungsy_stg.v_ga_googleads_queries
   -- where traffic_source_keyword = 'money transfers'
group by 1,2),

grouped  as (select b.*, row_number() over (partition by keyword order by visits desc) as row_number
from base b
where keyword not like '%+%' )

select keyword, campaign_category, visits, trx from grouped where row_number = 1
