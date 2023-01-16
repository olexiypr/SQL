--Select all the showtimes for the current week, including movie name, date and time of the
--show.
SELECT f.name,
       to_char(begin_date, 'DayHH24:MI')
FROM seance
JOIN films f on f.id = seance.film_id
WHERE extract(week from begin_date) = extract(week from current_date);

CREATE OR REPLACE FUNCTION get_free_places_by_seance_id (s_id integer)
RETURNS table 
    (id int,
     coords varchar(7))        
    AS 
    $$
    begin
        RETURN QUERY (SELECT place.id,
               place.coords FROM place
        JOIN seance s on place.cinema_hall_id = s.cinema_hall_id
        WHERE s.id = s_id
        EXCEPT
        SELECT place.id,
               place.coords FROM place
        JOIN place_in_seance pis on place.id = pis.place_id
        WHERE pis.seance_id = s_id);
    end;
    $$
LANGUAGE plpgsql;
--Select all available seats for the specific seance
SELECT * FROM get_free_places_by_seance_id(32);

--Find seats which were never booked
SELECT id,
       coords,
       cinema_hall_id
FROM place
WHERE id NOT IN (SELECT place_id FROM place_in_seance);

--Calculate all the money earned by each movie and display in descending order along with
--movies names.
SELECT sum(price) sm,
       f.name
FROM place_in_seance
JOIN seance s on s.id = place_in_seance.seance_id
JOIN films f on f.id = s.film_id
GROUP BY f.name
ORDER BY sm;

CREATE OR REPLACE FUNCTION get_max_amount(b date, e date) RETURNS 
table (sm numeric, viewer_id integer)
AS 
    $$
    begin 
        RETURN QUERY
            SELECT sum(price) sm,
                   pis.viewer_id
            FROM viewer
                     JOIN place_in_seance pis on viewer.id = pis.viewer_id
                     JOIN seance s on s.id = pis.seance_id
            WHERE begin_date BETWEEN b AND e
            GROUP BY pis.viewer_id
            ORDER BY sm DESC
            LIMIT 3;
    end;
    $$
LANGUAGE plpgsql;
--Show top 3 users, who spent most money in the specified dates interval
SELECT * FROM get_max_amount('2023-01-15 16:00', '2023-01-16 23:00');

CREATE OR REPLACE FUNCTION get_halls_with_less_viewers(b timestamp without time zone, e timestamp without time zone) RETURNS 
table(id int,
    name varchar(30),
    count bigint)
AS 
$$
begin 
    RETURN QUERY
        SELECT ch.id,
               ch.name,
               count(place_in_seance.viewer_id)
        FROM place_in_seance
                 JOIN place p on p.id = place_in_seance.place_id
                 JOIN cinema_hall ch on ch.id = p.cinema_hall_id
                 JOIN seance s on s.id = place_in_seance.seance_id
        WHERE s.begin_date BETWEEN b
                  AND
                  e
        GROUP BY ch.id;
end;
$$
LANGUAGE plpgsql;
-- Find cinema halls, which received less visitors in the last week than in this week
SELECT * 
FROM get_halls_with_less_viewers
    (date_trunc('week', current_date)::timestamp without time zone, 
    date_trunc('week', current_date + interval '1 weeks'):: timestamp without time zone) af
JOIN 
(SELECT *
FROM get_halls_with_less_viewers
    (date_trunc('week', current_date - interval '1 weeks')::timestamp without time zone,
     date_trunc('week', current_date):: timestamp without time zone)) be ON be.id = af.id
WHERE af.count < be.count
