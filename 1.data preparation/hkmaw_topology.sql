--create a new table with only 32650 proejction edges in maw TO be used for creating topology
CREATE TABLE jz_handover.hkmaw_32650_edges_1 AS 
SELECT id, id_cont, type, levels, ROUND(shape_leng,2) AS cost, source, target, null_geom, geom_32650 AS geom, area
	FROM jz_handover.hk_102140_edges WHERE null_geom = 0 AND area = 'maw';
	
--create topology
SELECT pgr_createTopology('jz_handover.hkmaw_32650_edges_1', 1, 'geom');

-- change cost type to double precision
ALTER TABLE jz_handover.hkmaw_32650_edges_1 ALTER COLUMN cost TYPE double precision;

--create a new poi table with only poi in maw
CREATE TABLE jz_handover.hkmaw_32650_poi_1 AS 
SELECT id, id_cont, poiid, name, address, telephone, type, areaid, type1, type2, type3, type1_en, type2_en, type3_en, cat, lng_transf, lat_transf,  geom_32650 AS geom, area, edge_id, fraction, pid
	FROM jz_handover.hk_102140_poi WHERE area = 'maw';


SELECT * FROM jz_handover.hkmaw_32650_poi_1;

--Deal with POIs, link to topology
WITH pe AS ( SELECT DISTINCT ON(p.id) p.id, 
    e.id As edge_id,
     ST_LineLocatePoint(e.geom, p.geom) AS frac, e.source, e.target
   FROM jz_handover.hkmaw_32650_poi_1 As p INNER JOIN jz_handover.hkmaw_32650_edges_1 As e 
        ON ST_DWithin(e.geom, p.geom, 500)
     ORDER BY p.id, ST_Distance(e.geom, p.geom) )
UPDATE jz_handover.hkmaw_32650_poi_1 AS p
    SET edge_id = pe.edge_id, 
        fraction =  pe.frac,
        pid = CASE WHEN pe.frac = 0 
            THEN pe.source WHEN pe.frac = 1 THEN pe.target ELSE -p.id END
  FROM pe
  WHERE pe.id = p.id;
  
  
  
  
  
  
  
  