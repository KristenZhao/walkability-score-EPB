-- THIS SCRIPT COMBINES ALL PROCESSES THAT ARE NEEDED TO CREATE THE TOPOLOGY TABLE AND THE POI TABLE
-- FOR KOWLOON AND NEW TERRIROTY AREA

--  create a new table with only 32650 proejction edges in kow to be used for creating topology
CREATE TABLE jz_handover.hkkow_32650_edges AS
SELECT id, id_cont, type, levels, ROUND(shape_leng,2) AS cost, source, target, null_geom, geom_32650 AS geom, area
	FROM jz_handover.hk_102140_edges WHERE null_geom = 0 AND area = 'kow';


-- we try and fix the problem of un-noded intersections using pgr_nodeNetwork.
-- reason: we assumed all intersections for the pedestrian network are real intersections.
SELECT pgr_nodeNetwork('jz_handover.hkkow_32650_edges', 1, the_geom:='geom', table_ending:='noded_1');
/* 49 SEC */

-- create a new topology table based on naming convention
CREATE TABLE jz_handover.hkkow_32650_edges_noded_1_topo_1 AS
SELECT * FROM jz_handover.hkkow_32650_edges_noded_1

-- create topology for this noded network
SELECT pgr_createTopology('jz_handover.hkkow_32650_edges_noded_1_topo_1', 1, 'geom');
/* it takes 410min failed*/

-- since the number of edges in kowloon is too large to process, we divided kowloon
-- into two parts: kow1 and new. kowloon_zones is used as the division polygon
-- kowloon_buf500 is a 500m-buffer fom it, in order to cover all edges and POIs
-- first: use the kowloon buffer to include the edges within the Kowloon area
-- (but in the buffer)
CREATE TABLE jz_handover.hkkow1_32650_edges_buf500 AS
SELECT a.*
  FROM jz_handover.hkkow_32650_edges AS a, jz_handover.kowloon_buf500 AS b
  WHERE ST_Within(a.geom, b.geom);
-- to leave a modification trace in the table, and create a new column to
-- specify the sub-area: kow
ALTER TABLE jz_handover.hkkow1_32650_edges_buf500 ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hkkow1_32650_edges_buf500 SET sub_area = 'kow';

-- second, do the same for POIs
-- but since the POIs for kowloon is not already done, so we will need to
-- filter directly from hk_102140_poi
CREATE TABLE jz_handover.hkkow1_32650_poi_buf500 AS
SELECT a.*
  FROM jz_handover.hk_102140_poi AS a, jz_handover.kowloon_buf500 AS b
  WHERE ST_Within(a.geom_32650, b.geom);

-- too many geom columns in this table, so delete two and only keep geom_32650
ALTER TABLE jz_handover.hkkow1_32650_poi_buf500 DROP COLUMN geom, DROP COLUMN geom_geometry;
-- rename as geom.
ALTER TABLE jz_handover.hkkow1_32650_poi_buf500 RENAME COLUMN geom_32650 TO geom; 

-- to leave a modification trace in the table, and create a new column to
-- specify the sub-area: kow
ALTER TABLE jz_handover.hkkow1_32650_poi_buf500 ADD COLUMN sub_area VARCHAR;
UPDATE jz_handover.hkkow1_32650_poi_buf500 SET sub_area = 'kow';


-- analyze the re-noded topology network
SELECT pgr_analyzegraph('jz_handover.hkkow1_32650_edges_buf500', 1, the_geom:='geom',source:='source',target:='target');
/* result: */

-- we lost the cost column so we are adding it back to table
ALTER TABLE jz_handover.hkkow_32650_edges_noded_1_topo_1 ADD COLUMN cost double precision;
UPDATE jz_handover.hkkow_32650_edges_noded_1_topo_1 SET cost = ST_Length(geom);

--re-create a new poi table with only poi in kow
CREATE TABLE jz_handover.hkkow_32650_poi_noded_1 AS
SELECT id, id_cont, poiid, name, address, telephone, type, areaid, type1, type2, type3, type1_en, type2_en, type3_en, cat, lng_transf, lat_transf,  geom_32650 AS geom, area, edge_id, fraction, pid
	FROM jz_handover.hk_102140_poi WHERE area = 'kow';


--Deal with POIs, link to topology
WITH pe AS ( SELECT DISTINCT ON(p.id) p.id,
    e.id As edge_id,
     ST_LineLocatePoint(e.geom, p.geom) AS frac, e.source, e.target
   FROM jz_handover.hkkow_32650_poi_noded_1 As p INNER JOIN jz_handover.hkkow_32650_edges_noded_1_topo_1 As e
        ON ST_DWithin(e.geom, p.geom, 500)
     ORDER BY p.id, ST_Distance(e.geom, p.geom) )
UPDATE jz_handover.hkkow_32650_poi_noded_1 AS p
    SET edge_id = pe.edge_id,
        fraction =  pe.frac,
        pid = CASE WHEN pe.frac = 0
            THEN pe.source WHEN pe.frac = 1 THEN pe.target ELSE -p.id END
  FROM pe
  WHERE pe.id = p.id;
