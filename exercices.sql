----------- Requêtes ---------------------

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


---------- Agrégations -----------------

select size, count(*) as nb
from inventory.products
group by size
order by nb;

select state, count(*)
from sales.customers
group by state;

select name, round(avg(price), 2) as avg_price from inventory.products
group by name
order by avg_price;

select name, max(price) - min(price) as diff from inventory.products
group by name
order by name;

SELECT state, count(*), bool_and(newsletter) 
FROM sales.customers 
GROUP BY state;

select gender, count(*), round(avg(height), 2) as avg, 
	min(height), max(height), round(variance(height), 2) as var, 
	round(stddev(height), 2) as std
from people
group by gender;

select category_id, size, count(*),
	min(price) as "lowest price",
	max(price) as "highest price",
	round(avg(price), 2) as "average price"
from inventory.products
group by rollup(category_id, size)
order by category_id, size;

select 
	gender,
	count(*) filter (where height < 170) as cat1,
	avg(height) filter (where height < 170) as avg1,
	count(*) filter (where height >= 170) as cat2,
	avg(height) filter (where height >= 170) as avg2
from people
group by rollup(gender);

SELECT
  customer_id,
  EXTRACT(YEAR FROM order_date) AS order_year,
  EXTRACT(MONTH FROM order_date) AS order_month,
  COUNT(customer_id) AS order_count
FROM
  sales.orders
GROUP BY
  customer_id,
  order_year,
  order_month
ORDER BY
  customer_id,
  order_year ASC,
  order_month ASC;
  
select sku, sum(quantity) as "total" from sales.order_lines
group by(sku)
order by total desc;

SELECT 
    name, 
    size, 
    MIN(price) OVER(PARTITION BY name, size) AS min_price,
    MAX(price) OVER(PARTITION BY name, size) AS max_price,
    AVG(price) OVER(PARTITION BY name, size) AS avg_price
FROM inventory.products;

with tab as (
	select 
		order_lines.order_id as id, 
		products.sku as sku, 
		quantity, 
		price, 
		quantity * price as prod
	from sales.order_lines
	left join inventory.products on order_lines.sku = products.sku
)
select 
	id, sku, quantity, price, prod, 
	sum(prod) over (partition by id order by sku) as cum
from tab;
	

SELECT
	company,
	ROW_NUMBER() OVER (ORDER BY company) AS row_number,
	FIRST_VALUE(company) OVER (ORDER BY company) AS first_value,
	LAST_VALUE(company) OVER (ORDER BY company RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_value,
	NTH_VALUE(company, 3) OVER (ORDER BY company) AS nth_value
FROM sales.customers;


SELECT
	gender,
	percentile_disc(0.25) within group (order by height) as "0.25",
	percentile_disc(0.5) within group (order by height) as "0.5",
	percentile_disc(0.75) within group (order by height) as "0.75"
FROM people
GROUP by rollup(gender);

WITH tab AS (
	SELECT
		customer_id,
		FIRST_VALUE(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS first_order_date,
		LAST_VALUE(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_order_date
	FROM
		sales.orders
	ORDER BY
		customer_id
)
SELECT DISTINCT * FROM tab;


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

--------------------- INDEX ---------------------------------------

CREATE INDEX idx_orders_delivery_address_gin ON public.orders USING gin (delivery_address gin_trgm_ops);

CREATE INDEX idx_orders_order_date ON public.orders (order_date);

CREATE INDEX idx_orders_order_status ON public.orders (order_status) WHERE order_status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled');

CREATE INDEX idx_orders_customer_id_product_id ON public.orders (customer_id, product_id);




