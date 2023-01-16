--auto add end_date in seance (begin_date + film.duration)
CREATE OR REPLACE FUNCTION add_end_date() RETURNS TRIGGER
AS
$$
    DECLARE dur interval;
    DECLARE begin_d timestamp;
BEGIN
    SELECT duration into dur FROM films
        WHERE films.id = new.film_id;
    SELECT begin_date INTO begin_d FROM seance
        WHERE seance.id = new.id;  
    UPDATE seance SET end_date = begin_d + dur
        WHERE id = new.id;
    RETURN new;
end;
$$
LANGUAGE plpgsql;

--checks whether there will be a situation that the film is 
--playing in the same hall from 18:00 to 20:00, 
--and someone adds another film at 19:00 to 21:00
CREATE OR REPLACE FUNCTION check_time_available() RETURNS TRIGGER
AS 
    $$
    DECLARE c integer;
        dur interval;
        begin_d timestamp;
        end_d timestamp;
    BEGIN 
        SELECT duration INTO dur FROM films
        WHERE films.id = new.film_id;
        SELECT count(id) INTO c FROM seance
        WHERE cinema_hall_id = new.cinema_hall_id
        AND 
              new.begin_date BETWEEN begin_date AND end_date;
        IF c > 0 THEN
            SELECT begin_date,
                   end_date INTO begin_d, end_d FROM seance
            WHERE cinema_hall_id = new.cinema_hall_id
              AND
                new.begin_date BETWEEN begin_date AND begin_date + dur; 
            RAISE EXCEPTION 
                'There is already a film going on. Hall: % begin: %, end: %. You add begin date: %',new.cinema_hall_id, begin_d, end_d, new.begin_date;
        END IF;
        IF extract(hour from new.begin_date + dur) > 23 THEN
            RAISE EXCEPTION 'The cinema is closed during this time: %!', new.begin_date + dur;
        end if;
        RETURN new;
    end;
    $$
LANGUAGE plpgsql;

--auto add end date
CREATE TRIGGER set_end_date AFTER INSERT ON seance
    FOR EACH ROW EXECUTE FUNCTION add_end_date();
--check available time
CREATE TRIGGER check_time BEFORE INSERT ON seance
    FOR EACH ROW EXECUTE FUNCTION check_time_available();
DROP TRIGGER set_end_date ON seance;

--auto insert film in available time (after last film)
CREATE OR REPLACE PROCEDURE add_film(hall_id integer, film_id integer, begin_day date)
AS 
    $$
    DECLARE dur interval;
        last_film_end_date timestamp;
        break interval = '10 min';
        price numeric = 10;
    begin 
        SELECT duration INTO dur FROM films
            WHERE films.id = film_id; 
        SELECT end_date INTO last_film_end_date
            FROM seance WHERE extract(day from end_date) = extract(day from begin_day)
            AND seance.cinema_hall_id = hall_id
            ORDER BY end_date DESC LIMIT 1;
        IF last_film_end_date IS NULL THEN
            last_film_end_date = begin_day::timestamp + interval '16 hours';
        end if;
        last_film_end_date = last_film_end_date + break;
        IF extract(hour from last_film_end_date) < 16 THEN
            last_film_end_date = last_film_end_date + interval '15:50 hours';
        end if;
        IF 
            extract(hour from last_film_end_date + dur) > 23 THEN
            RAISE 'The cinema is closed during this time: %!', last_film_end_date + dur;
        end if;
        SELECT floor(random() * 150)::numeric + 50 INTO price;
        INSERT INTO seance (film_id, cinema_hall_id, begin_date, price)
            VALUES (film_id, hall_id, last_film_end_date, price);
    end;
    $$
LANGUAGE plpgsql;
--call this with hall_id[1, 4], film_id[7, 14], begin_day[2023-01-14, 2023-01-17]
CALL add_film(4, 13, '2023-01-17');

--before insert check place.cinema_hall_id must be equal seance.cinema_hall_id
--this is necessary so that it does not happen that the user has 
--booked a seat in hall 1, and the session takes place in another hall
CREATE OR REPLACE FUNCTION check_correct_place() RETURNS TRIGGER
AS 
    $$
    DECLARE place_hall_id integer;
        seance_in_hall_id integer;
    BEGIN 
        SELECT place.cinema_hall_id INTO place_hall_id FROM place
            WHERE place.id = new.place_id;
        SELECT cinema_hall_id INTO seance_in_hall_id FROM seance
            WHERE seance.id = new.seance_id; 
        IF place_hall_id != seance_in_hall_id THEN
            RAISE EXCEPTION 'This place in hall: %, but seance in hall: %', place_hall_id, seance_in_hall_id;
        end if;
        RETURN new;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER check_correct_place BEFORE INSERT ON place_in_seance
FOR EACH ROW EXECUTE FUNCTION check_correct_place();