-- This function is to use the pgr_withPointsDD() to find the junctions and POIs
-- within a certain driving distance for multiple junctions.
-- in this script, it applies to hk island in hk, with 41,000 junctions

-- FISRT, SINCE THIS COMPUTER DOESN'T HAVE ENOUGH MEMORY TO RUN THE ENTIRE TABLE,
-- WE BREAK THE JUNCTIONS IN 4 SETS OF AROUND 10,000s

-- 0-10,000 - RETURN_POI_EACH_JUNCTION 1
-- pgr_withPointsDD() / network buffer query with no bounding box for first 10,000 junctions
CREATE TABLE jz_handover.hkhki_32650_poi_1_noded_resultspgr1 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hkhki_32650_edges_1_noded ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hkhki_32650_poi_1_noded WHERE edge_id IS NOT NULL',
/*the following line selects the first 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hkhki_32650_edges_1_noded_vertices_pgr WHERE id <= 10000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkhki_32650_poi_1_noded as p
on n.node = p.pid;
/* this takes  */

-- 10,001-20,000 RETURN_POI_EACH_JUNCTION 2
-- pgr_withPointsDD() / network buffer query with no bounding box for 2nd 10,000 junctions
CREATE TABLE jz_handover.hkhki_32650_poi_1_noded_resultspgr2 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hkhki_32650_edges_1_noded ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hkhki_32650_poi_1_noded WHERE edge_id IS NOT NULL',
 (SELECT ARRAY (SELECT id FROM jz_handover.hkhki_32650_edges_1_noded_vertices_pgr WHERE id > 10000 AND id <= 20000 ORDER BY id)),400,
 directed := false,
 details := true)
)
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkhki_32650_poi_1_noded as p
on n.node = p.pid;
/* this takes  */

-- RETURN_POI_EACH_JUNCTION 3
-- pgr_withPointsDD() / network buffer query with no bounding box for 3rd 10,0000 junctions
CREATE TABLE jz_handover.hkhki_32650_poi_1_noded_resultspgr3 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hkhki_32650_edges_1_noded ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hkhki_32650_poi_1_noded WHERE edge_id IS NOT NULL',
 (SELECT ARRAY (SELECT id FROM jz_handover.hkhki_32650_edges_1_noded_vertices_pgr WHERE id > 20000 AND id <= 30000 ORDER BY id)),400,
 directed := false,
 details := true)
)
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkhki_32650_poi_1_noded as p
on n.node = p.pid;
/* this takes  */

-- RETURN_POI_EACH_JUNCTION 4
-- pgr_withPointsDD() / network buffer query with no bounding box for last set of 10,000 (or so junctions) junctions
CREATE TABLE jz_handover.hkhki_32650_poi_1_noded_resultspgr4 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hkhki_32650_edges_1_noded ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hkhki_32650_poi_1_noded WHERE edge_id IS NOT NULL',
 (SELECT ARRAY (SELECT id FROM jz_handover.hkhki_32650_edges_1_noded_vertices_pgr WHERE id > 30000 ORDER BY id)),400,
 directed := false,
 details := true)
)
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkhki_32650_poi_1_noded as p
on n.node = p.pid;
/* this takes  */

-- APPEND ALL RESULTS TABLES
-- these tables are deleted to save space
CREATE TABLE jz_handover.hkhki_32650_poi_1_noded_resultspgr AS
SELECT * FROM jz_handover.hkhki_32650_poi_1_noded_resultspgr1
UNION
SELECT * FROM jz_handover.hkhki_32650_poi_1_noded_resultspgr2
UNION
SELECT * FROM jz_handover.hkhki_32650_poi_1_noded_resultspgr3
UNION
SELECT * FROM jz_handover.hkhki_32650_poi_1_noded_resultspgr4;

-- FINDING THE NODES WITH NO POIS ASSOCIATED WITH
CREATE TABLE jz_handover.hkhki_32650_edges_1_noded_vertices_no_pois AS
SELECT id, the_geom FROM jz_handover.hkhki_32650_edges_1_noded_vertices_pgr AS t1
	WHERE NOT EXISTS(SELECT start_vid FROM jz_handover.hkhki_32650_poi_1_noded_resultspgr AS t2 WHERE t1.id = t2.start_vid);
	
	
-- ADD A COLUMN TO CATEGORIZE THE POI TYPES INTO 10 TYPES WE USED IN CALCULATING WALKABILITY SCORES
-- this portion is added later 2020.07.29, to avoid having to run the analysis again
ALTER TABLE jz_handover.hkhki_32650_poi_1_noded_resultspgr ADD COLUMN cates VARCHAR(20);
UPDATE jz_handover.hkhki_32650_poi_1_noded_resultspgr 
	SET cates = 
		CASE WHEN type2_en = 'Shop' OR type2_en = 'Comprehensive market' 
				OR type2_en = 'Convenience store / convenience store' 
				OR type2_en = 'Shopping related sites' OR type2_en = 'supermarket' 
				THEN 'shop'
			WHEN type2_en = 'TRAIN STATION' OR type2_en = 'subway station' THEN 'major'
			WHEN type2_en = 'bus stop' THEN 'bus'
			WHEN type2_en = 'Restaurant'
				OR type2_en = 'Fast-food restaurant'
				OR type2_en = 'Cafe'
				OR type2_en = 'Foreign Restaurants'
				OR type2_en = 'Food related sites'
				OR type2_en = 'Casual dining options'
				OR type2_en = 'Bakery'
				OR type2_en = 'Tea houses'
				OR type2_en = 'Cold stores'
				THEN 'restaurant'
			WHEN type2_en = 'Entertainment'
				OR type2_en = 'Theater'
				THEN 'entertainment'
			WHEN type2_en =  'Park Place'
				OR type2_en = 'Leisure venues'
				THEN 'park'
			WHEN type2_en = 'Sports Complex' 
				OR type2_en = 'Sports and leisure establishments'
				THEN 'sport'
			WHEN type2_en = 'SCHOOL'
				THEN 'school'
			WHEN type2_en = 'Beauty salon'
				THEN 'domestic'
			WHEN type2_en =  'general Hospital'
				OR type2_en = 'clinic'
				OR type2_en = 'Specialist Hospital'
				THEN 'health'
			ELSE NULL END;

-- IF space is a concern, by deleting unnecessary columns and leaving only id, pid_geom, pid and distance, we can shrink the data size 3 times, from 2.3G to 0.8G 