--create a new table with only 32650 projection edges TO be used for creating topology
CREATE TABLE jz_handover.hk_32650_edges_1 AS 
SELECT id, id_cont, type, levels, ROUND(shape_leng,2) AS cost, source, target, null_geom, geom_32650 AS geom
	FROM jz_handover.hk_102140_edges WHERE null_geom = 0;
	
--create topology
SELECT pgr_createTopology('jz_handover.hk_32650_edges_1', 1, 'geom');
