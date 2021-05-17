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
SELECT n.start_vid, n.node, p.id, p.geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkhki_32650_poi_1_noded as p
on n.node = p.pid;
/* this takes  */

-- RETURN_POI_EACH_JUNCTION 2
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
SELECT n.start_vid, n.node, p.id, p.geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
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
SELECT n.start_vid, n.node, p.id, p.geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
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
SELECT n.start_vid, n.node, p.id, p.geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkhki_32650_poi_1_noded as p
on n.node = p.pid;
/* this takes  */
	
-- APPEND ALL RESULTS TABLES
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