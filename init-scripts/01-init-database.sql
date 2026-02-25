-- ============================================================================
-- DATA1500 - Oblig 1: Arbeidskrav I våren 2026
-- Initialiserings-skript for PostgreSQL
-- ============================================================================

-- Opprett grunnleggende tabeller
CREATE TABLE sykkelstasjon(
    stasjon_id SERIAL PRIMARY KEY,
    stasjon_navn VARCHAR(100) NOT NULL UNIQUE,
    adresse VARCHAR(200) NOT NULL,
    opprettet TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lock(
    lock_id SERIAL PRIMARY KEY,
    stasjon_id INT NOT NULL REFERENCES sykkelstasjon(stasjon_id),
    opprettet TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE kunde(
    kunde_id SERIAL PRIMARY KEY,
    fornavn VARCHAR(50) NOT NULL,
    etternavn VARCHAR(50) NOT NULL,
    epost VARCHAR(100) NOT NULL UNIQUE CHECK (epost ~ '^[^@]+@[^@]+\.[^@]+$'),
    mobilnr VARCHAR(20) NOT NULL UNIQUE CHECK (mobilnr ~ '^[0-9]{8}$'),
    opprettet TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sykkel(
    sykkel_id SERIAL PRIMARY KEY,
    sykkel_modell VARCHAR(100) NOT NULL,
    sykkel_innkjopsdato DATE NOT NULL,
    stasjon_id INT REFERENCES sykkelstasjon(stasjon_id),
    lock_id INT REFERENCES lock(lock_id),
    opprettet TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE utleie(
    utleie_id SERIAL PRIMARY KEY,
    kunde_id INT NOT NULL REFERENCES kunde(kunde_id),
    sykkel_id INT NOT NULL REFERENCES sykkel(sykkel_id),
    startstasjon_id INT NOT NULL REFERENCES sykkelstasjon(stasjon_id),
    sluttstasjon_id INT REFERENCES sykkelstasjon(stasjon_id),
    sluttlås_id INT REFERENCES lock(lock_id),
    leiebeløp NUMERIC(10, 2) NOT NULL CHECK (leiebeløp >= 0),
    utleie_tid TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    innlevert_tid TIMESTAMP DEFAULT NULL
);


-- Sett inn testdata
INSERT INTO sykkelstasjon (stasjon_navn, adresse) VALUES
('Sentrum Torg', 'Storgata 1'),
('Havneparken', 'Bryggeveien 12'),
('Universitetet', 'Campus Allé 5'),
('Kulturhuset', 'Parkveien 44'),
('Stadion', 'Idrettsveien 9');

INSERT INTO lock (stasjon_id)
SELECT s.stasjon_id
FROM sykkelstasjon s,
generate_series(1,20);

INSERT INTO kunde (fornavn, etternavn, epost, mobilnr) VALUES
('Ola', 'Nordmann', 'ola@example.com', '40000001'),
('Kari', 'Hansen', 'kari@example.com', '40000002'),
('Per', 'Johansen', 'per@example.com', '40000003'),
('Ida', 'Larsen', 'ida@example.com', '40000004'),
('Marius', 'Solberg', 'marius@example.com', '40000005');

INSERT INTO sykkel (sykkel_modell, sykkel_innkjopsdato, stasjon_id, lock_id)
SELECT 
    (ARRAY['BySykkel', 'FjellSykkel', 'ElSykkel'])[floor(random() * 3) + 1],
    CURRENT_DATE - (random() * 365)::int,
    l.stasjon_id,
    l.lock_id
FROM lock l
ORDER BY random()
LIMIT 100;

INSERT INTO utleie (
    kunde_id,
    sykkel_id,
    startstasjon_id,
    sluttstasjon_id,
    sluttlås_id,
    leiebeløp,
    utleie_tid,
    innlevert_tid
)
SELECT
    ((row_number() OVER () - 1) % 5) + 1 AS kunde_id,          -- rullerer 1–5
    s.sykkel_id,
    s.stasjon_id AS startstasjon_id,
    ((row_number() OVER () - 1) % 5) + 1 AS sluttstasjon_id,   -- rullerer 1–5
    l.lock_id,
    10 + (row_number() OVER () % 40),
    NOW() - (row_number() OVER () * interval '1 hour'),
    NOW() - (row_number() OVER () * interval '30 minutes')
FROM sykkel s
JOIN lock l ON l.stasjon_id = s.stasjon_id
ORDER BY s.sykkel_id
LIMIT 50;

-- For testing: Legge inn en kunde uten utleie
INSERT INTO kunde (fornavn, etternavn, epost, mobilnr) VALUES
('Birk', 'Bredland', 'Birk@example.com', '60000006');

-- DBA setninger (rolle: kunde, bruker: kunde_1)
CREATE ROLE kunde_role LOGIN PASSWORD 'kunde';
GRANT SELECT ON sykkelstasjon TO kunde_role;
GRANT SELECT ON sykkel TO kunde_role;

CREATE USER kunde_1 LOGIN PASSWORD 'kunde1pass';
GRANT kunde_role TO kunde_1;

CREATE TABLE kunde_bruker_map (
    brukernavn TEXT PRIMARY KEY,
    kunde_id INT NOT NULL REFERENCES kunde(kunde_id)
);

INSERT INTO kunde_bruker_map VALUES ('kunde_1', 1);

CREATE VIEW utleie_kunde_view AS
SELECT
sykkel.sykkel_modell,
startstasjon.stasjon_navn AS startstasjon,
sluttstasjon.stasjon_navn AS sluttstasjon,
u.utleie_tid,
u.innlevert_tid,
u.leiebeløp
FROM utleie u
JOIN sykkel ON u.sykkel_id = sykkel.sykkel_id
JOIN sykkelstasjon startstasjon ON u.startstasjon_id = startstasjon.stasjon_id
JOIN sykkelstasjon sluttstasjon ON u.sluttstasjon_id = sluttstasjon.stasjon_id
JOIN kunde_bruker_map m ON u.kunde_id = m.kunde_id
WHERE m.brukernavn = CURRENT_USER;

GRANT SELECT ON utleie_kunde_view TO kunde_role;

-- Eventuelt: Opprett indekser for ytelse



-- Vis at initialisering er fullført (kan se i loggen fra "docker-compose log"
SELECT 'Database initialisert!' as status;