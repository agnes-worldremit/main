
-- Output available in the following Google Drive folder
-- https://drive.google.com/drive/folders/1aFtdZ7esr6HYPJBcAy5pBmtMnn19P7ZW?usp=sharing


select case when country in ('usa','gbr') then country else 'other' end as country_group
     , device
     , page
     , sum(impressions) impressions
     , sum(clicks) clicks
     , sum(impressions*position) pos_tot

   from      "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."PAGE_REPORT"
   where page like '%/en/%' and search_type = 'web' and (date between '2020-10-01' and '2022-01-31')
   group by case when country in ('usa','gbr') then country else 'other' end
     , device
     , page;
