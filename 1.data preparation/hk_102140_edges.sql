-- Copy HK network table to new schema
-- changing geom multiLineString to geom_multi
CREATE TABLE jz_handover.hk_102140_edges AS
SELECT type, levels, shape_leng, source,
       target, geom AS geom_multi
  FROM public.hk_pede0131_z_guibo_arc_edge_table102140;

-- Create new id column
ALTER TABLE jz_handover.hk_102140_edges ADD COLUMN id SERIAL PRIMARY KEY;

-- Create new id_cont continuity column (for joining back)
-- after going through arcGIS
ALTER TABLE jz_handover.hk_102140_edges ADD COLUMN id_cont bigint;
UPDATE jz_handover.hk_102140_edges SET id_cont = id;

-- Let's solve the MultLiLineString issue
-- first step is to understand if any of the geometries are multipart:
SELECT
	COUNT(CASE WHEN ST_NumGeometries(geom_multi) > 1 THEN 1 END) AS multi_geom,
	COUNT(geom_multi) AS total_geom
   FROM jz_handover.hk_102140_edges;
/* no multi_geom so we can turn multiLineString into LineString*/

-- Create new geom_2d column as 2d version of geom_multi
ALTER TABLE jz_handover.hk_102140_edges ADD COLUMN geom_2d geometry(multiLineString,102140);
UPDATE jz_handover.hk_102140_edges SET geom_2d = ST_Force2D(geom_multi);
-- Create new geom column as LineString version of geom_2d
ALTER TABLE jz_handover.hk_102140_edges ADD COLUMN geom geometry(LineString,102140);
UPDATE jz_handover.hk_102140_edges SET geom = (ST_Dump(geom_2d)).geom;

-- create spatial index on geom
CREATE INDEX geom_gix ON jz_handover.hk_102140_edges USING GIST(geom);

SELECT * FROM jz_handover.hk_102140_edges LIMIT 10;

-- create short null_geom flag for short edges
ALTER TABLE jz_handover.hk_102140_edges ADD COLUMN null_geom integer;
UPDATE jz_handover.hk_102140_edges
	SET null_geom = CASE
		WHEN shape_leng < 0.001 THEN 1
		ELSE 0
		END;

-- we then used arcGIS to reproject to 32650
-- we will now rejoin this data back to the table (we will probably loose the rows where null_geom = 1
-- let's check out the data from the hk_32650_edges_for_joining table (generated using arcGIS)
-- ! I have put the hk_32650 table in the deprecated schema now !
SELECT id, (ST_Dump(geom)).geom::geometry(LineString,32650) AS geom_32650, id_cont
  FROM deprecated.hk_32650_edges_for_joining LIMIT 10;
-- we will add geom_32650 as a new column in hk_102140_edges
ALTER TABLE jz_handover.hk_102140_edges ADD COLUMN geom_32650 geometry(LineString,32650);
UPDATE jz_handover.hk_102140_edges
	SET geom_32650 = (ST_DUMP(t32650.geom)).geom
	FROM deprecated.hk_32650_edges_for_joining AS t32650
	WHERE jz_handover.hk_102140_edges.id = t32650.id_cont;
-- let's check the short edeges (null_geom =1_
SELECT * FROM jz_handover.hk_102140_edges WHERE null_geom =1;
/* there is a null value geo,_32650 as expected */

-- we created a hk_32650_zones layer with polygons representing different islands in HK.
-- then we will label edges with different zones they belong to. 
ALTER TABLE jz_handover.hk_102140_edges ADD COLUMN area VARCHAR(10);
UPDATE jz_handover.hk_102140_edges as e
	SET area = z.zone
	FROM jz_handover.hk_32650_zones as z
	WHERE ST_Contains(z.geom, e.geom_32650);

							  