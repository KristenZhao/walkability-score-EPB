-- analyze the 2d topology network
SELECT pgr_analyzegraph('jz_handover.hkhki_32650_edges_1', 1, the_geom:='geom',source:='source',target:='target');
/*NOTICE:              ANALYSIS RESULTS FOR SELECTED EDGES:
NOTICE:                    Isolated segments: 133
NOTICE:                            Dead ends: 3742
NOTICE:  Potential gaps found near dead ends: 342
NOTICE:               Intersections detected: 1929
NOTICE:                      Ring geometries: 13

Successfully run. Total query runtime: 5 secs 808 msec.
1 rows affected.*/

-- we try and fix the problem of un-noded intersections using pgr_nodeNetwork. 
-- reason: we assumed all intersections for the pedestrian network are real intersections.
SELECT pgr_nodeNetwork('jz_handover.hkhki_32650_edges_1', 1, the_geom:='geom', table_ending:='noded');
/*
NOTICE:  PROCESSING:
NOTICE:  pgr_nodeNetwork('jz_handover.hkhki_32650_edges_1', 1, 'id', 'geom', 'noded', '<NULL>',  f)
NOTICE:  Performing checks, please wait .....
NOTICE:  Processing, please wait .....
NOTICE:    Split Edges: 7728
NOTICE:   Untouched Edges: 37667
NOTICE:       Total original Edges: 45395
NOTICE:   Edges generated: 21860
NOTICE:   Untouched Edges: 37667
NOTICE:         Total New segments: 59527
NOTICE:   New Table: jz_handover.hkhki_32650_edges_1_noded
*/

-- create topology of new network
SELECT pgr_createTopology('jz_handover.hkhki_32650_edges_1_noded', 1, 'geom');
/*NOTICE:  PROCESSING:
NOTICE:  pgr_createTopology('jz_handover.hkhki_32650_edges_1_noded', 1, 'geom', 'id', 'source', 'target', rows_where := 'true', clean := f)
NOTICE:  Performing checks, please wait .....
NOTICE:  Creating Topology, Please wait...
NOTICE:  -------------> TOPOLOGY CREATED FOR  59527 edges
NOTICE:  Rows with NULL geometry or NULL id: 0
NOTICE:  Vertices table for table jz_handover.hkhki_32650_edges_1_noded is: jz_handover.hkhki_32650_edges_1_noded_vertices_pgr
Successfully run. Total query runtime: 53 secs 65 msec.
1 rows affected.*/


-- analyze the re-noded topology network
SELECT pgr_analyzegraph('jz_handover.hkhki_32650_edges_1_noded', 1, the_geom:='geom',source:='source',target:='target');
/*NOTICE:  PROCESSING:
NOTICE:  pgr_analyzeGraph('jz_handover.hkhki_32650_edges_1_noded',1,'geom','id','source','target','true')
NOTICE:  Performing checks, please wait ...
NOTICE:  Analyzing for dead ends. Please wait...
NOTICE:  Analyzing for gaps. Please wait...
NOTICE:  Analyzing for isolated edges. Please wait...
NOTICE:  Analyzing for ring geometries. Please wait...
NOTICE:  Analyzing for intersections. Please wait...
NOTICE:              ANALYSIS RESULTS FOR SELECTED EDGES:
NOTICE:                    Isolated segments: 39
NOTICE:                            Dead ends: 3411
NOTICE:  Potential gaps found near dead ends: 38
NOTICE:               Intersections detected: 985
NOTICE:                      Ring geometries: 6

Successfully run. Total query runtime: 5 secs 910 msec.
1 rows affected.*/

-- we lost the cost column so we are adding it back to table
ALTER TABLE jz_handover.hkhki_32650_edges_1_noded ADD COLUMN cost double precision;
UPDATE jz_handover.hkhki_32650_edges_1_noded SET cost = ST_Length(geom);

--re-create a new poi table with only poi in hki
CREATE TABLE jz_handover.hkhki_32650_poi_1_noded AS
SELECT id, id_cont, poiid, name, address, telephone, type, areaid, type1, type2, type3, type1_en, type2_en, type3_en, cat, lng_transf, lat_transf,  geom_32650 AS geom, area, edge_id, fraction, pid
	FROM jz_handover.hk_102140_poi WHERE area = 'hki';


SELECT * FROM jz_handover.hkhki_32650_poi_1_noded;

--Deal with POIs, link to topology
WITH pe AS ( SELECT DISTINCT ON(p.id) p.id,
    e.id As edge_id,
     ST_LineLocatePoint(e.geom, p.geom) AS frac, e.source, e.target
   FROM jz_handover.hkhki_32650_poi_1_noded As p INNER JOIN jz_handover.hkhki_32650_edges_1_noded As e
        ON ST_DWithin(e.geom, p.geom, 500)
     ORDER BY p.id, ST_Distance(e.geom, p.geom) )
UPDATE jz_handover.hkhki_32650_poi_1_noded AS p
    SET edge_id = pe.edge_id,
        fraction =  pe.frac,
        pid = CASE WHEN pe.frac = 0
            THEN pe.source WHEN pe.frac = 1 THEN pe.target ELSE -p.id END
  FROM pe
  WHERE pe.id = p.id;
  