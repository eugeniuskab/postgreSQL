-- Active: 1792049892529@@127.0.0.1@5432@superstore@public
-- Uloha 1
CREATE TABLE retail_sales (
    invoice_no VARCHAR(20),
    stock_code VARCHAR(50),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(10, 2),
    customer_id INTEGER,
    country VARCHAR(100)
);

-- Uloha 2
select customer_id, invoice_no, invoice_date, quantity, unit_price, quantity * unit_price as revenue,
sum(quantity * unit_price) over (
    partition by customer_id
    order by invoice_date
    range between interval '14 days' preceding and current row
) as revenue_last_14_days
from retail_sales
where customer_id is not NULL
order by customer_id asc, invoice_date asc
limit 3;

-- Uloha 3
select stock_code, country, invoice_date, quantity, 
round(avg(quantity) over (
    partition by stock_code, country
    order by invoice_date
    range between interval '7 days' preceding and current row
)

,2) as avg_quantity_7_days
from retail_sales
where quantity > 1
order by stock_code asc, country asc, invoice_date asc;

-- Uloha 4
with unique_invoices as(
    select customer_id, invoice_no, invoice_date
    from retail_sales
    where customer_id is not NULL
),
invoices_with_lead as (
    select customer_id, invoice_no, invoice_date,
    lead(invoice_date, 1) over(
        partition by customer_id
        order by invoice_date asc
        ) as next_invoice_date
        from unique_invoices)
select customer_id, invoice_no,
invoice_date::DATE AS invoice_date,
    next_invoice_date::DATE AS next_invoice_date,
    (next_invoice_date::DATE - invoice_date::DATE) AS days_to_next_invoice
    from invoices_with_lead
    where next_invoice_date is not NULL
    order by days_to_next_invoice desc
    limit 5;

-- Uloha 5
with price_history as (
    select stock_code, invoice_no, invoice_date,
    lag(unit_price) over (
        partition by stock_code
        order by invoice_date asc
    ) as previous_price,
    unit_price as current_price
    from retail_sales
)
select stock_code, invoice_no, invoice_date, previous_price, current_price,
(current_price - previous_price) as price_difference
from price_history
where previous_price is not null
and previous_price <> current_price
order by invoice_date asc;

-- Uloha 6
with customer_sales as(
    select customer_id, sum(unit_price * quantity) as total_sales
    from retail_sales
    where customer_id is not null
    group by customer_id
)
select customer_id, total_sales,
ntile(4) over (
    order by total_sales desc
) as sales_quartile
from customer_sales
order by total_sales desc;

-- Uloha 7
with monthly_country_sales as (
    select country,
        DATE_TRUNC('month', invoice_date)::DATE AS month,
        SUM(quantity * unit_price) AS total_amount
    from retail_sales
    group by country, DATE_TRUNC('month', invoice_date)
)
select country, month, total_amount,
ntile(4) over(
    partition by country
    order by total_amount desc
) as sales_quartile
from monthly_country_sales
order by country asc, month asc;

-- Uloha 8
with ranked_sales as (
    select 
        customer_id, invoice_no, invoice_date, stock_code, description, quantity, unit_price,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY invoice_date ASC
        ) as rn
    from retail_sales
    where customer_id is not null
)
select customer_id, invoice_no, invoice_date, stock_code, description, quantity, unit_price
from ranked_sales
where rn = 1
ORDER BY customer_id ASC;

-- Uloha 9
with ranked_items as (
    select 
        invoice_no, stock_code, description, quantity, unit_price, (quantity * unit_price) as amount,
        row_number() OVER (
            PARTITION BY invoice_no
            ORDER BY (quantity * unit_price) desc
        ) as row_num
    from retail_sales
)
select invoice_no, stock_code, description, quantity, unit_price, amount, row_num
from ranked_items
where row_num <= 3
order by invoice_no asc, row_num asc;

-- Uloha 10
with monthly_customers_sales as (
    select country, 
    DATE_TRUNC('month', invoice_date)::DATE AS month, customer_id, 
    sum(quantity * unit_price) as total_amount
    from retail_sales
    where customer_id is not null
    group by country, 
    DATE_TRUNC('month', invoice_date), customer_id
),
ranked_customers as (
    select country, month, customer_id, total_amount,
    dense_rank() over (
        partition by country, month
        order by total_amount desc
    ) as sales_rank
    from monthly_customers_sales
)
select country, month, customer_id, total_amount, sales_rank
from ranked_customers
where sales_rank <= 5
order by country asc, month asc, sales_rank asc, customer_id asc;

-- Uloha 11
with ranked_prices as (
    select invoice_no, stock_code, description, quantity, unit_price,
        dense_rank() over (
            partition by invoice_no 
            order by unit_price desc
        ) as price_rank
    from retail_sales
)
select invoice_no, stock_code, description, quantity, unit_price, price_rank
from ranked_prices
where price_rank <= 5
order by invoice_no asc, price_rank asc, stock_code asc;

-- Task 1d
-- Uloha 1
with ranked_orders as(
    select c.customer_name, o.order_id, o.order_date,
    row_number() over (
        partition by o.customer_id
        order by o.order_date desc
        ) as order_number
from orders o
join customers c on c.customer_id = o.customer_id
)
select customer_name, order_id, order_date
from ranked_orders
where order_number <= 2
order by customer_name asc, order_number asc;

-- Uloha 2
with customer_regional_profit as (
    select c.region, c.customer_name,
        sum(o.profit) as total_profit
    from orders o
    join customers c on c.customer_id = o.customer_id
    group by 
        c.region, 
        c.customer_name
)
select region, customer_name, total_profit,
    rank() over (
        partition by region 
        order by total_profit desc
    ) as rank_profit,
    dense_rank() over (
        partition by region 
        order by total_profit desc
    ) as dense_rank_profit
from customer_regional_profit
order by region asc, total_profit desc
limit 5;

-- Uloha 3
with customer_sales as (
    select c.customer_name,
        sum(o.sales) as total_sales
    from orders o
    join customers c on c.customer_id = o.customer_id
    group by c.customer_name
)
select customer_name, total_sales,
    ntile(4) over (
        order by total_sales desc
    ) as quartile
from customer_sales
order by total_sales desc;

-- Uloha 4
with monthly_data as (
    select 
        date_trunc('month', order_date)::date as month,
        sum(sales) as monthly_sales
    from orders
    group by date_trunc('month', order_date)
)
select month, monthly_sales,
    lag(monthly_sales, 1) over (order by month asc) as prev_month_sales,
    lead(monthly_sales, 1) over (order by month asc) as next_month_sales
from monthly_data
order by month asc;

-- Uloha 5
with product_totals as (
    select p.category, p.product_name,
    sum(o.sales) as product_sales
    from orders o
    join products p on o.product_id = p.product_id
    group by p.category, p.product_name
)
select 
    category,
    product_name,
    product_sales,
    sum(product_sales) over (partition by category) as category_total,
    round(
        product_sales * 100.0 / sum(product_sales) over (partition by category),
        2
    ) as pct_of_category
from product_totals
order by category asc, product_sales desc;

-- Uloha 6
with customer_order_dates as (
    select distinct c.customer_id, c.customer_name,
        max(o.order_date) over (
            partition by o.customer_id
        ) as last_order_date,
        max(o.order_date) over () as latest_order_date
    from orders o
    join customers c on c.customer_id = o.customer_id
)
select customer_id, customer_name, last_order_date
from customer_order_dates
where last_order_date < latest_order_date - interval '90 days'
order by last_order_date asc;

-- Uloha 7
with monthly_sales as (
    select date_trunc('month', order_date)::date as month,
    sum(sales) as month_sales
    from orders
    group by date_trunc('month', order_date)
),
prev_monthly_sales as (
    select month, month_sales,
    lag(month_sales) over (order by month) as prev_month_sales
    from monthly_sales
)
select month, month_sales, prev_month_sales,
month_sales - prev_month_sales as sales_change,
round((month_sales - prev_month_sales) * 100.0 / prev_month_sales, 2) as growth_percentage
from prev_monthly_sales
order by month asc;

-- Uloha 8
with customer_first_month as (
    select customer_id, date_trunc('month', min(order_date))::date as first_month
    from orders
    group by customer_id
    having date_trunc('month', min(order_date))::date = '2024-06-01'
)
select count(*) as returning_customers_count
from customer_first_month cfm
where exists (
    select 1
    from orders o
    where o.customer_id = cfm.customer_id
    and o.order_date >= '2024-07-01'
);