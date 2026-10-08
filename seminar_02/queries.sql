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

-- Seminar 3 Task 1b
-- Uloha 1
with high_sales as (
    select sale_date, sum(total_amount) as daily_sales
    from flourmills_sales
    group by sale_date
)
select *
from high_sales
where daily_sales > 3000000
order by daily_sales desc;

-- Uloha 2
with category_sales as (
    select product_category, sum(total_amount) as total_sales
    from flourmills_sales
    group by product_category
)
select *
from category_sales
order by total_sales desc;

-- Uloha 3
WITH product_sales AS (
    SELECT 
        product_category,
        product_name,
        SUM(total_amount) AS total_product_sales
    FROM flourmills_sales
    GROUP BY product_category, product_name
),
ranked_products AS (
    SELECT 
        product_category,
        product_name,
        total_product_sales,
        RANK() OVER (
            PARTITION BY product_category 
            ORDER BY total_product_sales DESC
        ) AS category_rank
    FROM product_sales
)
SELECT 
    product_category,
    product_name,
    total_product_sales,
    category_rank
FROM ranked_products
WHERE category_rank <= 3
ORDER BY product_category ASC, category_rank ASC
LIMIT 10;

-- Uloha 4
with customer_type_sales as (
    select customer_type, sum(total_amount) as revenue
    from flourmills_sales
    group by customer_type
),
sales_share as (
    select customer_type, revenue, sum(revenue) over () as total_revenue, round((revenue / sum(revenue) over () * 100.0), 2) as revenue_percentage
    from customer_type_sales
)
select customer_type, revenue, total_revenue, revenue_percentage
from sales_share
order by revenue desc;

-- Uloha 5
with customers_last_orders as(
    select customer_id, product_name, sale_date, total_amount,
    row_number() over (
        partition by customer_id
        order by sale_date desc
    ) as rn
    from flourmills_sales
)
select customer_id, product_name, sale_date, total_amount
from customers_last_orders
where rn = 1
order by customer_id asc
limit 5;

-- Uloha 6
with recursive date_bounds as (
    select MIN(sale_date) as min_date, MAX(sale_date) as max_date
    from flourmills_sales
),
calendar as (
    select min_date as datum, max_date
    from date_bounds

    union all

    select (datum + 1)::date, max_date
    from calendar
    where datum < max_date
)
select datum
from calendar
order by datum asc;


-- Uloha 7
with recursive monthly_revenue as (
    select DATE_TRUNC('month', sale_date) as month, SUM(total_amount) as revenue
    from flourmills_sales
    group by DATE_TRUNC('month', sale_date)
),
ordered_months as (
    select row_number() over (order by month) as rn, month, revenue
    from monthly_revenue
),
cumulative_target as (
    -- Anchor:
    select rn, month, revenue, revenue as cumulative_revenue
    from ordered_months
    where rn = 1

    union all

    select om.rn, om.month, om.revenue, c.cumulative_revenue + om.revenue as cumulative_revenue
    from cumulative_target c
    join ordered_months om on om.rn = c.rn + 1
    where c.cumulative_revenue < 500000000
)
select rn, month, revenue, cumulative_revenue
from cumulative_target
order by rn;