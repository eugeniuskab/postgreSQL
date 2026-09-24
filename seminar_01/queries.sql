-- Active: 1790111772943@@127.0.0.1@5432@superstore@public
-- Uloha 2
select o.order_id, c.customer_name, o.sales

from orders o

inner join customers c on c.customer_id = o.customer_id

where o.sales > 500

order by o.sales desc;

-- Uloha 3
select o.order_id, c.customer_name, p.category, o.sales

from orders o

inner join customers c on c.customer_id = o.customer_id

inner join products p on p.product_id = o.product_id;

-- Uloha 4
select c.region, sum(o.sales) as total

from customers c

left join orders o on c.customer_id = o.customer_id

group by c.region;

-- Uloha 5
select p.product_id, p.product_name, sum(o.sales)

from products p

left join orders o on p.product_id = o.product_id

group by p.product_id, p.product_name;

-- Uloha 6
select c.customer_name, o.order_id, o.sales

from customers c

full outer join orders o c on c.customer_id = o.customer_id;

-- Uloha 7
select c.region, sum(o.sales)

from customers c

inner join orders o on c.customer_id = o.customer_id

group by c.region;

-- Uloha 8
select c.customer_name, count(o.order_id)

from customers c

left join orders o on c.customer_id = o.customer_id

group by c.customer_name;

-- Uloha 9
select p.category, avg(o.discount)

from products p

inner join orders o on o.product_id = p.product_id

group by p.category;

-- Uloha 10
select c.customer_name, sum(o.sales) as amount

from customers c

inner join orders o on c.customer_id = o.customer_id

group by c.customer_name

having sum(o.sales) > 2000;

-- Uloha 11
select c.region, sum(o.sales), avg(o.discount), count(o.order_id)

from customers c

inner join orders o on c.customer_id = o.customer_id

group by c.region;

-- Uloha 12
select c.region,

count(case when o.sales > 1000 then 1 end) as high_value_orders,

count(case when o.sales <= 1000 then 1 end) as low_value_orders

from customers c

inner join orders o on c.customer_id = o.customer_id

group by c.region;

-- Uloha 13
select c.customer_name, sum(o.sales), avg(o.discount), count(o.order_id),

case when sum(o.sales) > 2500 then 'VIP' else 'REGULAR' end as type

from customers c

inner join orders o on c.customer_id = o.customer_id

group by c.customer_name

order by sum(o.sales) desc;