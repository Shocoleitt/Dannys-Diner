-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, sum(price) as total_amount_spent
FROM dannysdinerdb.menu as m
inner join dannysdinerdb.sales as s
using (product_id)
group by customer_id
;

/* How many days has each customer visited the restaurant?*/
select customer_id, count(distinct order_date) as number_of_days
from dannysdinerdb.sales 
group by customer_id
order by number_of_days desc
;

-- 3. What was the first item from the menu purchased by each customer?
with cte as (select s.customer_id, m.product_name, rank () over (partition by customer_id order by order_date) as rnk
from dannysdinerdb.sales  as s
inner join -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
.menu as m
using (product_id))
select customer_id, product_name
from cte
where rnk=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(m.product_name) as count
from dannysdinerdb.sales as s
inner join dannysdinerdb.menu as m
using (product_id)
group by m.product_name
order by count desc
limit 1
;

-- 5. Which item was the most popular for each customer?
select customer_id, product_name
from(select *, rank() over(partition  by customer_id order by count desc) as rnk
from
    (select distinct customer_id, product_name, count(product_name) over(partition by customer_id,product_name) as count
from dannysdinerdb.sales as s
inner join dannysdinerdb.menu as m
using (product_id)) as x) as z
where rnk=1
;
/* this is a very wrong approach and i 100% do not recommend as i also got confused and just tried to maneuver my way lol*/

/*6. Which item was purchased first by the customer after they became a member?*/
select s.customer_id, m.product_name
from dannysdinerdb.menu as m
inner join dannysdinerdb.sales as s
using (product_id)
inner join dannysdinerdb.members as y
using (customer_id)
where s.order_date> y.join_date
group by customer_id;

-- 7. Which item was purchased just before the customer became a member?
select s.customer_id, m.product_name
from dannysdinerdb.menu as m
inner join dannysdinerdb.sales as s
using (product_id)
inner join dannysdinerdb.members as y
using (customer_id)
where s.order_date< y.join_date
group by customer_id;


-- 8. What is the total items and amount spent for each member before they became a member?
select customer_id, count(product_name) as total_items , sum(price) as total_amnt_spent
from dannysdinerdb.menu as m
inner join dannysdinerdb.sales as s
using (product_id)
inner join dannysdinerdb.members as y
using (customer_id)
where s.order_date< y.join_date
group by customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id, sum(case when product_name = 'sushi' then m.price *10*2 
					else m.price * 10 end) as points 
from dannysdinerdb.sales as s
inner join dannysdinerdb.menu as m
using (product_id)
group by customer_id
; 


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH pointers AS (
	SELECT s.customer_id,
		   s.order_date,
		   m.join_date,
		   DATE_ADD(m.join_date, INTERVAL 7 DAY) AS week_after_join_date,
		   me.product_name,
		   me.price
	FROM dannysdinerdb.sales AS s
		 INNER JOIN dannysdinerdb.menu AS me
		 ON me.product_id = s.product_id
		 INNER JOIN dannysdinerdb.members AS m
		 ON m.customer_id = s.customer_id
)
SELECT customer_id,
	   SUM(CASE WHEN order_date BETWEEN m.join_date AND week_after_join_date THEN 2 * 10 * price
		    WHEN order_date NOT BETWEEN m.join_date AND week_after_join_date AND me.product_name = 'sushi' THEN 2 * 10 * price
            WHEN order_date NOT BETWEEN m.join_date AND week_after_join_date AND me.product_name != 'sushi' THEN 10 * price
            END) AS total_points
FROM pointers
WHERE MONTH(order_date) = 1
GROUP BY customer_id
ORDER BY customer_id;

-- Bonus Questions
select s.customer_id, s.order_date, m.product_name, m.price,
       CASE WHEN s.order_date < y.join_date THEN 'N'
			WHEN s.order_date >= y.join_date THEN 'Y'
            ELSE 'N' END AS member
from dannysdinerdb.sales as s
inner join dannysdinerdb.menu as m
using (product_id)
inner join dannysdinerdb.members as y
using (customer_id)
;


/*ranking all things*/

with cte as (select s.customer_id, s.order_date, m.product_name, m.price,
       CASE WHEN s.order_date < y.join_date THEN 'N'
			WHEN s.order_date >= y.join_date THEN 'Y'
            ELSE 'N' END AS member
from dannysdinerdb.sales as s
inner join dannysdinerdb.menu as m
using (product_id)
inner join dannysdinerdb.members as y
using (customer_id))

SELECT *,
	   CASE WHEN member = 'Y' THEN 
       RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
       END AS ranking
       from cte
;









