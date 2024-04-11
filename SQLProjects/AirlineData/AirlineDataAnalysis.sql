#Problems encountered when loading data
#aircrafts_data and airports_data, these two tables need to be manully creaated. 
#One more column (just for matching the data columns) needs to be added.
#Also, the column "coordinates" in airports_data has to be removed for now, gives error when loading.

#Also, one could convert .sqlite file to .sql file using https://github.com/majidalavizadeh/sqlite-to-mysql
#but, it gives some errors need to be fixed...


USE AirlineDataAnalysis;

################################
#https://www.kaggle.com/code/prashantverma13/airline-data-analysis-using-sql/notebook
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



#4 Total revenue per year and the average revenue per ticket.
SELECT * FROM bookings ORDER BY book_date; #total_amount, book_date
SELECT * FROM tickets;
SELECT * FROM flights; #aircraft_code
SELECT * FROM ticket_flights;
/*
by exploring, 
	tickets can be joined w/ bookings on book_ref;
    tickets can be joined w/ ticket_flights on ticket_no;
    ticket_flights can be joined w/ flights on flight_id;
s.t these 4 tables can be joined together.
*/

SELECT
	flights.aircraft_code,
    COUNT(*) AS ticket_count,
    SUM(ticket_flights.amount) AS total_revenue,
    SUM(ticket_flights.amount) / COUNT(*) AS avg_revenue_per_ticket
FROM tickets
INNER JOIN bookings
	ON tickets.book_ref = bookings.book_ref
INNER JOIN ticket_flights
	ON tickets.ticket_no = ticket_flights.ticket_no
INNER JOIN flights
	ON ticket_flights.flight_id = flights.flight_id
GROUP BY flights.aircraft_code
ORDER BY avg_revenue_per_ticket;
    



#5 the average occupancy per aircraft
SELECT * FROM flights; #aircraft_code
SELECT * FROM boarding_passes;
SELECT * FROM seats_new; #aircraft_code


SELECT
    f.aircraft_code,
    AVG(bp.seats_count) AS average_booked_seats,
    s.total_seats,
    (AVG(bp.seats_count) / s.total_seats) AS average_occupancy_rate
FROM
    (
        SELECT
            flight_id,
            COUNT(*) AS seats_count
        FROM
            boarding_passes
        GROUP BY flight_id
    ) AS bp
INNER JOIN flights AS f 
ON bp.flight_id = f.flight_id
INNER JOIN
    (
        SELECT
            aircraft_code,
            COUNT(*) AS total_seats
        FROM
            seats_new
        GROUP BY aircraft_code
    ) AS s 
ON f.aircraft_code = s.aircraft_code
GROUP BY f.aircraft_code;



