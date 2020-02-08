-- BASIC QUERIES --

/* Display movies that have an IMDB rating of at least 8 that was released in 2007 to 2013. Include only movies with more than 100k votes. Sort by highest ratings first. */

SELECT m.film_title
FROM relmdb.movies m
WHERE m.imdb_rating >= 8 
    AND m.imdb_votes > 100000 
    AND (EXTRACT(YEAR FROM m.release_date) BETWEEN 2007 AND 2013)
ORDER BY m.imdb_rating DESC;

/* Display movie and its total gross (where total gross is USA gross and worldwide gross combined). Exclude movies that do not have values for either USA or worldwide gross. Order by highest gross first. */

SELECT 
    m.film_title, 
    SUM(m.worldwide_gross + m.usa_gross) AS total_gross
FROM relmdb.movies m
WHERE m.worldwide_gross IS NOT NULL 
    AND m.usa_gross IS NOT NULL 
GROUP BY m.film_title
ORDER BY total_gross DESC;

/* In which movies did Tom Hanks and Tim Allen were cast members? (Show each movie title only once). */

SELECT DISTINCT film_title
FROM RELMDB.movies m
INNER JOIN RELMDB.casts c
    ON m.film_id = c.film_id
WHERE c.cast_member LIKE '%Tom Hanks%'
    OR c.cast_member LIKE '%Tim Allen%';

/* Count the number of movies in each MPAA rating (G, PG, PG-13, R). Order by MPAA rating in alphabetical order. */

SELECT m.mpaa_rating, COUNT(m.mpaa_rating)
FROM relmdb.movies m
WHERE m.mpaa_rating IN ('G', 'PG', 'PG-13', 'R')
GROUP BY m.mpaa_rating
ORDER BY m.mpaa_rating;

/* For each movie display its movie title, year, and how many cast members were a part of the movie. Exclude movies with five or fewer cast members. Display movies with the most cast members first, followed by movie year and title. */

SELECT 
    m.film_title, 
    m.film_year, 
    COUNT(c.cast_member) NUM_CAST
FROM relmdb.movies m
    INNER JOIN relmdb.casts c
    USING(film_id)
HAVING COUNT(c.cast_member) > 5
GROUP BY m.film_title, m.film_year
ORDER BY NUM_CAST DESC, m.film_year, m.film_title;

-- INTERMEDIATE QUERIES --

/* For each genre display the total number of films, average fan rating, and average USA gross. A genre should only be shown if it has at least five films. Any film without a USA gross should be excluded. A film should be included regardless of whether any fans have rated the film. Show the results by genre. */

SELECT genre, COUNT(*) AS tot_films, avg_fan_rating, avg_usa_gross
FROM(
SELECT LOWER(LTRIM(RTRIM(g.genre))) AS genre,
    ROUND(AVG(f.imdb_rating)
    OVER(PARTITION BY LOWER(LTRIM(RTRIM(g.genre)))),2) AS avg_fan_rating,
    ROUND(AVG(m.usa_gross)
    OVER(PARTITION BY LOWER(LTRIM(RTRIM(g.genre)))),2) AS avg_usa_gross
FROM relmdb.movies m
    INNER JOIN relmdb.genres g
    USING(film_id)
    INNER JOIN relmdb.fan_ratings f
    USING(film_id))
WHERE avg_usa_gross IS NOT NULL
GROUP BY genre, avg_fan_rating, avg_usa_gross
ORDER BY genre;

/* Find the average budget for all films from a director with at least one movie in the top 25 IMDB ranked films. Show the director with the highest average budget first. */

SELECT d.director, ROUND(AVG (budget)) AS avg_budget
FROM relmdb.movies m
    INNER JOIN relmdb.directors d
    USING (film_id)
WHERE d.director 
    IN 
    (SELECT d.director
    FROM relmdb.movies m
    INNER JOIN relmdb.directors d
    USING (film_id)
    WHERE m.imdb_rank <= 25)
GROUP BY d.director
ORDER BY avg_budget DESC;

/* Find all duplicate fans. A fan is considered duplicate if they have the same first name, last name, city, state, zip, and birth date. */

SELECT fname, lname, city, state, zip, birth_day, birth_month, birth_year
FROM relmdb.fans f
GROUP BY fname, lname, city, state, zip, birth_day, birth_month, birth_year
HAVING COUNT(*) > 1;

/* We believe there may be erroneous data in the movie database. To help uncover unusual records for manual review, write a query that finds all actors/actresses with a career spanning 60 years or more. Display each actor's name, how many films they worked on, the year of the earliest and latest film they worked on, and the number of years the actor was active in the film industry (assume all years between the first and last film were active years). Display actors with the longest career first. */

SELECT c.cast_member, COUNT(m.film_title) AS num_films, MAX(m.film_year) AS last_film, MIN(m.film_year) AS first_film, MAX(m.film_year) - MIN(m.film_year) AS active_years
FROM relmdb.movies m
INNER JOIN relmdb.casts c
USING(film_id)
GROUP BY c.cast_member
HAVING MAX(m.film_year) - MIN(m.film_year) >= 60
ORDER BY active_years DESC;

/* The movies database has two tables that contain data on fans (FANS_OLD and FANS). Due to a bug in our application, fans may have been entered into the old fans table rather then the new table. Find all fans that exist in the old fans table but not the new table. Use only the first and last name when comparing fans between the two tables. */

(SELECT fname, lname
FROM relmdb.fans_old)
MINUS
(SELECT fname, lname
FROM relmdb.fans);

-- ADVANCED --

/* Display the film title, film year and worldwide gross for all movies directed by Christopher Nolan that have a worldwide gross greater than zero. In addition, each row should contain the cumulative worldwide gross (current row's worldwide gross plus the sum of all previous rows' worldwide gross). Records should be sorted in ascending order by film year. */

SELECT m.film_title, m.film_year, m.worldwide_gross, 
    SUM(m.worldwide_gross) 
    OVER(ORDER BY m.film_year
         ROWS BETWEEN UNBOUNDED PRECEDING 
         AND CURRENT ROW) cum_sum
FROM relmdb.movies m
    INNER JOIN relmdb.directors d
    USING(film_id)
WHERE d.director IN 'Christopher Nolan' AND m.worldwide_gross > 0
ORDER BY m.film_year;