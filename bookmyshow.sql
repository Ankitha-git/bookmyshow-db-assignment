-- ============================================================
-- BookMyShow Database Schema
-- Normalized to 1NF, 2NF, 3NF, and BCNF
-- Compatible with MySQL
-- ============================================================

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS show_timings;
DROP TABLE IF EXISTS shows;
DROP TABLE IF EXISTS screens;
DROP TABLE IF EXISTS theatres;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS languages;
DROP TABLE IF EXISTS formats;
DROP TABLE IF EXISTS cities;

-- ============================================================
-- LOOKUP / REFERENCE TABLES
-- ============================================================

-- Table: cities
-- Stores city information (extracted to avoid transitive dependency)
CREATE TABLE cities (
    city_id     INT AUTO_INCREMENT PRIMARY KEY,
    city_name   VARCHAR(100) NOT NULL,
    state       VARCHAR(100) NOT NULL,
    country     VARCHAR(100) NOT NULL DEFAULT 'India'
);

-- Table: languages
-- Stores available languages (avoids repeating language strings in movies/shows)
CREATE TABLE languages (
    language_id   INT AUTO_INCREMENT PRIMARY KEY,
    language_name VARCHAR(50) NOT NULL UNIQUE
);

-- Table: formats
-- Stores projection formats like 2D, 3D, IMAX, 4DX
CREATE TABLE formats (
    format_id   INT AUTO_INCREMENT PRIMARY KEY,
    format_name VARCHAR(20) NOT NULL UNIQUE  -- e.g., '2D', '3D', 'IMAX 3D'
);

-- ============================================================
-- CORE ENTITY TABLES
-- ============================================================

-- Table: movies
-- Stores movie master data
-- 1NF: All attributes are atomic
-- 2NF: All non-key attributes depend on movie_id (no partial deps)
-- 3NF/BCNF: language_id is FK (no transitive dep on movie_id)
CREATE TABLE movies (
    movie_id        INT AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    language_id     INT          NOT NULL,
    duration_mins   INT          NOT NULL,  -- runtime in minutes
    genre           VARCHAR(100),
    release_date    DATE,
    rating          VARCHAR(10),            -- UA, A, U
    description     TEXT,
    CONSTRAINT fk_movie_language FOREIGN KEY (language_id) REFERENCES languages(language_id)
);

-- Table: theatres
-- Stores theatre/cinema hall information
-- city_id FK avoids storing city/state/country repeatedly (3NF)
CREATE TABLE theatres (
    theatre_id      INT AUTO_INCREMENT PRIMARY KEY,
    theatre_name    VARCHAR(200) NOT NULL,
    address_line1   VARCHAR(255) NOT NULL,
    address_line2   VARCHAR(255),
    city_id         INT          NOT NULL,
    pincode         VARCHAR(10),
    contact_number  VARCHAR(15),
    CONSTRAINT fk_theatre_city FOREIGN KEY (city_id) REFERENCES cities(city_id)
);

-- Table: screens
-- Each theatre can have multiple screens
-- Separating screen from theatre satisfies 2NF (capacity depends on screen, not theatre)
CREATE TABLE screens (
    screen_id       INT AUTO_INCREMENT PRIMARY KEY,
    theatre_id      INT          NOT NULL,
    screen_name     VARCHAR(50)  NOT NULL,   -- e.g., 'Screen 1', 'Audi 2'
    total_seats     INT          NOT NULL,
    format_id       INT          NOT NULL,   -- screen's native format
    CONSTRAINT fk_screen_theatre FOREIGN KEY (theatre_id) REFERENCES theatres(theatre_id),
    CONSTRAINT fk_screen_format  FOREIGN KEY (format_id)  REFERENCES formats(format_id)
);

-- ============================================================
-- TRANSACTIONAL / ASSOCIATION TABLES
-- ============================================================

-- Table: shows
-- Represents a movie scheduled at a particular screen for a date range
-- show_id -> screen_id, movie_id, language_id, format_id, dates
-- All non-key columns depend solely on show_id (BCNF satisfied)
CREATE TABLE shows (
    show_id         INT AUTO_INCREMENT PRIMARY KEY,
    movie_id        INT  NOT NULL,
    screen_id       INT  NOT NULL,
    language_id     INT  NOT NULL,   -- may differ from movie's default language (dubbed)
    format_id       INT  NOT NULL,   -- e.g., a 2D screen can show a 2D print
    run_start_date  DATE NOT NULL,   -- first day the show runs
    run_end_date    DATE NOT NULL,   -- last day the show runs
    ticket_price    DECIMAL(8,2) NOT NULL,
    CONSTRAINT fk_show_movie    FOREIGN KEY (movie_id)    REFERENCES movies(movie_id),
    CONSTRAINT fk_show_screen   FOREIGN KEY (screen_id)   REFERENCES screens(screen_id),
    CONSTRAINT fk_show_language FOREIGN KEY (language_id) REFERENCES languages(language_id),
    CONSTRAINT fk_show_format   FOREIGN KEY (format_id)   REFERENCES formats(format_id)
);

-- Table: show_timings
-- Stores individual time slots for each show (a show can have multiple timings per day)
-- Separated from shows table: start_time is not functionally dependent on show_id alone
-- (same show can have multiple timings) — keeps 1NF (no repeating groups)
CREATE TABLE show_timings (
    timing_id       INT AUTO_INCREMENT PRIMARY KEY,
    show_id         INT      NOT NULL,
    start_time      TIME     NOT NULL,   -- e.g., '09:30:00', '14:00:00'
    available_seats INT      NOT NULL,
    CONSTRAINT fk_timing_show FOREIGN KEY (show_id) REFERENCES shows(show_id)
);

-- ============================================================
-- SAMPLE DATA
-- ============================================================

-- cities
INSERT INTO cities (city_name, state, country) VALUES
  ('Mumbai',    'Maharashtra', 'India'),
  ('Bengaluru', 'Karnataka',   'India'),
  ('Delhi',     'Delhi',       'India');

-- languages
INSERT INTO languages (language_name) VALUES
  ('Telugu'),
  ('Hindi'),
  ('English'),
  ('Tamil');

-- formats
INSERT INTO formats (format_name) VALUES
  ('2D'),
  ('3D'),
  ('IMAX 3D'),
  ('4DX');

-- movies
INSERT INTO movies (title, language_id, duration_mins, genre, release_date, rating) VALUES
  ('Dasara',                        1, 165, 'Action/Drama',  '2023-03-30', 'UA'),
  ('Kisi Ka Bhai Kisi Ki Jaan',     2, 146, 'Action/Comedy', '2023-04-21', 'UA'),
  ('Tu Jhoothi Main Makkaar',       2, 158, 'Romantic Comedy','2023-03-08','UA'),
  ('Avatar: The Way of Water',      3, 192, 'Sci-Fi/Action', '2022-12-16', 'UA');

-- theatres
INSERT INTO theatres (theatre_name, address_line1, city_id, pincode) VALUES
  ('PVR Nexus', 'Nexus Mall, Koramangala', 2, '560034'),
  ('INOX Lido',  'Lido Mall, Ulsoor',      2, '560042'),
  ('PVR Phoenix', 'Phoenix Mall, Nagar',   1, '400001');

-- screens
INSERT INTO screens (theatre_id, screen_name, total_seats, format_id) VALUES
  (1, 'Audi 1', 250, 1),  -- PVR Nexus - 2D
  (1, 'Audi 2', 200, 2),  -- PVR Nexus - 3D
  (1, 'Audi 3', 180, 1),  -- PVR Nexus - 2D
  (1, 'Audi 4', 150, 1),  -- PVR Nexus - 2D
  (2, 'Screen 1', 300, 3);-- INOX Lido - IMAX 3D

-- shows (at PVR Nexus for the week shown in the screenshot)
INSERT INTO shows (movie_id, screen_id, language_id, format_id, run_start_date, run_end_date, ticket_price) VALUES
  (1, 1, 1, 1, '2023-04-25', '2023-05-05', 200.00),  -- Dasara - Telugu 2D - Audi1
  (2, 3, 2, 1, '2023-04-25', '2023-05-05', 180.00),  -- KBKJ - Hindi 2D - Audi3
  (3, 4, 2, 1, '2023-04-25', '2023-05-05', 180.00),  -- TJMM - Hindi 2D - Audi4
  (4, 2, 3, 2, '2023-04-25', '2023-05-05', 350.00);  -- Avatar - English 3D - Audi2

-- show_timings (matching screenshot slots)
-- Dasara (show_id=1): 12:15 PM
INSERT INTO show_timings (show_id, start_time, available_seats) VALUES
  (1, '12:15:00', 120);

-- KBKJ (show_id=2): 01:00 PM, 04:10 PM, 06:20 PM, 07:00 PM
INSERT INTO show_timings (show_id, start_time, available_seats) VALUES
  (2, '13:00:00', 100),
  (2, '16:10:00', 80),
  (2, '18:20:00', 60),
  (2, '19:00:00', 45);

-- TJMM (show_id=3): 01:15 PM
INSERT INTO show_timings (show_id, start_time, available_seats) VALUES
  (3, '13:15:00', 110);

-- Avatar (show_id=4): 01:20 PM
INSERT INTO show_timings (show_id, start_time, available_seats) VALUES
  (4, '13:20:00', 90);


-- ============================================================
-- P2 QUERY
-- List all shows on a given date at a given theatre
-- along with their respective show timings
-- ============================================================
-- Replace '2023-04-25' and theatre_id = 1 with desired values

SELECT
    m.title                         AS movie_title,
    l.language_name                 AS language,
    f.format_name                   AS format,
    sc.screen_name                  AS screen,
    TIME_FORMAT(st.start_time, '%h:%i %p') AS show_time,
    st.available_seats,
    s.ticket_price
FROM
    show_timings  st
    JOIN shows    s   ON st.show_id   = s.show_id
    JOIN movies   m   ON s.movie_id   = m.movie_id
    JOIN screens  sc  ON s.screen_id  = sc.screen_id
    JOIN theatres t   ON sc.theatre_id = t.theatre_id
    JOIN languages l  ON s.language_id = l.language_id
    JOIN formats   f  ON s.format_id  = f.format_id
WHERE
    t.theatre_id = 1                        -- filter by theatre
    AND '2023-04-25' BETWEEN s.run_start_date AND s.run_end_date  -- filter by date
ORDER BY
    m.title, st.start_time;
