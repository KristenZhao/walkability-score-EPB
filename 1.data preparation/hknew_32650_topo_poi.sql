-- THIS SCRIPT COMBINES ALL PROCESSES THAT ARE NEEDED TO CREATE THE TOPOLOGY
-- TABLE AND THE POI TABLE FOR NEW TERRITORY AREA (new)

-- since the number of edges in kowloon is too large to process, we divided kowloon
-- into two parts: kow1 and new. newterri_zone is used to include all new territory
-- roads, and new_terri_buf500 is the 500-meter buffer of it, in order to cover
-- all edges and POIs.
-- First: use the new_terri_buf500  to include the edges within the new terri area
-- (in the buffer)
CREATE TABLE jz_handover.hknew_32650_edges_buf500 AS
SELECT a.*
  FROM jz_handover.hk_32650_edges_1 AS a, jz_handover.new_terri_buf500 AS b
  WHERE ST_Within(a.geom, b.geom);
-- to leave a modification trace in the table, and to create a new column to
-- specify the sub-area: new
ALTER TABLE jz_handover.hknew_32650_edges_buf500 ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hknew_32650_edges_buf500 SET sub_area = 'new';

-- we try and fix the problem of un-noded intersections using pgr_nodeNetwork.
-- reason: we assumed all intersections for the pedestrian network are real intersections.
SELECT pgr_nodeNetwork('jz_handover.hknew_32650_edges_buf500', 1, the_geom:='geom', table_ending:='noded_1');
/* 26 SEC */

-- create a new topology table based on naming convention
CREATE TABLE jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 AS
SELECT * FROM jz_handover.hknew_32650_edges_buf500_noded_1;

-- create topology for this noded network
-- *question about the column names? google it
SELECT pgr_createTopology('jz_handover.hknew_32650_edges_buf500_noded_1_topo_1', 1, 'geom');
/* it takes 2min 29 secs successful */

-- analyze the re-noded topology network
SELECT pgr_analyzegraph('jz_handover.hknew_32650_edges_buf500_noded_1_topo_1', 1, the_geom:='geom',source:='source',target:='target');
/* took 13 secs
	NOTICE:              ANALYSIS RESULTS FOR SELECTED EDGES:
	NOTICE:                    Isolated segments: 34
	NOTICE:                            Dead ends: 9896
	NOTICE:  Potential gaps found near dead ends: 64
	NOTICE:               Intersections detected: 2819
	NOTICE:                      Ring geometries: 24
*/

-- we lost the cost column so we are adding it back to table
ALTER TABLE jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 ADD COLUMN cost double precision;
UPDATE jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 SET cost = ST_Length(geom);

-- second, re-create a new poi table with only poi in new territory
-- but since the POIs for new territory is not already done, so we will need to
-- filter directly from hk_102140_poi
CREATE TABLE jz_handover.hknew_32650_poi_buf500 AS
SELECT a.*
  FROM jz_handover.hk_102140_poi AS a, jz_handover.new_terri_buf500 AS b
  WHERE ST_Within(a.geom_32650, b.geom);

-- too many geom columns in this table, so delete two and only keep geom_32650
ALTER TABLE jz_handover.hknew_32650_poi_buf500 DROP COLUMN geom, DROP COLUMN geom_geometry;
-- rename as geom.
ALTER TABLE jz_handover.hknew_32650_poi_buf500 RENAME COLUMN geom_32650 TO geom;

-- to leave a modification trace in the table, and create a new column to
-- specify the sub-area: new
ALTER TABLE jz_handover.hknew_32650_poi_buf500 ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hknew_32650_poi_buf500 SET sub_area = 'new';


--Deal with POIs, link to topology
WITH pe AS ( SELECT DISTINCT ON(p.id) p.id,
    e.id As edge_id,
     ST_LineLocatePoint(e.geom, p.geom) AS frac, e.source, e.target
   FROM jz_handover.hknew_32650_poi_buf500 As p INNER JOIN jz_handover.hknew_32650_edges_buf500_noded_1_topo_1 As e
        ON ST_DWithin(e.geom, p.geom, 500)
     ORDER BY p.id, ST_Distance(e.geom, p.geom) )
UPDATE jz_handover.hknew_32650_poi_buf500 AS p
    SET edge_id = pe.edge_id,
        fraction =  pe.frac,
        pid = CASE WHEN pe.frac = 0
            THEN pe.source WHEN pe.frac = 1 THEN pe.target ELSE -p.id END
  FROM pe
  WHERE pe.id = p.id;
/*Query returned successfully in 3 min 31 secs.*/