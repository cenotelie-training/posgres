select
	size, count(*)
from inventory.products
group by size

select
	name, count(*) as "num"
from inventory.products
group by name
order by num desc;

select category_id, size, count(*)
from inventory.products
group by cube(category_id, size)
order by category_id, size

select 
	count(*) filter (where height < 170) as cat1,
	avg(height) filter (where height < 170) as avg1,
	count(*) filter (where height >= 170) as cat2,
	avg(height) filter (where height >= 170) as avg2
from people;

select customer_id,
	count(*) filter (where order_date >= '2021-03-01' and order_date <= '2021-03-31') as "March",
	count(*) filter (where order_date between '2021-04-01' and '2021-04-30') as "April"
from sales.orders
group by customer_id;

select sku, size, avg(price), min(size), max(size) over(partition by size)
from inventory.products
order by sku, size;

select sku,
	name,
	size,
	category_id,
	price,
	avg(price) over(partition by size) as "average price for size",
	price - avg(price) over(partition by size) as "difference"
from inventory.products
order by sku, size;

select id, sum(id) over (partition by id) as "sum"
from inventory.categories;

select order_lines.order_id,
	order_lines.id,
	order_lines.sku,
	order_lines.quantity,
	products.price as "price each",
	order_lines.quantity * products.price as "line total",
	sum (order_lines.quantity * products.price)
		over (partition by order_id) as "order total",
	sum (order_lines.quantity * products.price)
		over (order by id) as "cumul total"
from sales.order_lines inner join inventory.products
	on order_lines.sku = products.sku;
	
select
	id,
	sum(id) over(order by id rows between 0 preceding and 2 following)
from sales.orders;

select
	percentile_disc(0.5) within group (order by height) as "discrete median",
	percentile_cont(0.5) within group (order by height) as "discrete median"
from people;

select name, height, ntile(4) over (order by height)
from people order by height;

select
	mode() within group (order by height)
from public.people;

select category_id,
	min(price) as "min price",
	percentile_cont(.25) within group (order by price) as "1st quartile",
	percentile_cont(.50) within group (order by price) as "2nd quartile",
	percentile_cont(.75) within group (order by price) as "3rd quartile",
	max(price) as "max price",
	max(price) - min(price) as "price range"
from inventory.products
group by rollup(category_id);

select name, gender, height,
	rank() over (partition by gender order by height desc),
	dense_rank() over (partition by gender order by height desc)
from people
order by gender, height desc;
