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
  
select sku, sum(quantity) as "total" 
from sales.order_lines
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

select category_id,
	min(price) as "min price",
	percentile_cont(.25) within group (order by price) as "1st quartile",
	percentile_cont(.50) within group (order by price) as "2nd quartile",
	percentile_cont(.75) within group (order by price) as "3rd quartile",
	max(price) as "max price",
	max(price) - min(price) as "price range"
from inventory.products
group by rollup(category_id);

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

select name, gender, height,
	rank() over (partition by gender order by height desc),
	dense_rank() over (partition by gender order by height desc)
from people
order by gender, height desc;

select
	mode() within group (order by height)
from public.people;

SELECT round(height), COUNT(*)
FROM public.people
GROUP BY round(height);

--OR

SELECT DISTINCT height,
       COUNT(*) OVER (PARTITION BY height) as count
FROM public.people;

SELECT
    pclass,
    sex,
	case
		when age < 20 then '-20'
		when age >= 20 and age < 40 then '20-40'
		when age >= 40 and age < 60 then '40-60'
		else '60+'
	end as category,
    COUNT(*) AS total_people,
    SUM(survived) / COUNT(*)::float AS survival_rate
FROM public.titanic
GROUP BY pclass, sex, category
ORDER BY survival_rate;

----------------- SERIES TEMPORELLES ----------------

SELECT 
    t.city,
    t.country,
    ROUND(MIN(t.measure_value), 2) AS min,
    ROUND(MAX(t.measure_value), 2) AS max,
    ROUND(AVG(t.measure_value), 2) AS mean,
    ROUND((MAX(t.measure_value) - MIN(t.measure_value)), 2) AS interval,
    ROUND(STDDEV(t.measure_value), 2) AS dev,
    c.nb_cities
FROM public.temperatures t
JOIN (
    SELECT 
        country,
        COUNT(DISTINCT city) AS nb_cities
    FROM public.temperatures
    GROUP BY country
) c ON t.country = c.country
GROUP BY t.city, t.country, c.nb_cities
ORDER BY t.country, t.city;

SELECT 
    EXTRACT(YEAR FROM measure_date) AS year,
    ROUND(AVG(measure_value), 2) AS avg_annual_temperature
FROM public.temperatures
WHERE 
    city = 'Paris' AND 
    EXTRACT(YEAR FROM measure_date) BETWEEN 1900 AND 1999
GROUP BY year
ORDER BY year;

SELECT CORR(paris, new_york) as corr_coeff
FROM (
	SELECT 
		EXTRACT(YEAR FROM measure_date) AS year,
		AVG(CASE WHEN city = 'Paris' THEN measure_value END) AS paris,
		AVG(CASE WHEN city = 'New York' THEN measure_value END) AS new_york
	FROM public.temperatures
	WHERE 
		(city = 'Paris' OR city = 'New York') AND 
		EXTRACT(YEAR FROM measure_date) BETWEEN 1900 AND 1999
	GROUP BY year
	ORDER BY year
) AS annual_temperatures;

WITH RankedTemperatures AS (
    SELECT
        EXTRACT(YEAR FROM measure_date) AS year,
        CASE 
            WHEN EXTRACT(MONTH FROM measure_date) <= 6 THEN 'First Half'
            ELSE 'Second Half'
        END AS half_year,
        measure_value AS temperature,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM measure_date), 
            CASE WHEN EXTRACT(MONTH FROM measure_date) <= 6 THEN 'First Half' ELSE 'Second Half' END
            ORDER BY measure_date
        ) AS row_num
    FROM public.temperatures
    WHERE 
        city = 'Paris' AND
        EXTRACT(YEAR FROM measure_date) BETWEEN 1900 AND 1999
)
SELECT year, half_year, temperature
FROM RankedTemperatures
WHERE row_num = 1
ORDER BY year, half_year;

SELECT
    date_trunc('decade', measure_date) AS decade_start,
    ROUND(AVG(measure_value), 2) AS avg_temperature
FROM public.temperatures
WHERE 
    city = 'Paris' AND
    measure_date BETWEEN '1900-01-01' AND '1999-12-31'
GROUP BY decade_start
ORDER BY decade_start;

SELECT
    year,
    AVG(avg_temperature) OVER (ORDER BY year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS moving_avg_temperature
FROM (
    SELECT
        EXTRACT(year FROM measure_date) AS year,
        AVG(measure_value) AS avg_temperature
    FROM public.temperatures
    WHERE 
        city = 'Paris' AND
        measure_date BETWEEN '1900-01-01' AND '1999-12-31'
    GROUP BY year
) AS yearly_avg_temperatures
ORDER BY year;

with tab as (
	select measure_date, round(measure_value, 2) as measure
	from temperatures
	where city='Paris' 
		and (extract(year from measure_date) between 1900 and 2000)
	order by measure_date
)
select measure_date, 
	measure, 
	measure - lag(measure) over() as diff
from tab;

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

--------------------- QUIZZ -------------------------------------

-- 2. b, 3. d, 4. b, 5. c, 6. a, 8. d

