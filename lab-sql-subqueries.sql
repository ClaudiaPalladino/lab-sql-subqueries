-- Challenge
-- using the Sakila database:
USE sakila;

-- Determine the number of copies of the film "Hunchback Impossible" that exist in the inventory system.
SELECT title,
	COUNT(*) AS copies   -- when counting rows that match a condition, normally use COUNT(*) with a WHERE clause.
FROM film
INNER JOIN inventory
	ON film.film_id = inventory.film_id
WHERE film.title = 'Hunchback Impossible' 
GROUP BY film.title;

-- List all films whose length is longer than the average length of all the films in the Sakila database.
SELECT  title, length
FROM film
WHERE length > (
	SELECT AVG(length)
    FROM film
);

-- Use a subquery to display all actors who appear in the film "Alone Trip".
SELECT actor.first_name, actor.last_name, film.title
FROM actor
INNER JOIN film_actor   -- joins actors to the films they appear in.
	ON actor.actor_id = film_actor.actor_id
INNER JOIN film  -- this join retrieves the titles
	ON film_actor.film_id = film.film_id
WHERE film.title = 'Alone Trip'  -- limits results to that movie.
    ;


-- Bonus:
-- Identify all movies categorized as family films.
SELECT film.title
FROM film
INNER JOIN film_category
	ON film.film_id = film_category.film_id
INNER JOIN category
	ON film_category.category_id = category.category_id
WHERE category.`name` = 'Family';  -- limits results to that category.
    
-- Alternative approach
SELECT film.title
FROM film
JOIN film_category USING (film_id)
JOIN category USING (category_id)
WHERE category.name = 'Family'
ORDER BY film.title;


-- Retrieve the name and email of customers from Canada using both subqueries and joins.
-- To use joins, you will need to identify the relevant tables and their primary and foreign keys.
-- * TAB customer : customer_id , first_name , last_name , email  , address_id (FK)
-- * TAB address : address_id (PK) ,  city_id (FK)
-- * TAB city :  city_id (PK) , country_id (FK)
-- * TAB country :  country_id (PK) , country

SELECT c.first_name , c.last_name , c.email
FROM customer c
JOIN address a						-- the joins (customer → address → city → country) are the outer query, which uses the result of the subquery to filter customers
	ON c.address_id = a.address_id
JOIN city ci
	ON a.city_id = ci.city_id
JOIN country co
	ON ci.country_id = co.country_id
WHERE co.country_id = (             -- the subquery is contained in the WHERE clause, it finds country_id for 'Canada' from the country tab.
	SELECT co2.country_id
	FROM country co2
    WHERE co2.country = 'Canada'
) ;

-- Alternative approach using joins only:
SELECT customer.first_name, customer.last_name, customer.email
FROM customer
JOIN address
    ON customer.address_id = address.address_id
JOIN city
    ON address.city_id = city.city_id
JOIN country
    ON city.country_id = country.country_id
WHERE country.country = 'Canada';

-- Determine which films were starred by the most prolific actor in the Sakila database.
-- A prolific actor is defined as the actor who has acted in the most number of films.
-- First, you will need to find the most prolific actor and then use that actor_id to find the different films that he or she starred in.
SELECT f.title, a.first_name, a.last_name
FROM film f
INNER JOIN film_actor fa  -- the joins (film → film_actor → actor) return all films that actor appeared in
	ON f.film_id = fa.film_id
INNER JOIN actor a 
	ON fa.actor_id = a.actor_id
WHERE a.actor_id = (
	SELECT a2.actor_id
    FROM actor a2
    INNER JOIN film_actor fa2
		ON a2.actor_id  = fa2.actor_id
	GROUP BY a2.actor_id
	ORDER BY COUNT(DISTINCT fa2.film_id) DESC  -- counts how many unique films each actor acted in, picks the actor with the most films.
	LIMIT 1
)
ORDER BY f.title;


-- Find the films rented by the most profitable customer in the Sakila database.
-- You can use the customer and payment tables to find the most profitable customer,
-- i.e., the customer who has made the largest sum of payments.

SELECT f.title AS film_title, c.first_name, c.last_name, c.customer_id  -- find the films rented by the most profitable customer
FROM film f
INNER JOIN inventory i
    ON f.film_id = i.film_id
INNER JOIN rental r
    ON i.inventory_id = r.inventory_id
INNER JOIN customer c
    ON r.customer_id = c.customer_id
WHERE c.customer_id = (     -- subquery finds the most profitable customer, computes tot payments for each customer SUM
	SELECT c2.customer_id 
	FROM customer c2
	INNER JOIN payment p
		ON c2.customer_id = p.customer_id
	GROUP BY c2.customer_id
	ORDER BY SUM(p.amount) DESC
	LIMIT 1
);


-- Retrieve the client_id and the total_amount_spent of those clients who spent more than the average of the total_amount spent by each client.
-- You can use subqueries to accomplish this.
SELECT c.customer_id,
       SUM(p.amount) AS tot_amount
FROM customer c
INNER JOIN payment p
    ON c.customer_id = p.customer_id
GROUP BY c.customer_id
HAVING SUM(p.amount) > (         -- filters customers spending above the mean
    SELECT AVG(customer_total)   -- subquery: computes mean total amount spent by all customers
    FROM (
        SELECT SUM(p2.amount) AS customer_total
        FROM customer c2
        INNER JOIN payment p2
            ON c2.customer_id = p2.customer_id
        GROUP BY c2.customer_id
    ) AS totals
);
