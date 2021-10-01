-- original available on github here:
-- https://github.com/Worldremit/ma_performance/blob/master/spend_table_queries/update_f_mkt_spend.sql

-- code to auto update f_mkt_spend table
/************************************************
*   Facebook data
************************************************/
drop table if exists  #update_dates;
create table #update_dates as
select date_add('day', -29, current_date) as update_start,
        date_add('day', -1, current_date) as update_end;

DROP TABLE IF EXISTS #temp_facebook_spend ;
CREATE TABLE #temp_facebook_spend AS (
    WITH #max_date AS (
        SELECT account_name,
               country,
               date,
               campaign,
               ad_set_name,
               MAX(execution_date) AS most_recent_data_pull
        FROM datalake.smartly_accounts
        where date between (select update_start from #update_dates) and (select update_end from #update_dates)
        GROUP BY 1,2,3,4,5
        ORDER BY 1,2,3,4,5
    )
    SELECT FB.date::date AS date,
           'MT' AS product,
           CASE WHEN FB.account_name ILIKE 'App%' THEN 'app' ELSE 'website' END AS device,
           'facebook' AS channel,
           'smartly' AS platform,
           FB.account_name AS account,
           CASE
               WHEN LOWER(FB.account_name) ILIKE '%remarketing%' THEN 'remarketing'
               WHEN LOWER(FB.account_name) = 'offer account' THEN 'retention'
               WHEN LOWER(FB.campaign) ILIKE '%brand%' THEN 'brand'
               WHEN LOWER(FB.campaign) ILIKE '%receive%' THEN 'reverse'
               ELSE 'prospecting'
               END AS campaign_type,
           FB.campaign AS campaign_name,
           UPPER(FB.country) AS send_country,
           UPPER(RIGHT(SPLIT_PART(FB.ad_set_name,'_',2),2)) AS receive_country,
           SUM(FB.impressions::float) AS impressions,
           SUM(FB.spent::float) AS cost
    FROM datalake.smartly_accounts FB
    INNER JOIN #max_date MD
        ON FB.account_name = MD.account_name
        AND FB.country = MD.country
        AND FB.date = MD.date
        AND FB.campaign = MD.campaign
        AND FB.ad_set_name = MD.ad_set_name
        AND FB.execution_date = MD.most_recent_data_pull
    WHERE
        FB.date::date between (select update_start from #update_dates) and (select update_end from #update_dates)
    GROUP BY 1,2,3,4,5,6,7,8,9,10
) ;

/************************************************
*   Apple data
************************************************/
DROP TABLE IF EXISTS #temp_apple_spend ;
CREATE TABLE #temp_apple_spend AS (
    SELECT AA.date::date AS date,
           'MT' AS product,
           'app' AS device,
           'mobile' AS channel,
           'apple' AS platform,
           'apple' AS account,
           'prospecting' AS campaign_type,
           AA.campaign_name,
           UPPER(LEFT(SPLIT_PART(AA.campaign_name,'_',2),2)) AS send_country,
           UPPER(RIGHT(SPLIT_PART(AA.campaign_name,'_',2),2)) AS receive_country,
           SUM(AA.impressions::float) AS impressions,
           SUM(AA.local_spend::float) AS cost
    FROM datalake.apple_ads_creative_set AA
    WHERE
       AA.date::date between (select update_start from #update_dates) and (select update_end from #update_dates)
    GROUP BY 1,2,3,4,5,6,7,8,9,10
) ;

/************************************************
*   Search data
************************************************/
DROP TABLE IF EXISTS #temp_doubleclick_spend ;
CREATE TABLE #temp_doubleclick_spend AS
    WITH #search_data AS (
        SELECT date,
               accounttype,
               accountid,
               adgroupengineid,
               campaign,
               adgroupid,
               MAX(file_id) AS file_id
        FROM datalake.doubleclicksearch_v1_adgroup
        where date between (select update_start from #update_dates) and (select update_end from #update_dates)
        GROUP BY 1,2,3,4,5,6
    )
    SELECT date::date AS date,
           CASE WHEN campaign ILIKE '%_AT_%' THEN 'AT' ELSE 'MT' END AS product,
           'website' AS device,
           CASE
               WHEN campaign ILIKE 'Gmail%' THEN 'display'
               WHEN UPPER(accounttype) = 'FACEBOOK' THEN 'facebook'
               ELSE 'search' END AS channel,
           accounttype AS platform,
           account AS account,
           CASE WHEN campaign ILIKE '%TM%' THEN 'brand' ELSE 'prospecting' END campaign_type,
           campaign AS campaign_name,
           UPPER(LEFT(SPLIT_PART(campaign,'_',3),2)) AS send_country,
           UPPER(RIGHT(SPLIT_PART(campaign,'_',3),2)) AS receive_country,
           SUM(impr::float) AS impressions,
           SUM(cost::float) AS cost
    FROM datalake.doubleclicksearch_v1_adgroup DC
    INNER JOIN #search_data SD
        USING(date, accounttype, accountid, adgroupengineid, campaign, adgroupid, file_id)
    WHERE
         DC.date::date between (select update_start from #update_dates) and (select update_end from #update_dates)
        AND LOWER(DC.campaign) ILIKE 'search%'
    GROUP BY 1,2,3,4,5,6,7,8,9,10 ;

/************************************************
*   Display data
************************************************/
DROP TABLE IF EXISTS #temp_display_spend ;
CREATE TABLE #temp_display_spend AS
WITH #display_data AS (
    SELECT date,
           campaign_id,
           advertiser_id,
           creative_id,
           line_item_id,
           country,
           MAX(eqt) AS eqt
    FROM datalake.google_display_video_360_corridor_cpa
    where date between (select update_start from #update_dates) and (select update_end from #update_dates)
    GROUP BY 1,2,3,4,5,6
)
SELECT TO_DATE(DV.date, 'YYYY/MM/DD') AS date,
       'MT' AS product,
       'website' AS device,
       'display' AS channel,
       'display360' AS platform,
       DV.advertiser AS account,
       CASE
           WHEN DV.advertiser = 'WorldRemit - Remarketing' THEN 'remarketing'
           WHEN DV.advertiser = 'WorldRemit - Private Deals' THEN 'private deals'
           ELSE 'prospecting'
           END AS campaign_type,
       DV.campaign AS campaign_name,
       UPPER(country) AS send_country,
       UPPER(RIGHT(SPLIT_PART(DV.line_item,'_',1),2)) AS receive_country,
       SUM(DV.impressions::float) AS impressions,
       SUM(DV.revenue_adv_currency::float) AS cost
FROM datalake.google_display_video_360_corridor_cpa DV
INNER JOIN #display_data DD
    USING(date,campaign_id,advertiser_id,creative_id,line_item_id,country,eqt)
WHERE
    TO_DATE(DV.date, 'YYYY/MM/DD') between (select update_start from #update_dates) and (select update_end from #update_dates)
GROUP BY 1,2,3,4,5,6,7,8,9,10 ;

/************************************************
*   Affiliates data updated separately - run the below query first (unless Jim has already sorted this with fivetran):
  https://github.com/Worldremit/ma_performance/blob/master/spend_table_queries/affiliates_master_table.sql
************************************************/
DROP TABLE IF EXISTS #temp_affiliates_spend ;
-- Need date, product, device, channel, platform, account, campaign_type, campaign_name, send_country, receive_country, impressions, cost
CREATE TABLE #temp_affiliates_spend AS
SELECT  activity_timestamp::date AS date,
       mt_or_at AS product,
       'web' AS device, -- assume web, but we could pull through device from the base table I think
       'Affiliates' AS channel,
       case when advertiser_id is not null then 'Awin' else 'Direct Affiliate'  end AS platform,
       case when advertiser_id is not null then 'Awin' else 'Direct Affiliate - '||affiliate end AS account,
       transaction_type campaign_type,
       affiliate AS campaign_name,
       coalesce(send_country_iso2, awin_send_country, 'XX') AS send_country,
       coalesce(receive_country_iso2, 'YY') AS receive_country,
       null AS impressions,
       sum(case when awin_cost is null then 0 else awin_cost end) as a1,
       sum(case when direct_affiliate_cost is null then 0 else direct_affiliate_cost end) as a2,
       a1+a2 AS cost
FROM _prv_marketing.affiliates_master_table
    WHERE
  activity_timestamp between (select update_start from #update_dates) and (select update_end from #update_dates)
GROUP BY 1,2,3,4,5,6,7,8,9,10 ;


/************************************************
*   Google Ads data - needs to be downloaded separately - see the CPA Report Documentation below:
************************************************/

DROP TABLE IF EXISTS countries;
CREATE TEMPORARY TABLE countries AS
  (SELECT
      distinct
      country_iso2_code
      , country_name
      , region_name
   FROM d_geography
    WHERE level_code = 'COUNTRY');

-- There are a number of countries without iso2 code, the only one that matters is Czechia which is the Czech Republic,
-- about 40K worth of spend the rest total <£5 so just make them generic until we have an automated connector up

drop table if exists #temporary_UAC_spend;
create table #temporary_UAC_spend as
select
       case when a.ad_date ilike '%/%' then to_date(a.ad_date, 'DD/MM/YYYY')
           else to_date(a.ad_date, 'YYYY-MM-DD')
           end as date,
       'MT' as product,
       'app' as device,
       'mobile' as channel,
       'uac' as platform,
       'mobile_app_install_and_mobile_app_reengagement' as account,
       'prospecting' as campaign_type,
       campaign as campaign_name,
       case when country = 'Czechia' then 'CZ'
            when b.country_iso2_code is null then 'XX'
            else b.country_iso2_code
            end as send_iso2,
       case when c.country_iso2_code is null then 'YY' -- turns out UAC has no corridor information, all generic
            else c.country_iso2_code
            end as receive_iso2,
       case when country = 'Czechia' then 'Czech Republic'
            when send_iso2 = 'XX' then 'Generic'
            else b.country_name
            end as send_country,
       case when receive_iso2 = 'YY'  then 'Generic'
           else c.country_name
            end as receive_country,
       sum(CAST(replace(rtrim(cost, ' '), ',', '') as DOUBLE PRECISION)) as impressions,
       sum(CAST(replace(rtrim(cost, ' '), ',', '') as DOUBLE PRECISION)) as cost
from _prv_marketing.marketing__cds_adwords_uac_mobile a
left join countries b on a.country = b.country_name
left join countries c on right(split_part(a.campaign,'_',2),2) = c.country_iso2_code
where date between (select update_start from #update_dates) and (select update_end from #update_dates)
group by 1,2,3,4,5,6,7,8,9,10,11,12;

/************************************************
*   Gather Data Together
************************************************/

drop table if exists #marketing_spend_temporary;
create table #marketing_spend_temporary as
(
    SELECT f.date, product, device, channel, platform, account, campaign_type, campaign_name, send_country, receive_country, impressions, cost FROM #temp_facebook_spend f
    UNION ALL
    SELECT a.date, product, device, channel, platform, account, campaign_type, campaign_name, send_country, receive_country, impressions, cost FROM #temp_apple_spend a
    UNION ALL
    SELECT ds.date, ds.product, ds.device, ds.channel, ds.platform, ds.account, ds.campaign_type, ds.campaign_name, ds.send_country, ds.receive_country, ds.impressions, ds.cost  FROM #temp_doubleclick_spend ds
    UNION ALL
    SELECT d.date, d.product, d.device, d.channel, d.platform, d.account, d.campaign_type, d.campaign_name, d.send_country, d.receive_country, d.impressions, d.cost FROM #temp_display_spend d
    UNION ALL
    SELECT a.date, a.product, a.device, a.channel, a.platform, a.account, a.campaign_type, a.campaign_name, a.send_country, a.receive_country, cast(a.impressions as double precision), a.cost FROM #temp_affiliates_spend a
    UNION ALL
    select b.date, b.product, b.device, b.channel, b.platform, b.account, b.campaign_type, b.campaign_name, b.send_iso2 as send_country, b.receive_iso2 as receive_country, b.impressions, b.cost from #temporary_UAC_spend b
);

drop table if exists #marketing_spend_into_f_mkt_spend;
create table #marketing_spend_into_f_mkt_spend as
with geography as (
  select distinct
    country_iso2_code,
    region_name,
    country_name
from d_geography
)
select t.date,
       product,
       device,
       channel,
       platform,
       account,
       campaign_type,
       campaign_name,
       case when t.send_country in ('UNKNOWN') or t.send_country is null then 'XX' else t.send_country end as send_iso2,
       case when t.receive_country in ('UNKNOWN') or t.receive_country is null then 'XX' else t.receive_country end as receive_iso2,
       case when send_iso2 in ('XX', 'YY') or send_iso2 is null then 'Generic' else g1.country_name end as send_country,
       case when receive_iso2 in ('XX', 'YY') or receive_iso2 is null then 'Generic' else g2.country_name end as receive_country,
       impressions,
       cost
from #marketing_spend_temporary t
left join geography g1 on t.send_country = g1.country_iso2_code
left join geography g2 on t.receive_country = g2.country_iso2_code
;

-- delete data from date range
delete from _prv_marketing.f_mkt_channel_spend
where date between (select update_start from #update_dates) and
           (select update_end from #update_dates) ;

-- replace with newest data
insert into _prv_marketing.f_mkt_channel_spend
select *
from #marketing_spend_into_f_mkt_spend;

grant select on _prv_marketing.f_mkt_channel_spend to public;

/* if you want to update the latest month in the old spend table user_temp_schema.mkting_daily_channel_spend then use below query,
   the user_temp_schema table has a different structure where it needs region and a legacy additional column for cost
   */

/*
     drop table if exists user_temp_schema.marketing_spend_into_f_mkt_spend;
    create table user_temp_schema.marketing_spend_into_f_mkt_spend as
    with geography as (
      select distinct
        country_iso2_code,
        region_name,
        country_name
    from d_geography
    )
    select t.date, product, device, channel, platform, account as account_name, campaign_type, campaign_name,
           g1.country_name as sender_country,
           g1.region_name as sender_region, -- these columns needed if appending to user_temp_schema.mkting_daily_channel_spend
           g2.country_name as receive_country,
           g2.region_name as receiver_region,
           cost as ad_cost,
           cost as total_cost
    from user_temp_schema.marketing_spend_temporary t
    left join geography g1 on t.send_country = g1.country_iso2_code
    left join geography g2 on t.receive_country = g2.country_iso2_code;
;
 */
