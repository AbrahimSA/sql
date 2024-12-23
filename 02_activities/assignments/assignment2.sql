
/* ASSIGNMENT 2 */
/* SECTION 1 */
Diagram of bookstore you can find on the following path  02_activities\assignments\images\bookstore-diagram.jpg

/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT  COALESCE(product_name,'') || ', ' || COALESCE(product_size,'')|| ' (' || COALESCE(product_qty_type,'') || ')'
FROM product

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT  DISTINCT customer_id,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date) AS customer_visit,
market_date
FROM customer_purchases


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT customer_id, market_date 
FROM (
SELECT  DISTINCT customer_id,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS customer_visit,
market_date
FROM customer_purchases) x
WHERE customer_visit = 1


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

-- This query is returning how many different times that customer has purchased that product_id without inform the date and only one row per customer_id and product_id
SELECT distinct customer_id, product_id,  count() OVER (PARTITION BY customer_id, product_id) times_purchased
FROM customer_purchases 

-- Related of comment "Missing transaction time, output also not sorted", sorry I think this is what you are looking for.
-- This query is returning how many different times that customer has purchased one product showing all rows on the table showing also market_date
SELECT 
    customer_id,
    product_id,
    market_date,
    COUNT(market_date) OVER (PARTITION BY customer_id, product_id) AS purchase_count
FROM 
    customer_purchases;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
SELECT product_name, 
CASE WHEN trim(substr(product_name, INSTR(product_name,'-')+2)) IN ('Organic','Jar') THEN trim(substr(product_name, INSTR(product_name,'-')+2))  ELSE NULL END  description
FROM product

-- Ernani, I am not usre if I understood your request(Try making it without the product names or partially product names. The question asks with a very specific),  I am sharing a new query below
SELECT 
    product_name,
    TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 2)) AS product_description,
FROM product
WHERE INSTR(product_name, '-') > 0;

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT product_name, product_size
 FROM product
 WHERE product_size REGEXP '[0-9]' = 1

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

SELECT * FROM (SELECT market_date, SUM(quantity * cost_to_customer_per_qty ) total_sales
FROM customer_purchases 
GROUP BY market_date
ORDER BY total_sales
LIMIT 1) x
UNION 
SELECT * FROM (
SELECT market_date, SUM(quantity * cost_to_customer_per_qty ) total_sales
FROM customer_purchases 
GROUP BY market_date
ORDER BY total_sales DESC
LIMIT 1 ) y


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

-- Sorry, it is a litter confised this question, since you did not talked about which value from vendor_inventory I should consider I am using the most recent value

 SELECT
    v.vendor_name,
    v.product_name,
    v.price * 5 * c.customer_count AS total_price
FROM 
    -- Subquery for vendors and products
    (SELECT v.vendor_name, p.product_name, i.original_price price
		FROM vendor v 
		INNER JOIN vendor_inventory i ON (v.vendor_id = i.vendor_id) 
		INNER JOIN (SELECT product_id, vendor_id, max(market_date) market_date
					FROM vendor_inventory
					GROUP BY product_id, vendor_id) g ON ( i.product_id = g.product_id AND i.vendor_id = g.vendor_id AND i.market_date = g.market_date )
		INNER JOIN product p ON (i.product_id = p.product_id)
		GROUP BY v.vendor_name, p.product_name
	 ) v
CROSS JOIN 
    -- Subquery for the number of customers
    (SELECT COUNT(customer_id) AS customer_count
     FROM customer) c
ORDER BY 
    v.vendor_name, v.product_name;	

-- Ernani, related of "The result seems not resoanable. Based on your question about understanding the question you can try it without counting customers and grouping by after the CROSS JOIN. You ay think it visually.", 
-- I am not sure if it is you are looking for, but this case I will calculate data from every single line from vendor_inventory table; The same same product will be considerer many times.
SELECT 
    v.vendor_name,
    p.product_name,
    SUM(5 * vi.original_price * c.customer_count ) AS price
FROM vendor v
JOIN vendor_inventory vi ON v.vendor_id = vi.vendor_id
JOIN product p ON vi.product_id = p.product_id
CROSS JOIN 
    (SELECT COUNT(customer_id) AS customer_count FROM customer) c
GROUP BY 
    v.vendor_name, p.product_name


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

CREATE TABLE product_units AS
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp FROM product WHERE product_qty_type = 'unit'

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

-- Ernani,  related your comment "Seens like you added a product that doesn't exist in the products table ("Pasture-raised eggs") and the DELETE clause won't work for the older same product. Please review it."
-- Yes I added a new product that does not exist because the information above is saying "can be any product you desire", it is not saying any product from product table
--

-- This query is related of one product from product that product_qty_type != 'unit'
SELECT product_id, product_name, product_size, product_category_id,product_qty_type, CURRENT_TIMESTAMP
FROM product
WHERE product_qty_type != 'unit'
LIMIT 1

-- This query is from one new product
INSERT INTO product_units 
(product_id, product_name, product_size, product_category_id,product_qty_type, snapshot_timestamp)
Values (56, 'Pasture-raised eggs', '1 dozen',6,'unit',CURRENT_TIMESTAMP)


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units WHERE product_id = (SELECT product_id FROM product_units  ORDER BY snapshot_timestamp  LIMIT 1)


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

-- Note: Since the vendor_inventory could have more than one product_id from the last market_date because vendor_id is part of primary key, I am using MAX of quatity, 
-- but I could use SUM function to get total of quatity from the last day for each product. I am not sure exaclty what you are looking for.

-- Ernani I did not include the ALTER TABLE product_units ADD current_quantity INT; because the command was informed on 02_activities\assignments\Assignment2.md file
-- Related of your comment: "you have two UPDATE clauses with some issues (check if ";" is important too) and check why your result is resulting in 0 (zero)"
-- Sorry, I am not sure what happened I shared the wrong query, please considere this one.
 
UPDATE product_units
SET current_quantity = coalesce ((
    SELECT vi.quantity
    FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id
    ORDER BY vi.market_date DESC
    LIMIT 1
),0);


 