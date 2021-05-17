-- find pois
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM jz_handover.hkmaw_32650_edges_1 ',
'SELECT id AS pid, edge_id, fraction
 FROM jz_handover.hkmaw_32650_poi_1 ',
 426,400,
 directed := false,
 details := true)
)
SELECT p.id, p.geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.node, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN jz_handover.hkmaw_32650_poi_1 as p
on n.node = p.pid;
