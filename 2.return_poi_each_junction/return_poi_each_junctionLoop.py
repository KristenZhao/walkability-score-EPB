# =============================================================================
# This function a generalized version of place_proj_poi_tolerance_noded_resultspgr
# which is to use the pgr_withPointsDD() to find the junctions and POIs
# within a certain driving distance for multiple junctions.
# =============================================================================

'''
LOGIC

'''

import psycopg2
import pandas as pd
from sqlalchemy import create_engine


# =============================================================================
#                SET VARIABLES!
# =============================================================================

conn_string = "host='localhost' dbname='WIN_DUGALD_TEST' user='postgres' password='Hk2018'"
sqlalchemy_create_engine_string = 'postgresql+psycopg2://postgres:Hk2018@localhost/DB_JIANTING_TEST'
dbschema= 'jz_handover'

# check naming conventions for how tables should be named
poi_table = 'jz_handover.hk_poi'
edge_table = 'jz_handover.hk_edges'
junction_table = 'jz_handover.hk_junctions'
resultspgr_table = 'jz_handover.hknew_32650_poi_resultspgr'

# =============================================================================
#                FUNCTION(S)
# =============================================================================
def q_createTable(resultspgr_tablenum, poi_table, edge_table, junction_table, row_lower, row_upper):
    query =str("""
CREATE TABLE '""" +  resultspgr_tablenum + """' AS
WITH all_nodes as(
SELECT * FROM pgr_withPointsDD(
'SELECT id AS id, source, target, cost
 FROM '""" + edge_table + """' ',
'SELECT id AS pid, edge_id, fraction
 FROM '""" + poi_table + """' WHERE edge_id IS NOT NULL',
/*the following line selects the first 10,000 junctions as starting points.*/
 (SELECT ARRAY (SELECT id FROM '""" + junction_table + """' WHERE id >=""" + str(row_lower) + """ AND id <=""" + str(row_upper) + """ ORDER BY id)),400,
 directed := false,
 details := true)
)
/*n.start_vid is the starting junctions, pid are the poi ids, pid_geom are the geom of pois*/
SELECT n.start_vid AS id, p.geom AS pid_geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.edge, n.cost, n.agg_cost as distance
FROM all_nodes AS n
INNER JOIN '""" + poi_table + """' as p
on n.node = p.pid;
    """)
    return query

# =============================================================================
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

q_nb_junctions = str('''
                SELECT COUNT(id) AS junctions
                FROM ''' + junction_table + ''';
                ''')
nb_junctions = pd.read_sql(q_junctions_values,
                conn).values[0]

n = nb_junctions / 10000 
print 'we will need to break the ' + str(nb_junctions) +' into ' + str(n+1) + ' tables.'

# for loop to run multiple return_poi_each_junction queries
# around 10,000 jucnctions for each resultspgr_table) 
for i in range (1,n+2):
    print i
    
    resultspgr_tablenum = resultspgr_table + str(i) # set table name
    print resultspgr_tablenum
    
    row_lower = i*10000-10000+1 # lower id bracket
    row_upper = i*10000 # upper id bracket
    print '[' + str(row_lower) + ',' + str(row_upper) + ']'
    
    #send postgresql query to d
    cur = conn.cursor()
    print q_createTable(resultspgr_tablenum, poi_table, edge_table, junction_table, row_lower, row_upper)
    cur.execute(q_createTable)
    conn.commit()

#append all results table created by above for loop
if n > 1:
    query = 'SELECT * FROM ' + resultspgr_table +'1'
    for i in range(2, n+1):
        query = query +"""\nUNION\nSELECT * FROM '""" + resultspgr_table + str(i)
    q_unionTables = str("""
CREATE TABLE '""" +  resultspgr_table + """' AS """+ query + """;
   """)
print q_unionTables 


# =============================================================================



