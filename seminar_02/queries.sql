-- Active: 1790701026297@@127.0.0.1@5432@datacraftinglab_db@public
CREATE TABLE flourmills_sales (
    sales_id INT PRIMARY KEY,
    sale_date DATE,
    region VARCHAR(100),
    state VARCHAR(100),
    product_category VARCHAR(100),
    product_name VARCHAR(150),
    customer_type VARCHAR(100),
    customer_id INT,
    quantity_sold INT,
    unit_price NUMERIC(10,2),
    discount_rate INT,
    payment_method VARCHAR(100),
    sales_rep VARCHAR(150),
    warehouse VARCHAR(100),
    delivery_status VARCHAR(100),
    order_channel VARCHAR(100),
    batch_number INT,
    production_date DATE,
    total_amount NUMERIC(10,2)
);

-- Uloha 2
select product_name, total_amount
from flourmills_sales
where total_amount > (select avg(total_amount) from flourmills_sales);

-- Uloha 3
select * 
from flourmills_sales
where product_category = (select product_category 
    from flourmills_sales 
    group by product_category 
    order by sum(total_amount) desc
    limit 1)
order by sales_id asc;

-- Uloha 4
select product_name, total_amount, (select avg(total_amount) from flourmills_sales) as avg_amount
from flourmills_sales;

-- Uloha 5
select product_name, total_amount, (total_amount / (select sum(total_amount) from flourmills_sales)) as amount_share
from flourmills_sales;

-- Uloha 6
select mesiac, monthly_sales
from (
    select extract(month from sale_date) as mesiac, sum(total_amount) as monthly_sales
    from flourmills_sales
    group by extract(month from sale_date)
) as summary
order by monthly_sales desc;

-- Uloha 7
select product_category, total_sales
from (
    select product_category, sum(total_amount) as total_sales
    from flourmills_sales
    group by product_category
) as summary
where total_sales > 50000000
order by total_sales desc;

-- Uloha 8
select f1.product_name, f1.product_category, f1.total_amount
from flourmills_sales f1
where f1.total_amount > (
    select avg(f2.total_amount)
    from flourmills_sales f2
    where f2.product_category = f1.product_category
);

-- Uloha 9
select f1.product_name, f1.region, f1.total_amount, 
(select min(f2.total_amount)
from flourmills_sales f2
where f2.region = f1.region)
from flourmills_sales f1;


-- Uloha 10
select f1.*
from flourmills_sales f1
where exists (
    select 1
    from flourmills_sales f2
    where f2.product_name = f1.product_name
    having count(distinct extract(month from f2.sale_date) > 1)
);

-- Uloha 11
select f1.product_category, f1.product_name, f1.total_amount
from flourmills_sales f1
where exists (
    select 1
    from flourmills_sales f2
    where f2.product_category = f1.product_category
    and f2.total_amount > 200000
);

-- Uloha 12
select f1.product_category
from flourmills_sales f1
where exists (
    select 1
    from flourmills_sales f2
    where f2.product_category = f1.product_category
    having count(distinct f2.region) > 3
)
group by f1.product_category;

-- Uloha 13
select f1.*
from flourmills_sales f1
where exists (
    select 1
    from flourmills_sales f2
    where f2.region = f1.region
    and extract(year from f2.sale_date) = 2024
);

-- Uloha 14
select f1.product_category
from flourmills_sales f1
where not exists (
    select 1
    from flourmills_sales f2
    where f2.product_category = f1.product_category
    and f2.total_amount > 500000
)
group by f1.product_category;

-- Uloha 15
select f1.region
from flourmills_sales f1
where not exists (
    select 1
    from flourmills_sales f2
    where f2.region = f1.region
    and f2.product_category = 'Flour'
)
group by f1.region;