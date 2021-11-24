-- list of Google Ads campaigns and their countries, from Google Analytics Sessions table
create or replace view personal_space_db.abungsy_stg.v_dim_googleads_countries as

with
ga as
(select
 traffic_source_campaign as campaign
, geo_network_country as country
, sum(total_visits ) visits
, sum(total_transactions) trx
from WR_FIVETRAN_DB.GA360_WEB_FIVETRAN_STG.GA_SESSION
where channel_grouping = 'Paid Search' and traffic_source_source = 'google' and traffic_source_campaign is not null and traffic_source_adwords_click_info_ad_network_type <> 'NULL'
group by 1,2
),

grouped as (select ga.*, row_number() over (partition by campaign order by visits desc)  as row_visits
              , row_number() over (partition by campaign order by trx desc)  as row_trx
              ,  round(100 * ratio_to_report(visits) over (partition by campaign),0) as percent_visits
              ,  round(100 * ratio_to_report(visits) over (partition by campaign),0) as percent_trx
            from ga)

select grouped.*
from grouped
where row_visits = 1;

/*
USEFUL CODE

-- show view
select *
from personal_space_db.abungsy_stg.v_dim_googleads_countries limit 100


*/
