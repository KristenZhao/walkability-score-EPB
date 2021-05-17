-- This function a generalized version of place_proj_poi_tolerance_noded_resultspgr
-- which is to use the pgr_withPointsDD() to find the junctions and POIs
-- within a certain driving distance for multiple junctions.

-- REPLACE ALL KEY WORDS
-- schema
-- place
-- proj
-- tolerance

CREATE TABLE schema.place_proj_tolerance_noded_resultspgr AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM schema.place_proj_edges_tolerance_noded ',
'SELECT id AS pid, edge_id, fraction
 FROM schema.place_proj_poi_tolerance_noded WHERE edge_id IS NOT NULL',
/*the following line selects the first 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM schema.place_proj_edges_tolerance_noded_vertices_pgr WHERE id <= 10000 ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN schema.place_proj_poi_tolerance_noded as p
on n.node = p.pid;
/* this takes  */

-- If there is a segmentation in datasets due to memory limit,
-- APPEND ALL RESULTS TABLES
-- these tables are deleted to save space
CREATE TABLE schema.place_proj_tolerance_noded_resultspgr AS
SELECT * FROM schema.place_proj_tolerance_noded_resultspgr1
UNION
SELECT * FROM schema.place_proj_tolerance_noded_resultspgr2


-- FINDING THE NODES WITH NO POIS ASSOCIATED WITH
CREATE TABLE schema.place_proj_edges_tolerance_noded_vertices_no_pois AS
SELECT id, the_geom FROM schema.place_proj_edges_tolerance_noded_vertices_pgr AS t1
	WHERE NOT EXISTS(SELECT id FROM schema.place_proj_tolerance_noded_resultspgr AS t2 WHERE t1.id = t2.id);

-- IF space is a concern, by deleting unnecessary columns and leaving only id,
-- pid_geom, pid and distance, we can shrink the data size 3 times, from 2.3G to
-- 0.8G
