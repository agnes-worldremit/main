
-- categorise seo landing pages, using in first instance PPC based categories, then using rules for where PPC cat is unavailable
create or replace view personal_space_db.abungsy_stg.v_gsc_page_cat as
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
  left join personal_space_db.abungsy_stg.v_ga_googleads_query_cat paid_cat on g.keyword = paid_cat.keyword
  where row_number = 1)

select page, top_keyword
  , case
      --  when (top_keyword_paid_category is null) and  (top_keyword  like '%worldremit%' OR top_keyword like '%world remit%') then 'brand'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%worldremit%', '%world remit%')  then 'brand'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%western union%','%wester union%', '%moneygram%', '%money gram%','%kantipurremit%','%transferwise%'
                                                                             ,'%remitly%','%xoom%','%mukuru%','%trustly%','%geld sturen%')  then 'competitor'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%swift code%')  then 'informational'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%bancolombia%','%mpesa%', '%m pesa%'' ,%gcash%','%airtel%','%alipay%','%mtn mobile%'
                                                                             ,'%cebuana%','%palawan exp%','%digicel%','%airtel money%','%metrobank%','%balikbayan%'
                                                                             ,'%zaawadi%','%sofort%','%klarna%','%express union%','%intel express%')  then 'provider'
         when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('send money to %','money transfer organization%','foreign money transfer to%','transfer money to%') then 'generic'
         when page like '%/stories/%' then 'blog'

      else top_keyword_paid_category end as page_category
  , clicks, impressions, tot_position
from paid_cat;


/*

 -- USEFUL CODE

-- check availability of categories 0.008619610331
select sum(case when page_category is null then clicks end)/sum(clicks) clicks_missing
  , count(distinct top_keyword) count_all_kw, count(distinct case when page_category is not null then top_keyword end) count_kw_categorised   -- , sum(impressions) impressions
from personal_space_db.abungsy_stg.v_gsc_page_cat


-- see summary by page category
select page_category, sum(clicks) clicks, sum(impressions) impressions, count(distinct top_keyword) kw, sum(tot_position)/sum(impressions) as position
from personal_space_db.abungsy_stg.v_gsc_page_cat
group by 1;


-- see biggest missing keywords
select top_keyword, clicks from personal_space_db.abungsy_stg.v_gsc_page_cat where page_category is null order by clicks desc;

-- view  paid categories by category
select * from personal_space_db.abungsy_stg.v_ga_googleads_query_cat where campaign_category = 'provider' order by visits_ppc desc  limit 100

-- view  paid categories by keyword
select * from personal_space_db.abungsy_stg.v_ga_googleads_query_cat where keyword like '%geld sturen%' order by visits_ppc desc  limit 100


*/
