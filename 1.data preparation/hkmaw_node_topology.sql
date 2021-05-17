-- analyze the 2d topology network
SELECT pgr_analyzegraph('jz_handover.hkmaw_32650_edges_1', 1, the_geom:='geom',source:='source',target:='target');
/*NOTICE:  PROCESSING:
NOTICE:              ANALYSIS RESULTS FOR SELECTED EDGES:
NOTICE:                    Isolated segments: 0
NOTICE:                            Dead ends: 70
NOTICE:  Potential gaps found near dead ends: 6
NOTICE:               Intersections detected: 23
NOTICE:                      Ring geometries: 0
Successfully run. Total query runtime: 246 msec.
1 rows affected.*/


-- we try and fix the problem of un-noded intersections using pgr_nodeNetwork.
-- reason: we assumed all intersections for the pedestrian network are real intersections.
SELECT pgr_nodeNetwork('jz_handover.hkmaw_32650_edges_1', 1, the_geom:='geom', table_ending:='noded');
/* NOTICE:  PROCESSING:
NOTICE:  Split Edges: 100
NOTICE:  Untouched Edges: 568
NOTICE:  Total original Edges: 668
NOTICE:  Edges generated: 278
NOTICE:  Untouched Edges: 568
NOTICE:  Total New segments: 846
Successfully run. Total query runtime: 248 msec.
1 rows affected. */


-- create topology of new network
SELECT pgr_createTopology('jz_handover.hkmaw_32650_edges_1_noded', 1, 'geom');
/*NOTICE:  PROCESSING:
NOTICE:  -------------> TOPOLOGY CREATED FOR  846 edges
NOTICE:  Rows with NULL geometry or NULL id: 0
Successfully run. Total query runtime: 898 msec.
1 rows affected.*/


-- analyze the re-noded topology network
SELECT pgr_analyzegraph('jz_handover.hkmaw_32650_edges_1_noded', 1, the_geom:='geom',source:='source',target:='target');
/*
NOTICE:              ANALYSIS RESULTS FOR SELECTED EDGES:
NOTICE:                    Isolated segments: 0
NOTICE:                            Dead ends: 64
NOTICE:  Potential gaps found near dead ends: 0
NOTICE:               Intersections detected: 12
NOTICE:                      Ring geometries: 0
Successfully run. Total query runtime: 166 msec.
1 rows affected.*/

-- we lost the cost column so we are adding it back to table
ALTER TABLE jz_handover.hkmaw_32650_edges_1_noded ADD COLUMN cost double precision;
UPDATE jz_handover.hkmaw_32650_edges_1_noded SET cost = ST_Length(geom);

--re-create a new poi table with only poi in maw
CREATE TABLE jz_handover.hkmaw_32650_poi_1_noded AS
SELECT id, id_cont, poiid, name, address, telephone, type, areaid, type1, type2, type3, type1_en, type2_en, type3_en, cat, lng_transf, lat_transf,  geom_32650 AS geom, area, edge_id, fraction, pid
	FROM jz_handover.hk_102140_poi WHERE area = 'maw';


SELECT * FROM jz_handover.hkmaw_32650_poi_1_noded;

--Deal with POIs, link to topology
WITH pe AS ( SELECT DISTINCT ON(p.id) p.id,
    e.id As edge_id,
     ST_LineLocatePoint(e.geom, p.geom) AS frac, e.source, e.target
   FROM jz_handover.hkmaw_32650_poi_1_noded As p INNER JOIN jz_handover.hkmaw_32650_edges_1_noded As e
        ON ST_DWithin(e.geom, p.geom, 500)
     ORDER BY p.id, ST_Distance(e.geom, p.geom) )
UPDATE jz_handover.hkmaw_32650_poi_1_noded AS p
    SET edge_id = pe.edge_id,
        fraction =  pe.frac,
        pid = CASE WHEN pe.frac = 0
            THEN pe.source WHEN pe.frac = 1 THEN pe.target ELSE -p.id END
  FROM pe
  WHERE pe.id = p.id;
