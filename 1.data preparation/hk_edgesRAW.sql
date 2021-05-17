-- Create 2 pg Routing Networks: one 2d and one 2d + fixed with pgr_nodeNetwork

------ CREATE 2D HK edges -----
CREATE TABLE hk_edges2d AS
SELECT type, levels, cost, ST_Force2D(geom) as geom
  FROM hk_pede_102140_pgr_network;

-- change columns
ALTER TABLE hk_edges2d ADD COLUMN id SERIAL PRIMARY KEY;
ALTER TABLE hk_edges2d ADD source integer;
ALTER TABLE hk_edges2d ADD target integer;

-- create spatial index
CREATE INDEX geom_gix ON hk_edges2d USING GIST(geom);

SELECT * FROM hk_edges2d LIMIT 100;

-- We will create 2D fixed PGR network following https://docs.pgrouting.org/2.0/en/src/common/doc/functions/node_network.html
-- but first we will create a topology from the original 2d data
SELECT pgr_createTopology('hk_edges2d', 1, 'geom', 'id', 'source', 'target' , 'true', 'true');
/* which took 3.8 ms for 269,051 edges
pgr_createTopology('hk_edges2d', 1, 'geom', 'id', 'source', 'target', rows_where := 'true', clean := t)
Rows with NULL geometry or NULL id: 191 */

-- or could have used this:
--SELECT pgr_createTopology('hk_edges2d', 1, 'geom', 'id', 'source', 'target' , 'true');
/* which took 3.65min for 269,051 edges
pgr_createTopology('hk_edges2d', 1, 'geom', 'id', 'source', 'target', rows_where := 'true', clean := f)
Rows with NULL geometry or NULL id: 191 */

-- analyze original 2d network
SELECT pgr_analyzegraph('hk_edges2d', 1, the_geom:='geom',source:='source',target:='target');
/* this analysis tells us that:
ANALYSIS RESULTS FOR SELECTED EDGES:
注意:                    Isolated segments: 555
注意:                            Dead ends: 20503
注意:  Potential gaps found near dead ends: 1111
注意:               Intersections detected: 13217
注意:                      Ring geometries: 97
*/

-- we try and fix the problem using pgr_nodeNetwork
SELECT pgr_nodeNetwork('hk_edges2d', 1, 'id','geom','source','target', 'true');
/* results:
注意:    Split Edges: 47622
注意:   Untouched Edges: 221620
注意:       Total original Edges: 269242
注意:   Edges generated: 137868
注意:   Untouched Edges: 221620
注意:         Total New segments: 359488
注意:   New Table: public.hk_edges2d_source
*/

-- check the differences with the newly created network
-- create topology of new network
SELECT pgr_createTopology('hk_edges2d_source', 1, 'geom', 'id', 'source', 'target', rows_where := 'true', clean := true);
/* which took 5min for 359297 edges
pgr_createTopology('hk_edges2d_source', 1, 'geom', 'id', 'source', 'target', rows_where := 'true', clean := t)
Rows with NULL geometry or NULL id: 191 
*/

-- analyze nodeNetwork fixed 2d network
SELECT pgr_analyzegraph('hk_edges2d_source', 1, the_geom:='geom',source:='source',target:='target');
/* this analysis suggests that pgr_nodeNetwork has worked
注意:              ANALYSIS RESULTS FOR SELECTED EDGES:
注意:                    Isolated segments: 102
注意:                            Dead ends: 19421
注意:  Potential gaps found near dead ends: 175
注意:               Intersections detected: 6465
注意:                      Ring geometries: 66
*/



------ CREATE 2D HK POI for each network------

-- 1. create Table for unmodified 2d modified
CREATE TABLE hk_poi2d AS
SELECT ST_Force2D(geom) as geom, poiid, name, address, 
       telephone, type, areaid,
       type1, type2, type3, type1_en, type2_en, type3_en, cat
  FROM hk_pede_102140_pgr_network_poi;

-- 1.add columns to data
ALTER TABLE hk_poi2d ADD COLUMN id SERIAL PRIMARY KEY;
ALTER TABLE hk_poi2d ADD edge_id integer;
ALTER TABLE hk_poi2d ADD fraction float8;
ALTER TABLE hk_poi2d ADD pid integer;

-- 2.Create second table for pgr_nodeNetworke fixed 2d network 
CREATE TABLE hk_poi2d_source AS
SELECT *
  FROM hk_poi2d;

-- 1.Join poi to original 2d network
WITH pe AS (SELECT DISTINCT ON(p.id) p.id, 
    e.id As edge_id,
     ST_LineLocatePoint(e.geom, p.geom) AS frac, e.source, e.target
   FROM "hk_poi2d" As p INNER JOIN "hk_edges2d" As e 
        ON ST_DWithin(e.geom, p.geom, 500)
     ORDER BY p.id, ST_Distance(e.geom, p.geom) )
UPDATE "hk_poi2d" AS p
    SET edge_id = pe.edge_id,
        fraction =  pe.frac,
        pid = CASE WHEN pe.frac = 0 
            THEN pe.source WHEN pe.frac = 1 THEN pe.target ELSE -p.id END
  FROM pe
  WHERE pe.id = p.id;
/* took 9.6 min */

-- 2.Join poi to fixed 2d network
WITH pe AS (SELECT DISTINCT ON(p.id) p.id, 
    e.id As edge_id,
     ST_LineLocatePoint(e.geom, p.geom) AS frac, e.source, e.target
   FROM "hk_poi2d_source" As p INNER JOIN "hk_edges2d_source" As e 
        ON ST_DWithin(e.geom, p.geom, 500)
     ORDER BY p.id, ST_Distance(e.geom, p.geom) )
UPDATE "hk_poi2d_source" AS p
    SET edge_id = pe.edge_id,
        fraction =  pe.frac,
        pid = CASE WHEN pe.frac = 0 
            THEN pe.source WHEN pe.frac = 1 THEN pe.target ELSE -p.id END
  FROM pe
  WHERE pe.id = p.id;
 /* took 13min */