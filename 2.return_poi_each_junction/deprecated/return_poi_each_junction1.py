"""return_poi_each_junction.py

inputs:
    edge_table with pgr_createTopology:
        city_projection_edges[_modifications]_tolerance
    junction table (created automatically by pgr_createTopology):
        city_projection_edges[_modifications]_tolerance_vertices_pgr
    POI table associated with pgr edge table:
        city_projection_poi[_modifications]_tolerance_pgr

output:
    PGR Routing Results Table (POI within 400m (network distance) of
    each junction):
        city_projection_edges[_modifications]_tolerance_pgrresults

"""

import psycopg2
import pandas as pd

# =============================================================================
#                SET VARIABLES!
# =============================================================================

conn_string = "host='localhost' dbname='DB_JIANTING_TEST' user='postgres' password='Hk2018'"

edge_table = 'jz_handover.hkhki_32650_edges_1_noded'
junction_table = 'jz_handover.hkhki_32650_edges_1_noded_vertices_pgr'
poi_table = 'jz_handover.hkhki_32650_poi_1_noded'
results_table = 'jz_handover.hkhki_32650_edges_1_noded_pgrresults'
distance = 400

# =============================================================================

# Create Network Connection and Cursor
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

# Create a results table
cur.execute(
'CREATE TABLE IF NOT EXISTS ' + results_table +
    '''
    (
    id integer,
    geom geometry(Point,32650),
    pid bigint,
    type1_en character varying(80) COLLATE pg_catalog."default",
    type2_en character varying(80) COLLATE pg_catalog."default",
    type3_en character varying(80) COLLATE pg_catalog."default",
    node bigint,
    edge bigint,
    cost double precision,
    distance double precision
    )
    '''
            )
conn.commit()

# Get IDs of all junctions in junction_table
junctions = pd.read_sql(
'SELECT id FROM ' + junction_table + ' LIMIT 1000;',
                conn)['id'].tolist()
# print query used
print ('SELECT id FROM ' + junction_table + ';')


q_string = get_junctions_str(5298, distance, edge_table, junction_table, poi_table)

df = pd.read_sql(q_string, conn)


for i in junctions:
    q_string =  get_junctions_str(i, distance, edge_table, junction_table, poi_table)
    df = pd.read_sql(q_string, conn)
    print i
 
def get_junctions_str(id, distance, edge_table, junction_table, poi_table):
    """get_junctions_str to be used w/ pgr_withPointsDD to return all poi ids
    and travel distance (agg.cost) w/in distance of the specified junction
    """
    
    id = str(id) #stringify id
    distance = str(distance) #stringify distance
    
    #q_bbox requires 'SELECT' in front of it to run alone
    q_bbox = str("""
    \t/* q_bbox */
    \tST_Expand(
    \t(SELECT ST_Collect(the_geom) FROM """ + junction_table +
    '\n\tWHERE id IN (' + id +')),'+ distance+')'
            )
    
    q_edges = str("""
    /* q_edges */
    SELECT id AS id, source, target, cost
    FROM """ +  edge_table + ' WHERE geom &&'+ q_bbox
                )
    
    q_poi = str("""
    /* q_poi */
    SELECT id AS pid, edge_id, fraction
    FROM """ + poi_table + 
	 ' WHERE edge_id IS NOT NULL AND geom && ' + q_bbox
                 )            

    q_pgr_withPointsDD = str("""
    /* --- pgr_withPointsDD Query --- */
    WITH all_nodes as(
    SELECT * FROM pgr_withPointsDD("""
            + "'"+ q_edges+"',\n'" + q_poi + "'"
    ',' + id +','+ distance +', directed := false, details := true))' +
    """\n/* join pgr_withPointsDD query with poi_table */
    SELECT p.id, p.pid, n.agg_cost as distance
    FROM all_nodes AS n
    INNER JOIN """ + poi_table + ' as p \n on n.node = p.pid;'
                            )
    
    return(q_pgr_withPointsDD)

def get_junctions_str2(id, distance, edge_table, junction_table, poi_table):
    """get_junctions_str to be used w/ pgr_withPointsDD to return all poi w/in
    distance of the specified junction
    """
    
    id = str(id) #stringify id
    distance = str(distance) #stringify distance
    
    #q_bbox requires 'SELECT' in front of it to run alone
    q_bbox = str("""
    \t/* q_bbox */
    \tST_Expand(
    \t(SELECT ST_Collect(the_geom) FROM """ + junction_table +
    '\n\tWHERE id IN (' + id +')),'+ distance+')'
            )
    
    q_edges = str("""
    /* q_edges */
    SELECT id AS id, source, target, cost
    FROM """ +  edge_table + ' WHERE geom &&'+ q_bbox
                )
    
    q_poi = str("""
    /* q_poi */
    SELECT id AS pid, edge_id, fraction
    FROM """ + poi_table + 
	 ' WHERE edge_id IS NOT NULL AND geom && ' + q_bbox
                 )            

    q_pgr_withPointsDD = str("""
    /* --- pgr_withPointsDD Query --- */
    WITH all_nodes as(
    SELECT * FROM pgr_withPointsDD("""
            + "'"+ q_edges+"',\n'" + q_poi + "'"
    ',' + id +','+ distance +', directed := false, details := true))' +
    """\n/* join pgr_withPointsDD query with poi_table */
    SELECT p.id, p.geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.node, n.edge, n.cost, n.agg_cost as distance
    FROM all_nodes AS n
    INNER JOIN """ + poi_table + ' as p \n on n.node = p.pid;'
                            )
    
    return(q_pgr_withPointsDD)


print get_junctions_str(5298, distance, edge_table, junction_table, poi_table)



print len(df)