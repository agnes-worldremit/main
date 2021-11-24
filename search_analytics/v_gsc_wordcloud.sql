-- search queries split into individual words, with frequency included
-- this is to create a word cloud visualisation in Tableau

create or replace view personal_space_db.abungsy_stg.v_gsc_wordcloud as
with
splittable as (select *
              from personal_space_db.abungsy_stg.v_gsc_queries, table(split_to_table(keyword,' ')) as table1
              where  keyword <> 'XX_Uncategorized' and keyword not like '%-tail'),

cat as (select value,  region_name, sub_region_name, country_name, category , sum(seo_clicks) seo_clicks, sum(seo_impressions) seo_impressions from splittable group by 1,2,3,4,5)

-- tot as (select value,  region_name, sub_region_name, 'TOTAL' as category , sum(seo_clicks) seo_clicks, sum(seo_impressions) seo_impressions from splittable group by 1,2,3,4)

select * from cat
