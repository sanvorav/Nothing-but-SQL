-- BASIC QUERIES --

/* Display each beer's name and style name regardless if the style name exist or not */
SELECT 
    b.beer_name AS BEER, 
    s.style_name AS STYLE
FROM beerdb.beers b 
LEFT JOIN  beerdb.styles s
    ON b.style_id = s.style_id
ORDER BY BEER;

/* Display the beer's name, category, color, and style for beers that have values for category, color, and style */
SELECT 
    b.beer_name AS BEER, 
    t.category_name AS CATEGORY,
    c.examples AS COLOR,
    s.style_name AS STYLE
FROM beerdb.beers b
INNER JOIN beerdb.styles s 
    USING(style_id)
INNER JOIN beerdb.categories t 
    ON b.cat_id = t.category_id
INNER JOIN beerdb.colors c 
    ON b.srm = c.lovibond_srm
ORDER BY BEER;

/* Display each brewer's name showing the min, max, and avg ABV of its beers. Exclude beers with an ABV of 0. Order by highest ABV first */

SELECT 
    bw.name AS BREWER_NAME, 
    MIN(br.abv) AS MIN_ABV, 
    MAX(br.abv) AS MAX_ABV, 
    AVG(br.abv) AS AVG_ABV
FROM beerdb.beers br
    LEFT JOIN beerdb.breweries bw 
    USING(brewery_id)
WHERE br.abv <> 0
GROUP BY bw.name
ORDER BY AVG_ABV DESC;

/* Which cities should be selected to host a microbrewery tour? To be considered, the city must have at least 10 breweries. Display the city's name and the number of breweries in each city. Order by highest number of breweries first. */

SELECT 
    bw.city, 
    COUNT(bw.brewery_id) AS NUM_BREWERS
FROM beerdb.breweries bw
WHERE bw.city IS NOT NULL
GROUP BY bw.city
HAVING COUNT(bw.name) >= 10
ORDER BY NUM_BREWERS DESC;

/* Display beers that have category "Lager" in the category name with an ABV greater than or equal to 8. Order by the beer name in alphabetical order. */

SELECT br.beer_name AS LAGERS_GTE8
FROM beerdb.beers br    
    LEFT JOIN beerdb.categories ct 
    ON br.cat_id = ct.category_id
WHERE ct.category_name LIKE '%Lager%'
    AND br.abv >= 8
ORDER BY LAGERS_GTE8;

-- INTERMEDIATE QUERIES --

/* Categorize the beers according to ABV values. "Very High" for ABV greater than 10. "High" for ABV of 6 to 10. "Average" for ABV of 3 to 6. "Low" for ABV less than 3. Display beer name and ABV strength. Order by beer name alphabetically. */

SELECT 
    b.beer_name, 
    b.abv,
    CASE 
        WHEN b.abv > 10 THEN 'VERY HIGH'
        WHEN b.abv >= 6 AND b.abv <= 10 THEN 'HIGH'
        WHEN b.abv >= 3 AND b.abv < 6 THEN 'AVERAGE'
        ELSE 'LOW' 
    END STRENGTH
FROM beerdb.beers b
ORDER BY b.beer_name;

/* A brewery specializes in a particular beer style if they produce at least 10 beers of that same style. Display the brewer's name, style name, and the number of beers of the specalized style. Order by beer count. */

SELECT 
    s.style_name AS STYLE_NAME, 
    br.name AS BREWER_NAME, 
    COUNT(s.style_name) STYLES_COUNT
FROM beerdb.beers b
    INNER JOIN beerdb.styles s
        USING(style_id)
    INNER JOIN beerdb.breweries br
        USING(brewery_id)
GROUP BY s.style_name, br.name
HAVING COUNT(s.style_name) >= 10
ORDER BY STYLES_COUNT DESC; 

/* Display each brewer’s name and how many beers they have associated with their brewery. Only include brewers that are located outside the United States and  more than the average number of beers from all breweries (excluding itself when calculating the average). Show the brewers with the most beers first. If there is a tie in number of beers, then sort by the brewers’ names. */

SELECT 
    brewery_name, 
    num_beers
FROM(
    SELECT brewery_name, num_beers,
    SUM (num_beers)
    OVER () AS tot_all,
    COUNT(brewery_name)
    OVER () AS tot_rows
    FROM (
        SELECT br.name AS brewery_name, COUNT(b.beer_name) AS num_beers
        FROM beerdb.beers b
        INNER JOIN beerdb.breweries br
        USING (brewery_id) 
        WHERE br.country <> 'United States'
        GROUP BY br.name
        )
)
WHERE num_beers > (tot_all - num_beers)/(tot_rows - 1)
ORDER BY num_beers DESC, brewery_name;

-- ADVANCED --

/* Assign breweries to groups based on the number of beers they brew. Display the brewery ID, name, number of beers they brew, and group number for each brewery. The group number should range from 1 to 4, with group 1 representing the top 25% of breweries (in terms of number of beers), group 2 representing the next 25% of breweries, group 3 the next 25%, and group 4 for the last 25%. Breweries with the most beers should be shown first. In the case of a tie, show breweries by brewery ID (lowest to highest). */

SELECT 
    br.brewery_id,
    br.name,
    Count(b.brewery_id) "# of beers", 
    ntile(4) over (order by  Count(b.brewery_id) desc) "group #"
FROM BEERDB.breweries br
INNER JOIN BEERDB.Beers b on br.brewery_id = b.brewery_id
GROUP BY br.brewery_id, br.name
Order by Count(b.brewery_id) desc, "group #", br.brewery_id;

/* Rank beers in descending order by their alcohol by volume (ABV) content. Only consider beers with an ABV greater than zero. Display the rank number, beer name, and ABV for all beers ranked 1-10. Do not leave any gaps in the ranking sequence when there are ties (e.g., 1, 2, 2, 2, 3, 4, 4, 5). */

SELECT 
    rownum as "1-10 rank",
    "beer rank" as "actual rank",
     beer_name
FROM(
    SELECT 
        Rank() over (order by b.abv desc) "beer rank",
        b.beer_name
    FROM BEERDB.Beers b
    WHERE b.abv > 0)
WHERE "beer rank" between 1 and 10;