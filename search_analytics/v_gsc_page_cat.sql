
-- categorise seo landing pages, using in first instance PPC based categories, then using rules for where PPC cat is unavailable
create or replace view personal_space_db.abungsy_stg.v_gsc_page_cat as
with

base as (
 select keyword, case when page like '%/faq/%' then '/faq/'
                      when page like '%/stories/%' then '/stories/'
                      when page like '%/exchange-rates/%' then '/exchange-rates/' else page end as page
    , sum(clicks) clicks, sum(impressions) impressions, sum(impressions*position) tot_position
 from  "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_PAGE_REPORT"
 where search_type = 'web' --  and keyword in ('send money from nicaragua to usa')
 group by keyword, case when page like '%/faq/%' then '/faq/'
                      when page like '%/stories/%' then '/stories/'
                      when page like '%/exchange-rates/%' then '/exchange-rates/' else page end ),

grouped  as (select b.*, row_number() over (partition by page order by clicks desc) as row_number
  from base b ),

paid_cat as ( select page, g.keyword top_keyword,paid_cat.campaign_category as top_keyword_paid_category, clicks, impressions, tot_position
 from grouped g
 left join  personal_space_db.abungsy_stg.v_ga_googleads_query_cat
            -- personal_space_db.abungsy_stg.v_googleads_query_cat
                paid_cat on g.keyword = paid_cat.keyword and row_number = 1
 )

select page, top_keyword
 , case
     --  when (top_keyword_paid_category is null) and  (top_keyword  like '%worldremit%' OR top_keyword like '%world remit%') then 'brand'
        when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%worldremit%', '%world remi%','%word remit%','%world.remit%','%world remm%','%remit wor%','%workd rem%','wremit','world emit%','worldrmit%'
                     ,'%wolrdremi%','%worldremmit%','%worl remit%','world limit','%worldrimit%','%wolrd rem%','%workdremit%','worldremot%','%world limit%','worldtemit%'
                     ,'wordl remit%','remit login','worldremi%','worldre','remitworld','world temit%','world merit%','work remit%','word limit%','world rem%','worldmit%'
                     , 'world remot%','wold remit%','world re','worldemit','%worldrwmit%','world rim%','worldlimit%','%worldremt%','wirld remit%','worls remi%','world permit','world permit'
                     ,'worldrimet%','%wolremit%','wprld remit%','world renit%','world rwmit%','wirldremit%','worldrenit%','world remet%','worlddremit%','correspondent portal%'
                     ,'wordremi%','worldremet%','worlsremit%','word rimit%','%woldermit%','%woldremit%','%worlremit%','%wordlremit%','%wordmit%','%ворлд ремит%','%workremit%')  then 'brand'

   when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%western union%','%wester union%', '%moneygram%', '%money gram%','%kantipurremit%','%transferwise%'
                                          ,'%remitly%','%xoom%','%mukuru%','%trustly%','%geld sturen%')  then 'competitor'

   when (top_keyword_paid_category is null) and top_keyword LIKE ANY  ('%westernunion%','%westenun%','%westernun%','%western union%','%wester union%', '%moneygram%', '%money gram%','%kantipurremit%','%smallworld%'
           ,'%hello paisa%','%transfast%','ria money%','%dahabshiil%','%wave money transfer%','%orbit remit%','%banreservas%','ime %'
           ,'%transferwise%','%transfer wise%','%bancoppel%','poli pay%','%polipay%','%aboki fx%','%caribe exp%','%lebara money%','%instarem%','%abokif%'
           ,'%remitly%','%xoom%','%mukuru%','%trustly%','%geld sturen%','%polaris bank%','mobilemoney','m paisa%','poli','m-pesa%','%sendwave%','%m pesa%') then 'competitor'

   when top_keyword LIKE ANY ('%jazz%cash%','%mlhu%lier%','%polaris%','%bancolombia%','%mpesa%', '%m pesa%'' ,%gcash%','%airtel%','%alipay%','%mtn mobile%','bpi%','%bpi',' %bpi% ','%mcb%','mcb%','%mcb'
                   ,'%cebuana%','%palawan exp%','%digicel%','%airtel money%','%metrobank%','%balikbayan%','%diamond%bank%','%yonna fore%','%yonna fx%'
                   ,'%ntc%','ntc%','%ntc','%palawan pawn%','%tele%zaad%','%zaad soma%','%cooperative bank%'
                   ,'%zaawadi%','%sofort%','%klarna%','%express union%','%intel express%','%mtn%','alipay%','ali pay','ali-pay','jazz%','%etisalat%' ,'%commercial bank%','%bank al habib%'
                   ,'glo %','% glo %','glo','%ecocash%','%eco cash%','%zaad %','% zaad','zaad','%banco de reserva%','%lafise%','%bancentro%','%daviplata%','%unitransfer%'
                   ,'%standard bank%','%hsbc%','%natwest%','%icbc%','%bank of china%') then 'provider'

   when page like '%/stories/%' then 'blog'

   when page like any ('%/faq/%','%/gma') or page like '%/exchange-rates/%' or top_keyword in ('international currency exchange','best bank in nepal','how to open a bank account in nigeria'
         ,'uae exchange uganda','nigeria','benin money','czech money','deposit','money on','money germany','australian money exchange'
         ,'nigeria banks','dollars account in nigeria','world first bank account','nigeria bank','money brazil','cambodia money'
         ,'south africa money','globe','viva','sarah zaad','u s bank','pakistan pakistan','remit','contact us','dollar account in nigeria')  then 'informational'

  when top_keyword like any ('%exchange rate%','usd to ngn%','%usd to naira','%currency rate'
                              ,'which bank in jamaica use zelle','%definicion%','%definition%','%meaning%','% def','%airtime%'
                              , '%currency to naira%' ,'can %use zelle%','%can%venmo in%','cash exchange%me','%google transfer%'
                              , '%how much%zelle rate%' ,'what is a dollar account%','to nigeria currency','usa to nigeria','euro to cedis','prague money'
                              ,'german money','how to get free%','%list of bank%','%make money%','%access%bank%','transfer','%bank near %'
                              ,'%bancos en canada%'  ,'%ismail ahmed%','%catherine win%','%recarga%grati%' ,'%ncell%'
                              ,'%nigeria rate%' ,'%exchange rate dollar%','%exchange rate usd%','%devops in %','%diwali%','%888%','%00%','%refer a friend%','%nuban number%') then 'informational'

   when top_keyword in ('payment to china','receive money from philippines','easiest way to send money from india to usa','cash deposit transfer'
                            ,'money transfer options to india','money transfer charges from usa to india','send money fees','transfer money from philippines to uae'
                            ,'international money transfer from sri lanka','exchange money in australia','money online','online money','money cash'
                            ,'transfers','money world','bank deposit','bank account','transfer app','enviar dinero a venezuela','money transfer tracking'
                            , 'send thailand','send money from india to singapore','track money transfer','send money from india to south africa'
                            ,'transfer money from india to uae','transfer money from india to south africa','how to send money from india to uae'
                            ,'money in south africa','corporation bank money transfer','usd account','bank deposit','free money','transfer inr'
                            ,'how to transfer money from india to uae','sending money china','how to get money from india to uk','money bank'
                            ,'how to receive money from mexico','india to sri lanka money transfer','best way to transfer money from india to uk'
                            ,'free transfer','money to china','receive money from germany','remitrate usd to inr','receive money from united states',
                            'ways to transfer money from mexico to usa','can i send money from ghana to usa','best india money transfer'
                            ,'track transfer','send money online to china','money account','send money from india to poland'
                            ,'banks in nigeria','best rate to transfer money to india from usa','transfer funds south africa','send transfer'
                            ,'transfer china','send money from ghana to uk','transfer money from singapore to india','top money transfer companies in india'
                            ,'enviar dinero a cuba online','app transfer','send money from nicaragua to usa','how to transfer money from indian bank account'
                            ,'send payment to china','china to india money transfer','transfer to a bank in india','deposit money in indian bank'
                            ,'best way to send money from india','send money from india to pakistan','how to send money in china','send mobile'
                            , 'money indonesia','money morocco','money exchange germany','money to the philippines')

         or   top_keyword LIKE ANY ('%send money%','%transfer funds%','%transfer money%','%money transfer%','%receive money%','%send payment%'
                                     ,'%enviar dinero%','%app transfer%','%sending money%','%send aud%','%send usd%','%send inr%','%worldwide remit%'
                                     ,'transfer %','%deposit money%','%balance transfer%','%cash app%','%money app%','%transfer app%','%geld senden%'
                                     ,'%fund transfer%','%funds transfer%','%wiring money%','%receiving money%','%bank tranfer%','%money to india%'
                                     ,'%transferring money%','%money exchange comparison%','%sending cash%','%wire money%','%skrill upload funds%'
                                     ,'%how to transfer%','%card to card%','%get money out of%','%how to open%','india bank account'
                                     ,'%pick%up%cash%','thailand remittance','%fast tranfer%','%global transfer%','onlinemoney','world transfer'
                                     , '%money to usa from india%','%bring money%','%bring cash%','%bring funds%','%fast%transfer%','%bank to bank transfer%'
                                     ,'%mobile money%','%geld transfer%','%wire transfer%','%china%transfer%','%bargeld senden%','%remittance to %'
                                     ,'%send euro%to%','%card%transfer%','%geld senden nach%','%geld sturen%','%envio%dinero%','%money trasfer to%'
                                     ,'%bank deposit to%','%geld overmaken%','%sent%money%','%transfer money%','%send money to%','%how to transfer%','%gcash international%','%money remittance%'
                                     ,'%transf%argent%','%remit to india%','%cash pickup%','money remit','remit money%','remit transfer%','%gcash india to %','remittance%philippines%')    then 'generic'

      when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%swift code%')  then 'informational'
      when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('%bancolombia%','%mpesa%', '%m pesa%'' ,%gcash%','%airtel%','%alipay%','%mtn mobile%'
                                                                            ,'%cebuana%','%palawan exp%','%digicel%','%airtel money%','%metrobank%','%balikbayan%'
                                                                            ,'%sofort%','%klarna%','%express union%','%intel express%')  then 'provider'
      when (top_keyword_paid_category is null) and  top_keyword LIKE ANY ('send money to%','%money transfer%','foreign money transfer to%','transfer money to%'
                                         ,'%quick cash%','%phone transfer%','%mobile transfer%','%quick money%','%wire transfer%','%sending fee%'
                                         ,'how to receive%','%send money%','%envoyer%argent%'
                                         ,'%geldtransfer%',' %international%payment%','%geld nach%','send cash to%','%usd to nigeria%','%payment send%') then 'generic'


     else top_keyword_paid_category end as page_category
 , clicks, impressions, tot_position
 , row_number() over (partition by top_keyword order by clicks desc) as row_number_kw
from paid_cat;


/*

-- USEFUL CODE


select * from personal_space_db.abungsy_stg.v_gsc_page_cat  limit 100

-- check availability of categories 0.0194690368
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
select * from personal_space_db.abungsy_stg.v_ga_googleads_query_cat where keyword like 'swift code%' order by visits_ppc desc  limit 100


*/
