-- THIS SCRIPT IS USED TO COMBINE ALL PARTS OF HONG KONG WALK SCORE CALCULATION
-- IN TO ONE COMPLETE SHAPEFILE.

-- PART 1 ~ first we need to clean up the calculation for New Territory and Kowloon
-- because I used a 500-meter buffer to calculate the scores, and now I need to
-- clip the scores to their un-buffered boundaries in order to get rid of overlapping.
-- first do it for Kowloon (hkkow1)
CREATE TABLE jz_handover.hkkow1_unbuf_32650_algo_junction_scores AS
SELECT a.*
  FROM jz_handover.hkkow1_32650_algo_junction_scores AS a, jz_handover.kowloon_zones AS b
  WHERE ST_Within(a.geom, b.geom);
-- second, do it for New Territory (hknew)
CREATE TABLE jz_handover.hknew_unbuf_32650_algo_junction_scores AS
SELECT a.*
  FROM jz_handover.hknew_32650_algo_junction_scores AS a, jz_handover.new_terri_zone AS b
  WHERE ST_Within(a.geom, b.geom);

-- PART 2 add a zone identification to each zone before combining them together,
-- this is for the ease to be able to trace back to the original score tables
-- start with hkkow1
ALTER TABLE jz_handover.hkkow1_unbuf_32650_algo_junction_scores ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hkkow1_unbuf_32650_algo_junction_scores SET sub_area = 'kow';
-- start with hknew
ALTER TABLE jz_handover.hknew_unbuf_32650_algo_junction_scores ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hknew_unbuf_32650_algo_junction_scores SET sub_area = 'new';
-- start with hkhki
ALTER TABLE jz_handover.hkhki_32650_algo_junction_scores ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hkhki_32650_algo_junction_scores SET sub_area = 'hki';
-- start with hklan
ALTER TABLE jz_handover.hklan_32650_algo_junction_scores ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hklan_32650_algo_junction_scores SET sub_area = 'lan';
-- start with hkmaw
ALTER TABLE jz_handover.hkmaw_32650_algo_junction_scores ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hkmaw_32650_algo_junction_scores SET sub_area = 'maw';

-- PART 3 ~ a. convert column type; b. UNION the entire Hong Kong
/* the table column types are different, which caused error when uniting.
therefore adding a step to convert all column types for all associated tables
to double precision */

-- a. change column types for one of the tables
-- HKI
SELECT * FROM jz_handover.hkhki_32650_algo_junction_scores LIMIT 20;
/* no need for conversion */
-- Kowloon
SELECT * FROM jz_handover.hkkow1_unbuf_32650_algo_junction_scores LIMIT 20;
ALTER TABLE jz_handover.hkkow1_unbuf_32650_algo_junction_scores
ALTER COLUMN score_entertainment SET DATA TYPE double precision USING (score_entertainment::double precision),
ALTER COLUMN score_park SET DATA TYPE double precision using (score_park::double precision),
ALTER COLUMN score_domestic SET DATA TYPE double precision USING (score_domestic::double precision);
/* can add on more columns... be careful to have the column names consistant in the brackets!!!*/
-- lantau
SELECT * FROM jz_handover.hklan_32650_algo_junction_scores LIMIT 20;
ALTER TABLE jz_handover.hklan_32650_algo_junction_scores
ALTER COLUMN score_major SET DATA TYPE double precision USING (score_major::double precision),
ALTER COLUMN score_entertainment SET DATA TYPE double precision USING (score_entertainment::double precision);
-- mawan
SELECT * FROM jz_handover.hkmaw_32650_algo_junction_scores LIMIT 20;
ALTER TABLE jz_handover.hkmaw_32650_algo_junction_scores
ALTER COLUMN score_entertainment SET DATA TYPE double precision USING (score_entertainment::double precision);
-- new territory
SELECT * FROM jz_handover.hknew_unbuf_32650_algo_junction_scores LIMIT 20;
ALTER TABLE jz_handover.hknew_unbuf_32650_algo_junction_scores
ALTER COLUMN score_shop SET DATA TYPE double precision USING (score_shop::double precision),
ALTER COLUMN score_major SET DATA TYPE double precision USING (score_major::double precision),
ALTER COLUMN score_restaurant SET DATA TYPE double precision USING (score_restaurant::double precision),
ALTER COLUMN score_entertainment SET DATA TYPE double precision USING (score_entertainment::double precision),
ALTER COLUMN score_sport SET DATA TYPE double precision USING (score_sport::double precision),
ALTER COLUMN score_school SET DATA TYPE double precision USING (score_school::double precision),
ALTER COLUMN score_domestic SET DATA TYPE double precision USING (score_domestic::double precision),
ALTER COLUMN score_health SET DATA TYPE double precision USING (score_health::double precision);

-- a'. added a step to include entropy scores to these four tables. 
-- scripts are in the misc folder, file name ending with "entropy.sql" (edited on 20200730)


-- b. union all tables
CREATE TABLE jz_handover.hk_32650_algo_junction_scorefull AS
SELECT * FROM jz_handover.hkhki_32650_algo_junction_scorefull
UNION
SELECT * FROM jz_handover.hklan_32650_algo_junction_scorefull
UNION
SELECT * FROM jz_handover.hkmaw_32650_algo_junction_scorefull
UNION
SELECT * FROM jz_handover.hkkow1_unbuf_32650_algo_junction_scorefull
UNION
SELECT * FROM jz_handover.hknew_unbuf_32650_algo_junction_scorefull;

UPDATE jz_handover.hk_32650_algo_junction_scorefull
SET
	entroscr = CASE WHEN entroscr IS NULL THEN 0 
		ELSE entroscr END,
	overallscore = CASE WHEN overallscore IS NULL THEN 0 
		ELSE overallscore END; -- expected to have 24+24+245 number of 0s
	
SELECT COUNT(*) FROM jz_handover.hk_32650_algo_junction_scorefull WHERE overallscore = 0; -- 293. correct. Hurray!

-- PART 4 since after the union, ids are duplicated, here is to create a serial
-- key for this complete dataset
/* deprecated dataset --
ALTER TABLE jz_handover.hk_32650_algo_junction_scores RENAME COLUMN id TO old_id;
ALTER TABLE jz_handover.hk_32650_algo_junction_scores ADD COLUMN id SERIAL PRIMARY KEY;
*/
-- do it for scorefull dataset as well. 
ALTER TABLE jz_handover.hk_32650_algo_junction_scorefull RENAME COLUMN id TO old_id;
ALTER TABLE jz_handover.hk_32650_algo_junction_scorefull ADD COLUMN id SERIAL PRIMARY KEY;