-- Active: 1791897506187@@127.0.0.1@5432@retail@public
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