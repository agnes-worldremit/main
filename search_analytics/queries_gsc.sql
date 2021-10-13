-- keyword data
select *
-- sum(clicks) clicks, sum(impressions)  impressions
from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE"
where  device = 'MOBILE' and keyword = 'worldremit' and country = 'usa' and search_type = 'web' -- and date = '2021-09-25'
order by clicks desc


-- page data
select *
from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."PAGE_REPORT"
where page = 'https://www.worldremit.com/en/us' and date = '2021-09-26' and device = 'MOBILE' and search_type = 'web' and country = 'usa'


-- page & keyword data
select *
from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_PAGE_REPORT"
where page = 'https://www.worldremit.com/en/us' and date = '2021-09-26' and device = 'MOBILE' and search_type = 'web' and country = 'usa'


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
, device
, keyword
, clicks as seo_clicks
, impressions as seo_impressions
, impressions*position as seo_position_total   -- to calculate weighted position, so can be grouped in different ways
from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE" k
left join (select distinct calendar_date, iso_week_start_date from  "WR_DWH_DB"."DIMENSIONS"."D_CALENDAR") on k.date = calendar_date
left join (select distinct lower(country_iso3_code) country_code, country_name, region_name, sub_region_name  from "WR_DWH_DB"."DIMENSIONS"."D_GEOGRAPHY" where is_active = TRUE) geo on k.country = geo.country_code
where  device = 'DESKTOP'
     -- and keyword = 'worldremit'
     -- and country = 'usa'
     and search_type = 'web'  -- and date = '2021-09-25'
)


-- categorise seo landing pages
create or replace view personal_space_db.abungsy_stg.v_gsc_page_category as
with

base as (
  select keyword, page, sum(clicks) clicks, sum(impressions) impressions, sum(impressions*position) tot_position
  from  "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_PAGE_REPORT"
  where search_type = 'web'
  group by 1,2),

grouped  as (select b.*, row_number() over (partition by page order by clicks desc) as row_number
   from base b ),

paid_cat as ( select page, g.keyword top_keyword,paid_cat.campaign_category as top_keyword_paid_category, clicks, impressions, tot_position
  from grouped g
  left join personal_space_db.abungsy_stg.v_ga_googleads_query_category paid_cat on g.keyword = paid_cat.keyword
  where row_number = 1)

select page, top_keyword
  , case
      --  when (top_keyword_paid_category is null) and  (top_keyword  like '%worldremit%' OR top_keyword like '%world remit%') then 'brand'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%worldremit%', '%world remit%')  then 'brand'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%western union%','%wester union%', '%moneygram%', '%money gram%','%kantipurremit%','%transferwise%'
                                                                             ,'%remitly%','%xoom%','%mukuru%','%trustly%')  then 'competitor'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%swift code%')  then 'informational'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%bancolombia%','%mpesa%', '%m pesa%'' ,%gcash%','%airtel%','%alipay%','%mtn mobile%'
                                                                             ,'%cebuana%','%palawan exp%','%digicel%','%airtel money%','%metrobank%','%balikbayan%'
                                                                             ,'%zaawadi%','%sofort%','%klarna%','%express union%','%intel express%')  then 'provider'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('send money to %','money transfer organization%','foreign money transfer to%') then 'generic'
         when page like '%/stories/%' then 'blog'

      else top_keyword_paid_category end as page_category 
  , clicks, impressions, tot_position
from paid_cat


-- check availability of categories 0.008814398545
select sum(case when page_category is null then clicks end)/sum(clicks) clicks_missing
  , count(distinct top_keyword) count_all_kw, count(distinct case when page_category is not null then top_keyword end) count_kw_categorised   -- , sum(impressions) impressions
from personal_space_db.abungsy_stg.v_gsc_page_category


-- see summary by category
select page_category, sum(clicks) clicks, sum(impressions) impressions, count(distinct top_keyword) kw, sum(tot_position)/sum(impressions) as position
from personal_space_db.abungsy_stg.v_gsc_page_category
group by 1


-- see biggest missing keywords
select top_keyword, clicks from personal_space_db.abungsy_stg.v_gsc_page_category where page_category is null order by clicks desc

-- view  paid categories by category
select * from personal_space_db.abungsy_stg.v_ga_googleads_query_category where campaign_category = 'provider' order by visits desc  limit 100

-- view  paid categories by keyword
select * from personal_space_db.abungsy_stg.v_ga_googleads_query_category where keyword like '%poli p%' order by visits desc  limit 100
