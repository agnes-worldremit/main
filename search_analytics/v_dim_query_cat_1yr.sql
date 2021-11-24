-- a full and distinct list of search queries (SEO+PPC), with keyword category, last 1 year only

create or replace view personal_space_db.abungsy_stg.v_dim_query_cat_1yr as (
with
  -- full list of paid and organic keywords (paid using targeted keyworsd as we currently dont have actual paid keywords)
full_list as (select distinct keyword from  "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE" where search_type = 'web' and  datediff(year, date, CURRENT_DATE()) = 0 and datediff(day, date, CURRENT_DATE()) > 3
              UNION
              select distinct traffic_source_keyword from personal_space_db.abungsy_stg.v_ga_googleads_query where traffic_source_keyword not like '%+%' and traffic_source_campaign not like '%_DSA%'
              UNION
              select distinct query from "WR_FIVETRAN_DB"."ADWORDS_ONESEARCH_FIVETRAN_STG"."SEARCH_QUERY_PERFORMANCE_REPORT" where query not like '%+%' and   datediff(year, date, CURRENT_DATE()) = 0  and datediff(day, date, CURRENT_DATE()) > 3),

gsc_list as (select keyword, sum(clicks) clicks, sum(impressions) impressions, sum(impressions*position) as tot_position
             from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE" where search_type = 'web' and datediff(year, date, CURRENT_DATE()) = 0 group by 1),

paid_list as (select  traffic_source_keyword, sum(visits) visits_ppc, sum(trx) trx_ppc from personal_space_db.abungsy_stg.v_ga_googleads_query group by 1),

--getting categories for keywords based on paid campaigns
paid_cat  as (select keyword, campaign_category  as campaign_category1 from personal_space_db.abungsy_stg.v_ga_googleads_query_cat where campaign_category is not null ),

 --getting categories for keywords based on paid campaigns
paid_cat_2  as (select keyword, campaign_category as campaign_category2, clicks_ppc, impressions_ppc from personal_space_db.abungsy_stg.v_dim_googleads_query_cat where campaign_category is not null ),

--getting categories for keywords based on categorised landing pages
page_cat as (select top_keyword, page_category  from personal_space_db.abungsy_stg.v_gsc_page_cat where row_number_kw = 1 and page_category is not null )


select  case when len(fl.keyword) > 50 then concat(left(fl.keyword,50),'..XX') else fl.keyword end as keyword
   ,  case
         when -- (campaign_category is null and page_category is null) and
                                  fl.keyword LIKE ANY ('%worldremit%', '%world remi%','%word remit%','%world.remit%','%world remm%','%remit wor%','%workd rem%','wremit','world emit%','worldrmit%'
                                 ,'%wolrdremi%','%worldremmit%','%worl remit%','world limit','%worldrimit%','%wolrd rem%','%workdremit%','worldremot%','%world limit%','worldtemit%'
                                 ,'wordl remit%','remit login','worldremi%','worldre','remitworld','world temit%','world merit%','work remit%','word limit%','world rem%','worldmit%'
                                 , 'world remot%','wold remit%','world re','worldemit','%worldrwmit%','world rim%','worldlimit%','%worldremt%','wirld remit%','worls remi%'
                                 ,'worldrimet%','%wolremit%','wprld remit%','world renit%','world rwmit%','wirldremit%','worldrenit%','world remet%','worlddremit%'
                                 ,'wordremi%','worldremet%','worlsremit%','word rimit%','%woldermit%')   then 'brand'
         when (campaign_category1 is null and campaign_category2 is null and page_category is null)
                                 and  fl.keyword LIKE ANY ('%westernunion%','%westenun%','%westernun%','%western union%','%wester union%', '%moneygram%', '%money gram%','%kantipurremit%','%smallworld%'
                                 ,'%hello paisa%','%transfast%','ria money%','%dahabshiil%','%wave money transfer%','%orbit remit%','%banreservas%','ime %'
                                 ,'%transferwise%','%transfer wise%','%bancoppel%','poli pay%','%polipay%','%aboki fx%','%caribe exp%','%lebara money%','%instarem%','%abokif%'
                                 ,'%remitly%','%xoom%','%mukuru%','%trustly%','%geld sturen%','%polaris bank%','mobilemoney','m paisa%','poli','m-pesa%','%sendwave%')  then 'competitor'
         when (campaign_category1 is null and campaign_category2 is null and page_category is null)
                                 and  fl.keyword LIKE ANY ('%swift code%','%swift number','swiftcode','what is %','% account number','%swift bank%','canadian bank account'
                                   ,'como abrir %' ,'abrir cuenta %','%remittance meaning%','remit','world permit','bank swift','swift nummer%','swift','%bic swift%'
                                   ,'buy airtime online','devops in london','%abrir una cuenta%','how does mobile money%','%number sample%'
                                   ,'opening a bank account in %','%code swift','cuenta bancaria en %','%banco para abrir%','%scamme%','apple pay refund%','bancos en estados%'
                                   ,'%how many digit%','%transfer scam%','%track transaction%','%iban number%','% meaning','%swift-code%','%bank account for%'
                                   ,'open bank account in%','%open a bank account%','iban','%como enviar dinero%','bic code%','%open canadian bank%','how mobile %'
                                   ,'%much does it cost%','canada bank account%','%888%','can i receive %','%account number%')  then 'informational'
         when (campaign_category1 is null and campaign_category2 is null and page_category is null)
                                 and  fl.keyword LIKE ANY ('%bancolombia%','%mpesa%', '%m pesa%'' ,%gcash%','%airtel%','%alipay%','%mtn mobile%','bpi%','%bpi',' %bpi% ','%mcb%','mcb%','%mcb'
                                  ,'%cebuana%','%palawan exp%','%digicel%','%airtel money%','%metrobank%','%balikbayan%','%diamond%bank%','%yonna fore%','%yonna fx%','%ntc%','ntc%','%ntc'
                                  ,'%zaawadi%','%sofort%','%klarna%','%express union%','%intel express%','%mtn%','alipay%','ali pay','ali-pay','jazz%','%etisalat%')  then 'provider'
         when (campaign_category1 is null and campaign_category2 is null and page_category is null)
                                 and  fl.keyword LIKE ANY ('sending money','%send money to %','money transfer organization%','foreign money transfer to%','transfer money to%'
                                  ,'%send money online%','send money%','transfer money%','money transfer to%','%money transfer online%','send money col%'
                                  ,'%international money transfer%','remit money transfer','%online money transfer%','%money remit%','world money transfer%'
                                  ,'%mobile money transfer%','transfert d%','%enviar dinero%','%sending money to%','remit money%','transfert argent%'
                                  ,'remit to %','%remit transfer%','money transfer %','how to send money%','envoyer de l%','world transfer','best way to transfer money%'
                                  ,'how to receive money from%','remittance money transfer%','online remittance%','%send mobile money%','bank remittance%','portefeuille mobile'
                                  ,'bvn money%','%bank to bank transfer%','%money transfer%','worldwide remit%','remittance to %','%envoyer de l argent%'
                                  ,'cash pick up%','how to receive dollars%','money to the %','%moneytrans%tun%','%cash pick up%','%bank transfer%') then 'generic'
          when (campaign_category1 is null and campaign_category2 is null and page_category is null)
                                  and  fl.keyword LIKE ANY ('%heroes%','%hispanic figures%','%spanish heroes%','%hispanic hero%','hispanic people%','hispanic historical%','%living in %'
                                   ,'cost of living%','remit send money%','famous nigerian%','nigerian singer%','%influential%','%retiring%','%educational%'
                                   ,'%retire%','%hispanic lead%') then 'blog'
          when (campaign_category1 is not null and visits_ppc >= pc2.clicks_ppc)  then campaign_category1   -- paid campaign category from the Google Analytics data set
          when (campaign_category2 is not null and pc2.clicks_ppc >= visits_ppc)  then campaign_category2   -- paid campaign category from the Google Ads data set
          when page_category is not null then page_category           -- category from the SEO landing page categories
          when campaign_category1 is not null then campaign_category1
          when campaign_category2 is not null then campaign_category2
          end as category
  , to_number(visits_ppc) visits_ppc
  , to_number(pc2.clicks_ppc) clicks_ppc
  , to_number(pc2.impressions_ppc) impressions_ppc
  , to_number(trx_ppc) trx_ppc
  , to_number(clicks) as clicks_seo
  , to_number(impressions) as impressions_seo
  , to_number(tot_position) tot_position
  , tot_position/impressions position_seo
  , round(round(tot_position/impressions/5,1)*5,1) position_seo_round
  , round(tot_position/impressions,0) position_seo_round_whole
  , to_number(clicks)+to_number(pc2.clicks_ppc) as total_clicks
  , case when  to_number(pc2.impressions_ppc) > to_number(impressions) then pc2.impressions_ppc
         when  round(tot_position/impressions,0) between 1 and 9 and to_number(impressions) >0 then to_number(impressions) end as searches
  , NTILE (10)OVER (order by impressions_seo asc )   size_group    -- score keywords from 1 to 10, based on total volumes of clicks*impressions
  , NTILE (10)OVER (partition by category   order by  impressions_seo asc )   size_group_cat -- score keywords at a category level, from 1 to 10, based on total volumes of clicks*impressions
  , NTILE (10)OVER (order by impressions_ppc asc )   size_group_ppc    -- score keywords from 1 to 10, based on total volumes of clicks*impressions
  , NTILE (10)OVER (partition by category   order by  impressions_ppc asc )   size_group_cat_ppc -- score keywords at a category level, from 1 to 10, based on total volumes of clicks*impressions
from full_list fl
left join gsc_list on fl.keyword  = gsc_list.keyword
left join paid_list on fl.keyword  = paid_list.traffic_source_keyword
left join paid_cat pc on fl.keyword  = pc.keyword
left join paid_cat_2 pc2 on fl.keyword  = pc2.keyword
left join page_cat oc on fl.keyword  = oc.top_keyword
where to_number(clicks)+to_number(pc2.clicks_ppc) > 0 or to_number(pc2.impressions_ppc) >0 or impressions >0);


/*

-- USEFUL CODE

-- combined data for a query
select * from personal_space_db.abungsy_stg.v_dim_query_cat_1yr where keyword =  'remittance'

select * from personal_space_db.abungsy_stg.v_dim_query_cat_1yr where clicks_ppc is null and clicks_seo is null limit 100

select sum(clicks_ppc) from  personal_space_db.abungsy_stg.v_dim_query_cat_1yr  where keyword = 'worklremit'


select * from personal_space_db.abungsy_stg.v_dim_query_cat_1yr where size_group = 10 limit 100

-- see keywords in gsc data
 select distinct keyword from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_SITE" where search_type = 'web' and keyword = 'cardless withdrawal standard bank'

-- see keywords in categorised Google Ads data
 select * from personal_space_db.abungsy_stg.v_dim_googleads_query_cat   where keyword = 'cardless withdrawal standard bank'


-- view long keywords
select * from personal_space_db.abungsy_stg.v_dim_query_cat_1yr
where len(keyword) > 51
limit 100

-- count distinct keywords
select count(distinct keyword) from personal_space_db.abungsy_stg.v_dim_query_cat_1yr ; 1,650,284

-- count distinct keywords by size group
select size_group,sum(clicks_seo) clicks_seo, sum(impressions_seo) impressions_seo, sum(clicks_ppc+clicks_seo) as clicks, sum(impressions_seo+impressions_ppc) as impressions, count(distinct keyword) from personal_space_db.abungsy_stg.v_dim_query_cat group by 1 ;


-- check availability of categories 0.023172 (based on SEO numbers)
select sum(case when category is null then clicks_seo end)/sum(clicks_seo) seo_clicks_missing
   , sum(case when category is null then clicks_ppc end)/sum(clicks_ppc) ppc_clicks_missing
  , count(distinct keyword) count_all_kw, count(distinct case when category is not null then keyword end) count_kw_categorised   -- , sum(impressions) impressions
from personal_space_db.abungsy_stg.v_dim_query_cat

-- see summary by kw category
select category, sum(clicks_seo) clicks, sum(impressions_seo) impressions, count(distinct keyword) kw, sum(tot_position)/sum(impressions_seo) as position,sum(clicks_ppc) clicks_ppc,sum(impressions_ppc) impressions_ppc
from personal_space_db.abungsy_stg.v_dim_query_cat
group by 1;

-- see biggest missing keywords
select keyword, clicks_seo from personal_space_db.abungsy_stg.v_dim_query_cat  where category is null order by clicks_seo desc;


-- view  paid categories by keyword
select * from personal_space_db.abungsy_stg.v_ga_googleads_query_cat where keyword like 'pola%' order by visits_ppc desc  limit 100

-- view  paid categories by category
select * from personal_space_db.abungsy_stg.v_ga_googleads_query_cat where campaign_category = 'competitor' order by visits_ppc desc  limit 100

*/
