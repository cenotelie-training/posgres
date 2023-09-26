select * from inventory.products
where price between 10 and 20;

select employees.firstname, employees.lastname, services.name as service from manufacturing.employees as employees
left join manufacturing.services as services
on employees.service_id = services.id
where services.name = 'Manufacturing';

select * from manufacturing.employees
where employees.lastname like 'F%';

select * from manufacturing.employees
where employees.firstname ilike 'D%E';

create view manufacturing.members
as
select firstname, lastname, name
from manufacturing.employees
left join manufacturing.services
on employees.service_id = services.id;

create role rh with login;
grant select on table manufacturing.employees to rh;
alter role rh with password 'avicenne';

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

----------------- PARTITIONS ------------------------

ALTER TABLE public.people RENAME TO old_people;

CREATE TABLE public.people (
    id serial not null,
    name varchar(20),
    height decimal(5,2),
    gender char(1)
) PARTITION BY LIST (gender);

CREATE TABLE public.people_male PARTITION OF public.people FOR VALUES IN ('m');
CREATE TABLE public.people_female PARTITION OF public.people FOR VALUES IN ('f');

ALTER TABLE public.people_male ADD PRIMARY KEY (id);
ALTER TABLE public.people_female ADD PRIMARY KEY (id);

INSERT INTO public.people SELECT * FROM old_people;

DROP TABLE old_people;

--OPTIONNEL: si d'autres catégories viennent se rajouter

CREATE TABLE public.people_trans PARTITION OF public.people FOR VALUES IN ('t');
ALTER TABLE public.people ATTACH PARTITION public.people_trans FOR VALUES IN ('t');


