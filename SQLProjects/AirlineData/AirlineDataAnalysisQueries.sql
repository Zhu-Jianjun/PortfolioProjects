#Problems encountered when loading data
#aircrafts_data and airports_data, these two tables need to be manully creaated. 
#One more column (just for matching the data columns) needs to be added.
#Also, the column "coordinates" in airports_data has to be removed for now, gives error when loading.

#Also, one could convert .sqlite file to .sql file using https://github.com/majidalavizadeh/sqlite-to-mysql
#but, it gives some errors need to be fixed...


################################
#Queries:
#1 How many planes have more than 100 seats?
SELECT * FROM seats;
SELECT aircraft_code, COUNT(seat_no) AS number_seats FROM seats
GROUP BY aircraft_code
HAVING number_seats > 100;
#Problem: the last row is aircraft_code=0, number_seats=159.
#checking the data file, found that there are 3 diff. aircraft_code (i.e., CN1, CR2, SU9). After loading into mysql, they become 0 instead, and the total number if 159.
SHOW COLUMNS FROM seats; #found the data type of aircraft_code is INT, alter to VARCHAR(10)
ALTER TABLE seats
MODIFY aircraft_code VARCHAR(10);
#but the problem is still there, because all those rows (i.e., CN1, CR2, SU9) have already been changed to 0. 
#So, try to recreate this table with VARCHAR() data type for column aircraft_code and see,
#if not working properly, then deal with those rows in Excel would be easier. (It does work, see below).
SELECT * FROM seats_new WHERE aircraft_code = 'CN1';
SELECT aircraft_code, COUNT(seat_no) AS number_seats FROM seats_new
GROUP BY aircraft_code
HAVING number_seats > 100;


#2 Fare Distribution for the Flights
SELECT * FROM ticket_flights; #fare_conditions, amount
SELECT * FROM tickets; #none
SELECT * FROM flights; #aircraft_code

SELECT flights.aircraft_code, ticket_flights.fare_conditions, AVG(ticket_flights.amount) 
FROM ticket_flights
INNER JOIN flights
ON ticket_flights.flight_id = flights.flight_id
GROUP BY flights.aircraft_code, ticket_flights.fare_conditions;


#3 crafts info.
SELECT * FROM aircrafts_data; 

#but first, there are diff. languages in the column "model", just keep understandable one.
ALTER TABLE aircrafts_data
ADD COLUMN model_en VARCHAR(255) AFTER model; 

SET SQL_SAFE_UPDATES = 0; #To temporarily disable safe update mode for your current session: SET SQL_SAFE_UPDATES = 0; 
UPDATE aircrafts_data
SET model_en = (JSON_UNQUOTE(JSON_EXTRACT(model, '$.en')));
#Here's a breakdown of the path expression '$.en':
#The leading $ represents the root of the JSON object or array.
#The . (dot) is used to access the properties or elements of the JSON object or array.
#en is the key whose value needs to be extracted from the JSON object.
#So, '$.en' essentially means "extract the value associated with the 'en' key from the root of the JSON object".


-- (to be done...)
#4 Total revenue per year and the average revenue per ticket.
SELECT * FROM bookings ORDER BY book_date; #total_amount
SELECT COUNT(*) FROM bookings;
SELECT * FROM tickets;

select aircraft_code,ticket_count,total_revenue,total_revenue/ticket_count as avg_revenue_per_ticket from
                    (select aircraft_code, count(*) as ticket_count, sum(amount) as total_revenue from ticket_flights
                        join flights on ticket_flights.flight_id = flights.flight_id
                        group by aircraft_code) AS temp;


-- (to be done...)
#5 the average occupancy per aircraft
select a.aircraft_code,avg(a.seats_count) as booked_seats, b.num_seats, avg(a.seats_count)/b.num_seats as occupancy_rate from
                (select aircraft_code,flights.flight_id,count(*) as seats_count from boarding_passes
                    inner join flights
                    on boarding_passes.flight_id = flights.flight_id
                    group by aircraft_code,flights.flight_id) as a
                    inner join 
                    (select aircraft_code,count(*) as num_seats from seats
                    group by aircraft_code) as b
                    on a.aircraft_code = b.aircraft_code group by a.aircraft_code;
