-- set 1 - easy 
-- who is the senior most employee based on the job title?
select * from employee
order by levels desc 
limit 1


--Q2: WHICH COUNTRY HAVE THE MOST INVOICES ?
select count(*) as c,billing_country 
from invoice 
group by billing_country
order by c desc
limit 1

---Q3: WHAT ARE THREE TOP VALUES OF TOTAL INVOICES ?
SELECT total FROM INVOICE 
group by total 
order by total desc
limit 3

-- Q4:Which city has the best customers? We would like to throw a promotional Music Festival 
--    in the city  we made the most money.Write a query that returns one city that has the highest
--    sum of invoice totals.Return both the city name & sum of all invoice totals .
 select billing_city,sum(total) as invoice_totals from invoice
 group by billing_city 
order by invoice_totals  desc

--Q5:Who is the best customer? The customer who has spent the most money will be declared the 
---  best  customer .Write a query that returns the person who has spent the most money
 select c.customer_id,c.first_name,c.last_name ,sum(i.total) as total from customer as c
inner join invoice as i
on c.customer_id=i.customer_id 
group by c.customer_id 
order by total desc 
limit 1



-- MODERATE SET 
-- Q1:Write a query to return the email,first name, last name &genre of all rock music listeners .Return your list ordered 
-- alphabteically  by email starting with A .
 SELECT  DISTINCT email, first_name,last_name
FROM customer as c
 inner join invoice as i on c.customer_id=i.customer_id
inner  join invoice_line as l on i.invoice_id=l.invoice_id
where track_id in(
	select track_id from track
	join genre on track.genre_id=genre.genre_id
	where genre.name='Rock'
)
order by email asc
limit 5 

-- Q2: Let's invite the artists who have written the most rock music in our dataset.Write a query  that returns the artist name,
-- and total track count  of the top 10 rock bands.
select a.artist_id, a.name,count(a.artist_id)as total
from artist as a 
join album as al 
on a.artist_id=al.artist_id
where album_id in(
	select album_id from track
	join genre on track.genre_id=genre.genre_id
	where genre.name='Rock')
	group by a.artist_id
	order by total desc 
	limit 10
	
	--or  this one is same to you tube 
	select artist.artist_id, artist.name,count(artist.artist_id)as total
	from track 
	join album on album.album_id=track.album_id
	join artist on artist.artist_id=album.artist_id
	join genre on genre.genre_id=track.genre_id
	where genre.name like'Rock'
	group by artist.artist_id
	order by total desc 
	limit 10
	
	
	--Q3: Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds 
--    for each track. Order by the song length with the longest songs listed first.
      select milliseconds, name from track 
      where milliseconds >
      (select avg(milliseconds) from track)
       order by milliseconds desc
       limit 10


       ----SET3- ADVANCE ---
-- Q1: Find how much amount spent by each customer on artists? Write a query to return customer name , artist name and total 
-- spent .

with  best_selling_artist as
( select  artist.artist_id as artist_id,artist.name as artist_name,
 sum(invoice_line.unit_price*invoice_line.quantity)as total_sales 
 from invoice_line
join track on track.track_id=invoice_line.track_id
 join album on track.album_id=album.album_id
 join artist on album.artist_id=artist.artist_id
 group by artist.artist_id
 order by 3 desc
 limit 1	
)
select c.customer_id, c.first_name,c.last_name,bsa.artist_name ,
sum(il.unit_price*il.quantity) as amount_spent
from invoice as i
join customer as c on c.customer_id=i.customer_id 
join invoice_line as il on il.invoice_id=i.invoice_id
join track as t on  t.track_id=il.track_id
join album as a on a.album_id=t.album_id
join best_selling_artist as bsa on bsa.artist_id=a.artist_id
group by 1,2,3,4
order by 5 desc ;

--Q2:We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with 
--   the highest amount of purchases.Write a query that returns each country along with the top Genre. For countries where the
---  maximum number of purchses  is shared return all Genres.
With popular_genre as 
(
	Select count (invoice_line.quantity) as purchases,customer.country,genre.name ,genre.genre_id,
	ROW_Number() over(Partition by customer.country order By count( invoice_line.quantity) desc) as ROWno
	From invoice_line
	join invoice on invoice.invoice_id=invoice_line.invoice_id
	join customer on customer.customer_id=invoice.customer_id
	join track on track.track_id=invoice_line.track_id
	join genre on genre.genre_id=track.genre_id
	group by 2,3,4
	order by 2 asc,1 desc 
)
 Select * from popular_genre where ROWno<=1
 
 
 --- recursive method
 WITH RECURSIVE
	 sales_per_country AS (
		 select count(*) as purchases_per_genre,customer.country,genre.name,genre.genre_id
		 from invoice_line
		 join invoice on invoice.invoice_id=invoice_line.invoice_id 
		 join customer on customer.customer_id=invoice.customer_id
		 join track on track.track_id=invoice_line.track_id
		 join genre on genre.genre_id=track.genre_id
		 group by 2,3,4
		 order by 2
	 ),
	 max_genre_per_country as (select max(purchases_per_genre) as max_genre_number, country
				from sales_per_country
							   group by 2
							   order by 2 )
	
	select sales_per_country.*
	from sales_per_country 
	join max_genre_per_country on sales_per_country.country=max_genre_per_country.country
	where sales_per_country.purchases_per_genre=max_genre_per_country.max_genre_number 
	 
 


--Q3: Write a query that determines the customer that has spent the most on music for each country. Write a query that returns 
--    the country along with the top customer and how much they spent. For countries where the top amount spent is shared,
----  provide all customers who spent this amount .

with recursive 
customer_per_country as(
select c.customer_id, count(*)as purchase_as_country, c.first_name,c.last_name,c.country,
sum(il.unit_price*il.quantity) as amount_spent
from invoice_line as il 
join invoice as i on i.invoice_id= il.invoice_id 
join customer as c on c.customer_id=i.customer_id
group by 1,3,4,5
order by 5
 ),

max_amount_by_customer  as (
	select max(amount_spent)as max_amount_spent ,country 
	from customer_per_country 
	group by 2
	order by 2
)
select customer_per_country.*
from customer_per_country 
join max_amount_by_customer on customer_per_country.country=max_amount_by_customer.country
where customer_per_country.amount_spent=max_amount_by_customer.max_amount_spent 











	
	











