-- =============================================
-- Practicing bounding box - with the aim of speeding up pgrouting
-- inspired by http://ghost.mixedbredie.net/improving-pgrouting-performance/
-- =============================================

-- thi is how to create a bounding box - in this example around Shanghai Airport
CREATE TABLE sh_airportBox_1km AS
SELECT ST_Expand(
	(SELECT ST_Collect(the_geom) FROM sh_102029_pgr_network_vertices_pgr  WHERE id IN (105558)),1000);

-- standard query to return all POI which are 400m network distance from node 1 in suzhou_102029_pgr_network 
SELECT * FROM pgr_withPointsDD(
	'SELECT id AS id, source, target, cost  FROM suzhou_102029_pgr_network',
	'SELECT id AS pid, edge_id, fraction FROM suzhou_102029_pgr_network_poi',
         1,400,
            directed := false,
            driving_side := 'b',
            details := true);
 -- with no bounding box it takes 8.456s

-- same query with network bounding box
SELECT * FROM pgr_withPointsDD(
	'SELECT id AS id, source, target, cost  FROM suzhou_102029_pgr_network 
		WHERE geom && ST_Expand(
                    (SELECT ST_Collect(the_geom) FROM suzhou_102029_pgr_network_vertices_pgr  WHERE id IN (1)),1000)',
	'SELECT id AS pid, edge_id, fraction FROM suzhou_102029_pgr_network_poi',
         1,400,
            directed := false,
            driving_side := 'b',
            details := true);
-- it takes 6.575s (22% faster)

-- same query with netowrk + POI bounding boxes
SELECT * FROM pgr_withPointsDD(
	'SELECT id AS id, source, target, cost  FROM suzhou_102029_pgr_network
		WHERE geom && ST_Expand(
                    (SELECT ST_Collect(the_geom) FROM suzhou_102029_pgr_network_vertices_pgr  WHERE id IN (1)),1000)',
	'SELECT id AS pid, edge_id, fraction FROM suzhou_102029_pgr_network_poi
		WHERE geom && ST_Expand(
                    (SELECT ST_Collect(the_geom) FROM suzhou_102029_pgr_network_vertices_pgr  WHERE id IN (1)),1000)',
         1,400,
            directed := false,
            driving_side := 'b',
            details := true);
-- it takes 1.013s (88% faster)