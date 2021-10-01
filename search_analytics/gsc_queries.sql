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
from "WR_FIVETRAN_DB"."SEARCH_CONSOLE_FIVETRAN_STG"."KEYWORD_SITE_REPORT_BY_page"
where page = 'https://www.worldremit.com/en/us' and date = '2021-09-26' and device = 'MOBILE' and search_type = 'web' and country = 'usa'
