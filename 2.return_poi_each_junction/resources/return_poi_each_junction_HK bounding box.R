library(centiserve)
library(igraph)
library(ggplot2)
library(rgdal)
library(rgeos)
library(ggplot2)
library(downloader)
library(geosphere)
library(RANN)
library(XML)
library(broom)
library(plyr)
library(sp)
library(maptools)
library(dismo)
library(classInt)
library(qdapRegex)
library(stplanr)
library(RPostgreSQL)
library(rpostgis)
library(data.table)


# set global variables
network_table <- "hk_pede_102140_pgr_network"
node_table <- "hk_pede_102140_pgr_network_vertices_pgr"
poi_table <- "seb_hk_pede_102140_poi"
results_table <- "seb_hk_pede_102140_pgr_results"
distance <- 400

# database connection
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "WIN_DUGALD_TEST",
                 host = "localhost", port = 5432,
                 user = "postgres", password = "Hk2018")


# calculate number of nodes
nodes <- dbReadTable(con, node_table)
no_nodes <- nrow(nodes)

# for loop to loop through every junction and return poi within distance variable

for (i in 1:no_nodes)
  
{

  poi_query <- paste(
    "WITH all_nodes as( 
      SELECT * FROM pgr_withPointsDD(
        'SELECT id AS id, source, target, cost 
            FROM",network_table,"
          WHERE geom && ST_Expand(
                    (SELECT ST_Collect(geom)
                      FROM ",node_table,"
                    WHERE id = ",i,"),1000)
        ',
        'SELECT id AS pid, edge_id, fraction 
            FROM",poi_table,"
            WHERE geom && ST_Expand(
                    (SELECT ST_Collect(geom)
                      FROM ",node_table,"
                    WHERE id = ",i,"),1000)
        ',",
        i,",",distance,",
        directed := false,
        driving_side := 'b',
        details := true)
      
    )
    
    SELECT p.id, p.geom, p.pid, p.type1_en, p.type2_en, p.type3_en, n.node, n.edge, n.cost, n.agg_cost as distance
    FROM all_nodes AS n
    INNER JOIN ",poi_table," as p
    on n.node = p.pid;")
  return_poi <- dbGetQuery(con, poi_query)
  # if no poi's return skip junction
  if (nrow(return_poi) ==0) {
    message(i, "; no poi") 
  } else {
  # add column to identify junction
  return_poi$junction <- i
  
  # write reulsts to results table
  dbWriteTable(con, results_table, return_poi, append = TRUE, row.names = FALSE)
  print(i)
  }

}
