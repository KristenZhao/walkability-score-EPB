-- find routings and pois in buffer
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hkhki_32650_edges_1_noded ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hkhki_32650_poi_1_noded WHERE edge_id IS NOT NULL',
 5298,400,
 directed := false,
 details := true)
)
SELECT p.id, p.geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.node, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkhki_32650_poi_1_noded as p
on n.node = p.pid;

-- find routings and junctions in buffer
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hkhki_32650_edges_1_noded ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hkhki_32650_poi_1_noded WHERE edge_id IS NOT NULL',
 5298,400,
 directed := false,
 details := true)
)
SELECT p.id, p.the_geom, n.node, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkhki_32650_edges_1_noded_vertices_pgr as p
on n.node = p.id;

--pgr_drivingDistance
SELECT node as id, edge, agg_cost as cost FROM pgr_drivingDistance(
        'SELECT id, source, target, cost FROM jz_handover.hkhki_32650_edges_1_noded',
        5298, 400
      );
