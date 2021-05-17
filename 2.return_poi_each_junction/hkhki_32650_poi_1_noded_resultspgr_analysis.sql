CREATE TABLE jz_handover.hkhki_32650_poi_1_noded_resultspgr_analysis AS
-- results table
with t1 AS(
SELECT
	id AS junction,pid,pid_geom as geom_pid, distance
FROM jz_handover.hkhki_32650_poi_1_noded_resultspgr
)
-- results table with added line between junction and poi
, t2 AS(
SELECT
	t1.junction, t2.the_geom As geom_junction, t1.pid, t1.geom_pid AS geom_poi,
	ST_MakeLine(t2.the_geom, t1.geom_pid) AS geom_junction_poi,
	t1.distance
FROM t1
INNER JOIN jz_handover.hkhki_32650_edges_1_noded_vertices_pgr as t2
ON t1.junction = t2.id)
-- junction occurences tables
, t3 AS (
SELECT
	distinct(id),count(id) AS junc_occurences
FROM jz_handover.hkhki_32650_poi_1_noded_resultspgr
GROUP BY id)
-- poi occurences tables
, t4 AS(
SELECT
	DISTINCT(pid),
	count(pid) AS poi_occurences
FROM jz_handover.hkhki_32650_poi_1_noded_resultspgr
GROUP BY pid)
-- CREATE TABLE w/ main SELECT statement using temp tables t2, t3 (junction occurences) and t3 (poi occurences)
SELECT
	t2.junction,
	t3.junc_occurences,
	t2.geom_junction,
	t2.pid,
	t4.poi_occurences,
	t2.geom_poi,
	t2.geom_junction_poi,
	t2.distance
FROM t2 JOIN t3 ON t2.junction = t3.id
JOIN t4 ON t2.pid = t4.pid
;



	