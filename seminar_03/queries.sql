-- Active: 1791307290836@@127.0.0.1@5432@retail_sales@public
-- Uloha 1
create view high_value_customers AS
select c.customer_id, c.customer_name, sum(o.sales) as total_sales
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name
having sum(o.sales) > 2000;
select * from high_value_customers;

-- Uloha 2
create view regional_monthly_sales AS
select c.region, date_trunc('month', o.order_date) as month, sum(o.sales) as monthly_sales
from customers c
join orders o on c.customer_id = o.customer_id
group by c.region, date_trunc('month', o.order_date);
select * from regional_monthly_sales
where region = 'West';

-- Uloha 3
create view analyst_order AS
select order_id, customer_id, product_id, sales, quantity, discount
from orders;

-- Uloha 4
create index idx_orders_customer_id on orders (customer_id);
select * from orders
where customer_id = 'C001';

-- Uloha 5
create index idx_orders_order_date on orders (order_date);
select date_trunc('month', order_date) as month, sum(sales)
from orders
group by date_trunc('month', order_date)
order by sum(sales) asc;

-- Uloha 6
create index idx_orders_region_category on orders (customer_id, order_date);
select c.customer_id, c.customer_name, c.region, o.order_id, o.order_date, o.profit
from orders o
join customers c on c.customer_id = o.customer_id
where c.region = 'West'
and o.order_date >= '2024-01-01';

-- Uloha 7
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 'C001';

-- Uloha 8
ALTER DATABASE retail_sales SET datestyle TO 'ISO, MDY';

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    region VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ship_mode VARCHAR(30) NOT NULL,
    sales NUMERIC(10, 2) NOT NULL,
    profit NUMERIC(10, 2) NOT NULL
);

SELECT *
FROM orders;

-- Uloha 9
create procedure get_customer_sales(p_customer_id VARCHAR)
language plpgsql
as $$
declare v_total_sales numeric(10,2);
begin
select coalesce(sum(sales), 0)
into v_total_sales
from orders
where customer_id = p_customer_id;
raise notice 'Customer: %, Total Sales: %', p_customer_id, v_total_sales;
end;
$$;

call get_customer_sales('C001');

-- Uloha 10
create procedure apply_regional_discount(region_name VARCHAR, discount_rate NUMERIC)
language plpgsql
as $$
begin
update orders
set sales = round(sales * (1 - discount_rate), 2)
where region = region_name;
raise notice 'Aplikovana zlava % pre region %', discount_rate, region_name;
end;
$$;

call apply_regional_discount('West', 0.2);

-- Uloha 11
create procedure get_sales_between(start_date DATE, end_date DATE)
language plpgsql
as $$
declare v_total_sales numeric(10,2);
begin
select coalesce(sum(sales), 0)
into v_total_sales
from orders
where order_date >= start_date and order_date <= end_date;
raise notice 'Total sales from % until % : %', start_date, end_date, v_total_sales;
end;
$$;

call get_sales_between('2024-01-01','2024-03-31');