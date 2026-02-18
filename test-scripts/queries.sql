-- ============================================================================
-- TEST-SKRIPT FOR OBLIG 1
-- ============================================================================

-- Kjør med: docker-compose exec postgres psql -h -U admin -d data1500_db -f test-scripts/queries.sql

-- En test med en SQL-spørring mot metadata i PostgreSQL (kan slettes fra din script)
select nspname as schema_name from pg_catalog.pg_namespace;

-- Oppgave 5.1: Lag en spørring som viser alle sykler.
SELECT * FROM sykkel;

-- Oppgave 5.2: Lag en spørring som viser etternavn, fornavn og mobilnummer for alle kunder, sortert alfabetisk på etternavn.
select fornavn, etternavn, mobilnr
from kunde
ORDER BY etternavn ASC;

-- Oppgave 5.3: Lag en spørring som viser alle sykler som er tatt i bruk etter 1. januar 2026.
SELECT * FROM sykkel
WHERE sykkel_innkjopsdato > '2026-01-01';

-- Oppgave 5.4: Lag en spørring som viser antallet kunder i bysykkelordningen.
SELECT COUNT(*) AS antall_kunder FROM kunde;

-- Oppgave 5.5: Lag en spørring som viser alle kunder og teller opp antallet utleieforhold for hver kunde. Oversikten skal også vise kunder som ennå ikke har leid sykkel.
SELECT k.fornavn, k.etternavn, COUNT(u.utleie_id) AS antall_utleier
FROM kunde k
LEFT JOIN utleie u ON k.kunde_id = u.kunde_id
GROUP BY k.kunde_id, k.fornavn, k.etternavn;

-- Oppgave 5.6: Lag en spørring som gir en oversikt over hvilke kunder som aldri har leid en sykkel.
SELECT k.fornavn, k.etternavn
FROM kunde k
LEFT JOIN utleie u ON k.kunde_id = u.kunde_id
WHERE u.utleie_id IS NULL;
-- Oppgave 5.7: Lag en spørring som viser hvilke sykler som aldri har vært utleid.
SELECT s.sykkel_id, s.sykkel_modell
FROM sykkel s
LEFT JOIN utleie u ON s.sykkel_id = u.sykkel_id
WHERE u.utleie_id IS NULL
ORDER BY s.sykkel_id ASC;

-- Oppgave 5.8: Lag en spørring som viser hvilke sykler, med informasjon om kunden, som ikke er levert tilbake etter ett døgn.
SELECT s.sykkel_id, s.sykkel_modell, k.fornavn, k.etternavn
FROM sykkel s
JOIN utleie u ON s.sykkel_id = u.sykkel_id
JOIN kunde k ON u.kunde_id = k.kunde_id
WHERE u.innlevert_tid - u.utleie_tid > INTERVAL '1 day';