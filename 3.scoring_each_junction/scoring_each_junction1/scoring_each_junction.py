# =============================================================================
# This takes  the results table and returns a score for each junction
# need to replace the table names accordingly. currently it's for hong kong island, HK
# =============================================================================

'''
LOGIC OF THIS ALGORITHM

Results Table has the following columns:
|id|geom|pid|type1_en|type2_en|type3_en|node|edge|cost|distance|junction|
--> we want to calculate a score for each junction so we will return a
table that looks like this:
|junction|score| or possibly |junction|type1_score|type2_score|...|

create an empty junctions table:

for every junction:
    subset the results
    for every category:
        calculate cat_score category score
    add up the category scores

You need to run the scoring_each_junctionfunc.py and 
  scoring_each_junctionsettings.py scripts manually before running
this script
'''

import psycopg2
import pandas as pd
from sqlalchemy import create_engine

# =============================================================================
#                SET VARIABLES!
# =============================================================================

conn_string = "host='localhost' dbname='database' user='username' password='password'"
sqlalchemy_create_engine_string = 'postgresql+psycopg2://postgres:password@localhost/database'
dbschema= 'jz_handover'
junction_table = 'jz_handover.hkmaw_32650_edges_1_noded_vertices_pgr' #change for five areas: hki, kow, new, lan, maw
resultspgr_table = 'jz_handover.hkmaw_32650_poi_resultspgr'
algo_junction_scores_table = 'jz_handover.hkmaw_32650_algo_junction_scores'
algo_junction_scores_table_temp = 'hkmaw_32650_algo_junction_scores_temp' #same as algo junction_scores
# but with _temp at end and no schema
# =============================================================================


# =============================================================================

conn = psycopg2.connect(conn_string)
cur = conn.cursor()


# get junction values from database (we will cycle through these)
q_junctions_values = str('''
                SELECT DISTINCT(id) AS junction
                FROM ''' + resultspgr_table + '''
                ORDER BY junction;
                ''')
junctions_values = pd.read_sql(q_junctions_values,
                conn)
junctions_values = junctions_values['junction']
'''___           ____'''

# setup empty dataframe for storing alogrithm scores
junction_scores = pd.DataFrame(columns=['junction',
                                        'score',
                                        'score_shop',
                                        'score_major',
                                        'score_bus',
                                        'score_restaurant',
                                        'score_entertainment',
                                        'score_park',
                                        'score_sport',
                                        'score_school',
                                        'score_domestic',
                                        'score_health'])

q_resultspgr =  str("""SELECT  id, pid, type1_en, type2_en, type3_en, distance, pid_geom
               FROM """ + resultspgr_table + ' ;')
resultspgr = pd.read_sql(q_resultspgr
                 ,conn)


# iterate through all junctions in junction values
for i, v in enumerate (junctions_values):
    '''to speed things up, we need to combine the sql imports into batches'''
    #setup dataframe df with poi in buffer
    df = resultspgr.loc[resultspgr['id'] == v]
    #df = df[['junction','id','distance','type2_en','geom']]

    # calculate scores for each category using cat_score()
    score_shop =  cat_score(df, shop_types, shop_dist_scores, shop_weights)
    score_major = cat_score(df, major_transport_types, major_transport_dist_scores,
                      major_transport_weights)
    score_bus = cat_score(df, bus_transport_types, bus_transport_dist_scores,
                          bus_transport_weights)
    score_restaurant = cat_score(df, restaurant_types, restaurant_dist_scores,
                                 restaurant_weights)
    score_entertainment = cat_score(df, entertainment_types,
                                    entertainment_dist_scores,
                                    entertainment_weights)
    score_park = cat_score(df, park_types, park_dist_scores, park_weights)
    score_sport = cat_score(df, sport_types, sport_dist_scores, sport_weights)
    score_school = cat_score(df, school_types, school_dist_scores,
                             school_weights)
    score_domestic = cat_score(df, domestic_types, domestic_dist_scores,
                               domestic_weights)
    score_health = cat_score(df, health_types, health_dist_scores,
                             health_weights)

    #initialise junction scores
    junction_score = 0
    #calculate combined score
    junction_score = score_shop + score_major + score_bus + score_restaurant \
        + score_entertainment + score_park + score_sport + score_school \
        + score_domestic + score_health

    print 'junction ',v, ': ', junction_score

    #save scores for specific junction in junction_score_df
    junction_score_df = pd.DataFrame([[v,
                                   junction_score,
                                   score_shop,
                                   score_major,
                                   score_bus,
                                   score_restaurant,
                                   score_entertainment,
                                   score_park,
                                   score_sport,
                                   score_school,
                                   score_domestic,
                                   score_health]],
                                  columns=['junction',
                                           'score',
                                           'score_shop',
                                           'score_major',
                                           'score_bus',
                                           'score_restaurant',
                                           'score_entertainment',
                                           'score_park',
                                           'score_sport',
                                           'score_school',
                                           'score_domestic',
                                           'score_health']
                                  )

    #add junction_score_df to junction_scores dataframe
    junction_scores = junction_scores.append(junction_score_df)

# =============================================================================
# Save the junctin_scores dataframe to the database in temporary table
# Create Network Connection with sqlalchemy
engine = create_engine(sqlalchemy_create_engine_string,
    connect_args={'options': '-csearch_path={}'.format(dbschema)})

with engine.connect() as conn, conn.begin():
    #save to database in temporary table
    junction_scores.to_sql(name=algo_junction_scores_table_temp,
                           con=engine,
                           if_exists='fail')

#rejoin the geometry column from junctions table
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

q_createTable = str("""
CREATE TABLE """ + algo_junction_scores_table + """ AS
    SELECT junc.id, algo.score,
            algo.score_shop, algo.score_major, algo.score_bus,
            algo.score_restaurant,
            algo.score_entertainment, algo.score_park,
            algo.score_sport, algo.score_school,
            algo.score_domestic, algo.score_health,
            junc.the_geom AS geom
    FROM """ + dbschema+'.'+algo_junction_scores_table_temp +""" AS algo
    LEFT JOIN """ + junction_table + """ AS junc
    ON algo.junction = junc.id;
-- drop temporary table
DROP TABLE """ + dbschema+'.'+algo_junction_scores_table_temp +""";"""
                 )
print q_createTable
cur.execute(q_createTable)
conn.commit()
