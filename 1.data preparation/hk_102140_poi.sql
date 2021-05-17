-- Copy HK poi table to new schema
-- changing geometry to geom_geometry
CREATE TABLE jz_handover.hk_102140_poi AS
SELECT poiid, name, address, telephone, type, areaid, type1, type2, 
       type3, type1_en, type2_en, type3_en, cat, lng_transf, lat_transf, 
       geom AS geom_geometry
  FROM public.hk_pede_102140_poi;

-- Create new id column
ALTER TABLE jz_handover.hk_102140_poi ADD COLUMN id SERIAL PRIMARY KEY;

-- Create new id_cont continuity column (for joining back
-- after going through arcGIS
ALTER TABLE jz_handover.hk_102140_poi ADD COLUMN id_cont bigint;
UPDATE jz_handover.hk_102140_poi SET id_cont = id;

--Create new geom column as Point version of geom_geometry
ALTER TABLE jz_handover.hk_102140_poi ADD COLUMN geom geometry(Point,102140);
UPDATE jz_handover.hk_102140_poi SET geom = geom_geometry;

-- we don't seem to need to create spatial index on geom as it is an exact copy of a column
-- which was already an index

-- we then used arcGIS to reproject to 32650
-- we will now rejoin this data back to the table (we will probably loose the rows where null_geom = 1
-- let's check out the data from the hk_32650_poi_for_joining table (generated using arcGIS)
-- ! I have put the hk_32650 table in the deprecated schema now !
SELECT id, geom, id_cont
  FROM deprecated.hk_32650_poi_for_joining LIMIT 10;
-- we will add geom_32650 as a new column in hk_102140_poi
ALTER TABLE jz_handover.hk_102140_poi ADD COLUMN geom_32650 geometry(Point,32650);
UPDATE jz_handover.hk_102140_poi
	SET geom_32650 = t32650.geom
	FROM deprecated.hk_32650_poi_for_joining AS t32650
	WHERE jz_handover.hk_102140_poi.id = t32650.id_cont;

-- we created a hk_32650_zones layer with polygons representing different islands in HK.
-- then we will label with different zones they belong to. 
ALTER TABLE jz_handover.hk_102140_poi ADD COLUMN area VARCHAR(10);
UPDATE jz_handover.hk_102140_poi as e
	SET area = z.zone
	FROM jz_handover.hk_32650_zones as z
	WHERE ST_Contains(z.geom, e.geom_32650);

-- add columns to data
ALTER TABLE jz_handover.hk_102140_poi ADD edge_id bigint;
ALTER TABLE jz_handover.hk_102140_poi ADD fraction float8;
ALTER TABLE jz_handover.hk_102140_poi ADD pid bigint;

SELECT * FROM jz_handover.hk_102140_poi LIMIT 100; 

-- create a new column "cates" to indicate the categorization of amenities in consistency with 
-- our classification in Walkability Score calculation. 
-- classification is consistent with the python code: scoring_each_junctionsetting.py
ALTER TABLE jz_handover.hk_102140_poi ADD COLUMN cates VARCHAR(20);
UPDATE jz_handover.hk_102140_poi 
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
