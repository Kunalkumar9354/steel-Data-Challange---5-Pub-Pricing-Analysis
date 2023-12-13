create schema pub_pricing ;
use pub_pricing;

-- 1. How many pubs are located in each country??
select country,count(pub_id) as total_pubs 
from pubs
group by country;
-- 2. What is the total sales amount for each pub, including the beverage price and quantity sold?
select p.pub_name ,concat(sum(quantity*price_per_unit),"","$") total_sales from sales s 
join beverages b 
on s.beverage_id = b.beverage_id
join pubs p on s.pub_id = p.pub_id
group by p.pub_name;
-- 3. Which pub has the highest average rating?
with pub_rating_table as(select p.pub_name,round(avg(rating),2) as avg_rating,
rank() over(order by round(avg(rating),2) desc) as pub_rank
from pubs p
join ratings r on p.pub_id = r.pub_id
group by p.pub_name)
select pub_name,avg_rating from pub_rating_table
where pub_rank = 1;
-- 4. What are the top 5 beverages by sales quantity across all pubs?
with bev_rank_table as(select b.beverage_name,concat(sum(quantity*price_per_unit),"","$") total_sales,
rank() over(order by sum(quantity*price_per_unit) desc) as bev_rank
from beverages b 
join sales s
on b.beverage_id = s.beverage_id
group by b.beverage_name)
select beverage_name,total_sales
from bev_rank_table 
where bev_rank<=5;
-- 5. How many sales transactions occurred on each date?
 select transaction_date,count(distinct sale_id) as total_transactions
 from sales 
 group by transaction_date;
-- 6. Find the name of someone that had cocktails and which pub they had it in.
select p.pub_name,r.customer_name 
from sales  s
join beverages b
on s.beverage_id = b.beverage_id
join pubs p on s.pub_id = p.pub_id
join  ratings r on p.pub_id = r.pub_id
where b.category = "Cocktail";
-- 7. What is the average price per unit for each category of beverages, excluding the category 'Spirit'?
select concat(round(avg(price_per_unit),2),"","$") as avg_price_of_beverage
from beverages 
where category in ("Beer","Whiskey","Cocktail","Wine","Beer");
-- 8. Which pubs have a rating higher than the average rating of all pubs?
select p.pub_name from pubs p 
join ratings r on p.pub_id = r.pub_id 
where r.rating>(select avg(rating) from ratings);
-- 9. What is the running total of sales amount for each pub, ordered by the transaction date?
with running_table as(select s.transaction_date ,p.pub_name,(quantity*price_per_unit) as total_price
from pubs p 
join sales s on p.pub_id = s.pub_id
join beverages b on s.beverage_id = b.beverage_id
order by s.transaction_date)
select pub_name,sum(total_price) over(order by transaction_date)as running_total
from running_table;
-- 10. For each country, 
# what is the average price per unit of beverages in each category, 
#and what is the overall average price per unit of beverages across all categories?
select p.country,b.category,round(avg(b.price_per_unit),2)as avg_price,
round(avg(avg(b.price_per_unit)) over(partition by p.country),2) as overall_average
from sales s 
join pubs p on s.pub_id = p.pub_id
join beverages b on s.beverage_id = b.beverage_id
group by p.country,b.category;
-- 11. For each pub, what is the percentage contribution of each category of beverages to the total sales amount, 
#and what is the pub's overall sales amount?
select *
from beverages b 
join sales s 
on b.beverage_id = s.beverage_id;

with contribution_table as (select p.pub_name,b.category,sum(quantity*price_per_unit) as total_sales_by_category,
sum(sum(quantity*price_per_unit)) over(partition by pub_name) as total_sales
from beverages b 
join sales s 
on b.beverage_id = s.beverage_id
join pubs p on s.pub_id = p.pub_id
group by p.pub_name,b.category)
select pub_name,category,concat(round(100*(total_sales_by_category/total_sales),2),"","%") as percentage_contribution 
from contribution_table
