-- list of ppc queries (as typed by the user), with top category (based on Campaig names, using Search Query report from Google Ads)
create or replace view personal_space_db.abungsy_stg.v_dim_googleads_query_cat as
with

base as (

select lower(query) keyword,
case when lower(campaign_name) like '%competitor%' then 'competitor'
     when lower(campaign_name) like '%_tm_%' then 'brand'
     when lower(campaign_name) like '%_generic_%' then 'generic'
     when lower(campaign_name) like '%_provider_%' then 'provider'
     else 'other' end as campaign_category, sum(impressions) impressions_ppc, sum(clicks) clicks_ppc, sum(cost) cost_ppc
from  "WR_FIVETRAN_DB"."ADWORDS_ONESEARCH_FIVETRAN_STG"."SEARCH_QUERY_PERFORMANCE_REPORT"
where  campaign_name not like '%_DSA%'
group by 1,2),

grouped  as (select b.*, row_number() over (partition by keyword order by clicks_ppc desc) as row_number
from base b
where keyword not like '%+%' )

select keyword, campaign_category, clicks_ppc, cost_ppc, impressions_ppc from grouped where row_number = 1;


/*
-- USEFUL CODE

-- preview data
select *  from personal_space_db.abungsy_stg.v_dim_googleads_query_cat limit 100;

-- check availability of categories 0.0394566005
select sum(case when campaign_category is null then clicks_ppc end)/sum(clicks_ppc) clicks_missing
  , count(distinct keyword) count_all_kw, count(distinct case when campaign_category is not null then keyword end) count_kw_categorised
from  personal_space_db.abungsy_stg.v_dim_googleads_query_cat;

-- see summary by kw category
select campaign_category, sum(clicks_ppc) clicks, sum(impressions_ppc) impressions, count(distinct keyword) kw
from personal_space_db.abungsy_stg.v_dim_googleads_query_cat
group by 1;

-- see inconsistent categories
select *
from personal_space_db.abungsy_stg.v_dim_googleads_query_cat ads
join personal_space_db.abungsy_stg.v_ga_googleads_query_cat ga on ads.keyword = ga.keyword
where ads.campaign_category is not null and  ga.campaign_category is not null and ads.campaign_category <>  ga.campaign_category
limit 100

*/
