-- For Lantau island
-- This function uses the pgr_withPointsDD() to find the junctions and POIs
-- within a certain driving distance for multiple junctions.

CREATE TABLE jz_handover.hklan_32650_poi_resultspgr AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hklan_32650_edges_noded_1_topo_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hklan_32650_poi_noded_1 WHERE edge_id IS NOT NULL',
/*the following line selects the first 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM jz_handover.hklan_32650_edges_noded_1_topo_1_vertices_pgr ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hklan_32650_poi_noded_1 as p
on n.node = p.pid;
/* this takes  1 secs 225 msec */

-- FINDING THE NODES WITH NO POIS ASSOCIATED WITH
CREATE TABLE jz_handover.hklan_32650_edges_noded_1_vertices_no_pois AS
SELECT id, the_geom FROM jz_handover.hklan_32650_edges_noded_1_topo_1_vertices_pgr AS t1
	WHERE NOT EXISTS(SELECT id FROM jz_handover.hklan_32650_poi_resultspgr AS t2 WHERE t1.id = t2.id);

-- ADD A COLUMN TO CATEGORIZE THE POI TYPES INTO 10 TYPES WE USED IN CALCULATING WALKABILITY SCORES
-- this portion is added later 2020.07.29, to avoid having to run the analysis again
ALTER TABLE jz_handover.hklan_32650_poi_resultspgr ADD COLUMN cates VARCHAR(20);
UPDATE jz_handover.hklan_32650_poi_resultspgr 
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