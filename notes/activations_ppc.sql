/*
 MAIN TABLE
 user_temp_schema.f_mkt_online_paid_activations - MAIN ACTIVATIONS TABLE
Paid search
 user_temp_schema.search_activations_nd - current holding place for the paid search activations

 On top of this we need to include activation which are from a PPC add but the client downloaded
 the WR app and then activated - these will be covered as part of the Branch transformations

For reference branch holding table below
Branch
 user_temp_schema.branch_activations_nd (Jul 2019 - October 2020 branch activations - THESE HAVE BEEN INSERTED INTO MAIN TABLE)

 For each month the time frames need to be changed in order to only get the latest data
 */




drop table if exists #search_activations;
create table #search_activations as (
    select row_number() over (partition by c."transaction id" order by c.conversiontimestamp::timestamp desc ) row_latest
         ,right("transaction id",8)                                                                 transaction_id
         ,conversiontimestamp::timestamp                                                            conversiontimestamp
         ,c.campaign
         ,devicesegment
         ,'Paid_search'                                                                            source
    from datalake.doubleclicksearch_v1_conversion c
    where "transaction id" is not null
      and c.floodlightgroup = 'Activation'
      and accounttype in ('Google AdWords', 'Bing Ads')
      and conversiontimestamp::date >= '2021-03-01'
      and conversiontimestamp::date < '2021-04-01'
);

insert into  _prv_marketing.f_mkt_online_paid_activations
(
select cast(sa.transaction_id as int) transaction_id
       ,sa.conversiontimestamp source_activity_time
       ,'Search Ads' source
       , 'Paid Search'
       ,sa.campaign
       ,case when t.payout_method_id <> 20 then 'MT' else 'AT' end transaction_type
       ,t.is_client_first_transaction activation_in_dwh
       ,t.created_date activation_date_dwh
from #search_activations sa
left join f_transaction t on sa.transaction_id = t.transaction_id
where row_latest = 1
);
