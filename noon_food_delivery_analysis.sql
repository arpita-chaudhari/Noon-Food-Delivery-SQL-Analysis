

--1)Find Top 3 Outlets by Cuisine Type without using LIMIT or TOP function.
with cte as (
select Cuisine , Restaurant_id , COUNT(*) as no_of_orders
from orders
group by Cuisine , Restaurant_id)
select * from (
select * 
, ROW_NUMBER() over(partition by cuisine order by no_of_orders desc) as rn
from cte ) a
where rn<=3



--2- Find the daily new customer count from the launch date (everyday how many new customers are we acquiring)
with cte as (
select Customer_code , cast(MIN(placed_at) AS date) as first_order_date
from orders
group by Customer_code)

select first_order_date, COUNT(1) as no_of_new_customers
from cte
group by first_order_date
order by first_order_date



--3 Count of all the users who were acquired in Jan 2025 and only placed one order in Jan 
--and did not place any other order.
select Customer_code , COUNT(*) as no_of_orders
from orders
where MONTH(placed_at)=1 and YEAR(placed_at)=2025
and Customer_code not in (select distinct Customer_code 
from orders 
where not (MONTH(placed_at)=1 and YEAR(placed_at)=2025)
)
group by Customer_code
having COUNT(*)=1


--4) List All the customers with no order in the last 7 days but were acquired one month ago with their first order on promo.
with cte as (
select Customer_code , MIN(placed_at) as first_order_date
, max(placed_at) as latest_order_date
from orders
group by Customer_code)
select cte.* , orders.Promo_code_Name as first_order_promo from cte 
inner join orders on cte.Customer_code=orders.Customer_code and cte.first_order_date=orders.Placed_at
where latest_order_date < dateadd(DAY,-7,getdate())
and first_order_date < dateadd(month,-1,getdate()) and orders.Promo_code_Name is not null



--5)Growth team is planning to create a trigger that will target customers after their every third order with a personalized communication. Create a query for this.
with cte as (
    select *,
        ROW_NUMBER() over(partition by customer_code order by placed_at) as order_number
    from orders
)
select *
from cte
where order_number % 3 = 0 and cast(Placed_at as date) = cast(GETDATE() as date)




--6) List customers who placed more than 1 order and all their orders on a promo only
select Customer_code, COUNT(*) as no_of_orders, COUNT(Promo_code_Name) as promo_orders
from orders
group by Customer_code
having COUNT(*) > 1 and COUNT(*) = COUNT(Promo_code_Name)


--7) what percent of customers were organically acquired in jan 2025. (placed their first order without promo code)
with cte as (
select * 
, ROW_NUMBER() over(partition by customer_code order by placed_at) as rn
from orders
where MONTH(placed_at) = 1
)
select COUNT(case when rn=1 and Promo_code_Name is null then customer_code end) * 100.0 / COUNT(distinct Customer_code)
from cte
