-- This function is to use the pgr_withPointsDD() to find the junctions and POIs
-- within a certain driving distance for multiple junctions.
-- in this script, it applies to new territory area (new) in hk, with 102308 junctions

-- FISRT, SINCE THIS COMPUTER DOESN'T HAVE ENOUGH MEMORY TO RUN THE ENTIRE TABLE,
-- WE BREAK THE JUNCTIONS IN 10 SETS OF AROUND 10,000s

-- 0-10,000 - RETURN_POI_EACH_JUNCTION 1
-- pgr_withPointsDD() / network buffer query with no bounding box for first 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr1 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the first 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr WHERE id <= 10000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;
/*Query returned successfully in 44 secs 898 msec.*/

-- 10,001-20,000 RETURN_POI_EACH_JUNCTION 2
-- pgr_withPointsDD() / network buffer query with no bounding box for 2nd 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr2 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the 2nd 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 10000 AND id <= 20000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;
/*Query returned successfully in 3 min 5 secs.*/

-- 20,001-30,000 RETURN_POI_EACH_JUNCTION 3
-- pgr_withPointsDD() / network buffer query with no bounding box for 3rd 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr3 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the third 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 20000 AND id <= 30000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;

-- 30,001-40,000 RETURN_POI_EACH_JUNCTION 4
-- pgr_withPointsDD() / network buffer query with no bounding box for 4th 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr4 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the 4th 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 30000 AND id <= 40000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;

-- 40,001-50,000 RETURN_POI_EACH_JUNCTION 5
-- pgr_withPointsDD() / network buffer query with no bounding box for 5th 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr5 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the 5th 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 40000 AND id <= 50000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;

-- 50,001-60,000 RETURN_POI_EACH_JUNCTION 6
-- pgr_withPointsDD() / network buffer query with no bounding box for 6th 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr6 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the 6th 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 50000 AND id <= 60000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;

-- 60,001-70,000 RETURN_POI_EACH_JUNCTION 7
-- pgr_withPointsDD() / network buffer query with no bounding box for 2nd 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr7 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the 7th 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 60000 AND id <= 70000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;

-- 70,001-80,000 RETURN_POI_EACH_JUNCTION 8
-- pgr_withPointsDD() / network buffer query with no bounding box for 2nd 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr8 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the 8th 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 70000 AND id <= 80000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;

-- 80,001-90,000 RETURN_POI_EACH_JUNCTION 9
-- pgr_withPointsDD() / network buffer query with no bounding box for 2nd 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr9 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the 9th 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 80000 AND id <= 90000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;


-- 90,001-end RETURN_POI_EACH_JUNCTION 10
-- pgr_withPointsDD() / network buffer query with no bounding box for 2nd 10,000 junctions
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr10 AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hknew_32650_poi_buf500 WHERE edge_id IS NOT NULL',
 /*the following line selects the 9th 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr
   WHERE id > 90000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hknew_32650_poi_buf500 as p
on n.node = p.pid;
/* function 2 to 10 Queries returned successfully in 11 min 37 secs.*/
	
-- APPEND ALL RESULTS TABLES
-- these tables are deleted to save space
CREATE TABLE jz_handover.hknew_32650_poi_resultspgr AS
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr1
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr2
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr3
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr4
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr5
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr6
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr7
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr8
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr9
UNION
SELECT * FROM jz_handover.hknew_32650_poi_resultspgr10;
/*Query returned successfully in 53 secs.*/

-- FINDING THE NODES WITH NO POIS ASSOCIATED WITH
CREATE TABLE jz_handover.hknew_32650_edges_buf500_vertices_no_pois AS
SELECT id, the_geom FROM jz_handover.hknew_32650_edges_buf500_noded_1_topo_1_vertices_pgr AS t1
	WHERE NOT EXISTS(SELECT id FROM jz_handover.hknew_32650_poi_resultspgr AS t2 WHERE t1.id = t2.id);

-- ADD A COLUMN TO CATEGORIZE THE POI TYPES INTO 10 TYPES WE USED IN CALCULATING WALKABILITY SCORES
-- this portion is added later 2020.07.29, to avoid having to run the analysis again
ALTER TABLE jz_handover.hknew_32650_poi_resultspgr ADD COLUMN cates VARCHAR(20);
UPDATE jz_handover.hknew_32650_poi_resultspgr 
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