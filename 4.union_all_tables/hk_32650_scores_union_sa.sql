-- this script works exclusively for sensitivity analysis.
-- THIS SCRIPT IS USED TO COMBINE ALL PARTS OF HONG KONG WALK SCORE CALCULATION
-- IN TO ONE COMPLETE SHAPEFILE.

-- b. union all tables
CREATE TABLE jz_handover.hk_32650_algo_junction_scorefull_sa AS
SELECT * FROM jz_handover.hkhki_32650_algo_junction_scorefull_sa
UNION
SELECT * FROM jz_handover.hklan_32650_algo_junction_scorefull_sa
UNION
SELECT * FROM jz_handover.hkmaw_32650_algo_junction_scorefull_sa
UNION
SELECT * FROM jz_handover.hkkow1_unbuf_32650_algo_junction_scorefull_sa
UNION
SELECT * FROM jz_handover.hknew_unbuf_32650_algo_junction_scorefull_sa;

UPDATE jz_handover.hk_32650_algo_junction_scorefull_sa
SET
	entroscr = CASE WHEN entroscr IS NULL THEN 0 
		ELSE entroscr END,
	overallscore = CASE WHEN overallscore IS NULL THEN 0 
		ELSE overallscore END; -- expected to have 24+24+245 number of 0s
	
SELECT COUNT(*) FROM jz_handover.hk_32650_algo_junction_scorefull_sa WHERE overallscore = 0; -- 293. correct. Hurray!

-- PART 4 since after the union, ids are duplicated, here is to create a serial
-- key for this complete dataset
/* deprecated dataset --
ALTER TABLE jz_handover.hk_32650_algo_junction_scores RENAME COLUMN id TO old_id;
ALTER TABLE jz_handover.hk_32650_algo_junction_scores ADD COLUMN id SERIAL PRIMARY KEY;
*/
-- do it for scorefull_sa dataset as well. 
ALTER TABLE jz_handover.hk_32650_algo_junction_scorefull_sa RENAME COLUMN id TO old_id;
ALTER TABLE jz_handover.hk_32650_algo_junction_scorefull_sa ADD COLUMN id SERIAL PRIMARY KEY;