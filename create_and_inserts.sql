CREATE DATABASE task_13;

CREATE TABLE cinema_hall(
    id serial PRIMARY KEY,
    name varchar(10) NOT NULL
);
CREATE TABLE films(
    id serial PRIMARY KEY,
    duration int,
    name varchar(30) NOT NULL UNIQUE
);
--film + hall
CREATE TABLE seance(
    id serial PRIMARY KEY,
    film_id int NOT NULL REFERENCES films(id),
    cinema_hall_id int NOT NULL REFERENCES cinema_hall(id),
    begin_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone,
    price numeric NOT NULL CHECK ( price > 0 )
);
CREATE TABLE viewer(
    id serial PRIMARY KEY,
    name varchar(30) NOT NULL
);
--place + viewer
CREATE TABLE place_in_seance (
    id serial PRIMARY KEY,
    viewer_id int REFERENCES place(id) NOT NULL,
    seance_id int REFERENCES seance(id) NOT NULL,
    place_id int REFERENCES place(id) NOT NULL
);
CREATE TABLE place(
    id serial PRIMARY KEY,
    coords varchar (7),
    cinema_hall_id int NOT NULL REFERENCES cinema_hall(id)
);

INSERT INTO cinema_hall (name)
VALUES ('Hall1'),
       ('Hall2'),
       ('Hall4'),
       ('Hall5');

INSERT INTO films (duration, name) 
VALUES ('1:30 hour', 'Film1'),
       ('1:50 hour', 'Film2'),
       ('2:10 hour', 'Film3'),
       ('1:15 hour', 'Film4'),
       ('0:45 hour', 'Film5'),
       ('2:15 hour', 'Film6'),
       ('1:45 hour', 'Film7'),
       ('2:30 hour', 'Film8'),
       ('2:20 hour', 'Film9');

INSERT INTO viewer (name) 
VALUES ('Viewer1'),
       ('Viewer2'),
       ('Viewer3'),
       ('Viewer4'),
       ('Viewer5'),
       ('Viewer6'),
       ('Viewer7'),
       ('Viewer8'),
       ('Viewer9'),
       ('Viewer10'),
       ('Viewer11');

INSERT INTO place (coords, cinema_hall_id) 
VALUES ('1, 1', 1),
       ('1, 2', 1),
       ('1, 3', 1),
       ('1, 4', 1),
       ('1, 5', 1),
       ('2, 1', 2),
       ('2, 2', 2),
       ('2, 3', 2),
       ('2, 4', 2),
       ('2, 5', 2),
       ('3, 1', 3),
       ('3, 2', 3),
       ('3, 3', 3),
       ('3, 4', 3),
       ('3, 5', 3),
       ('4, 1', 4),
       ('4, 2', 4),
       ('4, 3', 4),
       ('4, 4', 4),
       ('4, 5', 4),
       ('4, 6', 4),
       ('4, 7', 4);

INSERT INTO place_in_seance (viewer_id, place_id, seance_id) 
VALUES (1, 6, 24),
       (2, 7, 24),
       (3, 8, 24),
       (4, 6, 32),
       (5, 7, 32),
       (6, 11, 71),
       (7, 9, 62),
       (8, 5, 65),
       (9, 4, 66),
       (11, 3, 67),
       (11, 12, 73),
       (1, 12, 74),
       (2, 12, 77),
       (1, 13, 77),
       (3, 14, 77),
       (5, 16, 93),
       (6, 17, 93),
       (7, 17, 94),
       (8, 18, 94),
       (8, 16, 97),
       (8, 18, 106),
       (8, 19, 106),
       (8, 16, 110),
       (8, 14, 89),
       (8, 11, 91),
       (8, 15, 82),
       (8, 15, 83),
       (8, 15, 84),
       (8, 15, 86),
       (8, 14, 86),
       (8, 14, 90),
       (8, 13, 90),
       (8, 11, 90);
