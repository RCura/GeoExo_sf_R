#### Chargement des packages ####

library(tidyverse)
library(sf)
library(duckdb)

#### Création de la base de données ####

# to start an in-memory database
con <- dbConnect(duckdb(), dbdir = ":memory:")
# to use a database file (not shared between processes)
# con <- dbConnect(duckdb(), dbdir = "my-db.duckdb", read_only = FALSE)

#### Chargement des extensions spatiales et transferts internet de DuckDB ####

duckdb::dbSendQuery(con, "INSTALL spatial;")
duckdb::dbSendQuery(con, "LOAD spatial;")
duckdb::dbSendQuery(con, "INSTALL httpfs;")
duckdb::dbSendQuery(con, "LOAD httpfs;")
dbGetQuery(con, "SELECT extension_name, installed, description FROM duckdb_extensions();")


#### Création d'une VIEW locale contenant l'ensemble des bâtiments du Sénégal directement depuis le fichier geoparquet en ligne ####

# dbSendQuery(con, "DROP VIEW buildings;")
# Local file
#dbSendQuery(con, "CREATE VIEW buildings AS SELECT * EXCLUDE (geometry), ST_AsWKB(ST_GeomFromWKB(geometry)) as geometry FROM read_parquet('SN.parquet');")
# Remote file
dbSendQuery(con, "CREATE VIEW buildings AS SELECT area_in_meters, confidence, ST_AsWKB(ST_GeomFromWKB(geometry)) as geometry FROM read_parquet('https://data.source.coop/cholmes/google-open-buildings/geoparquet-by-country/country_iso=SN/SN.parquet');")

table_buildings_senegal <- tbl(con, "buildings")
table_buildings_senegal # Le fichier parquet distant fait ~500Mo, seuls ~45Mo sont lus là
table_buildings_senegal %>% count() # Pas de lecture de données, les métadonnées du parquet sont directement interrogées


#### Exemple de récupération d'un sous-ensemble (100 premières lignes) du fichier distant, et conversion en objet sf ####

table_buildings_senegal %>%
  head(100) %>% # Lecture des 100 premières lignes
  collect() %>% # Conversion en objet R (téléchargement), de type data.frame (téléchargement d'environ 40Mo)
  st_sf(sf_column_name = "geometry") %>% # Conversion en objet sf depuis la colonne de géométrie
  st_set_crs(4326) %>% # Par défaut, c'est un data.frame, il n'y a donc pas de métadonnées de SRC : on lui spécifie que c'est du WGS84
  st_transform(32628) # On re-projette en 32628 : UTM zone 28N


#### Lecture de la couche de points USSEIN qui contient les coordonnées de l'USSEIN et création d'un buffer de 25km ####

ussein <- st_read("data/GeoSenegal.gpkg", layer = "USSEIN") %>%
  st_buffer(25e3)


#### Préparation pour l'envoi dans la BDD en mémoire ####

ussein <- ussein %>%
  st_transform(4326) %>% # Notre table initiale (buildings) est en WGS84, et on va faire une intersection, donc on re-projette dans le même SRC
  mutate(geometry = sf::st_as_text(geom)) %>% # Ecriture de la colonne de géométrie en WKT
  st_drop_geometry() # Conversion de l'objet sf en obet data.frame

# dbSendQuery(con, "DROP VIEW ussein")
  
#### Création d'une table ussein depuis notre variable ####
  
duckdb_register(con, "ussein", ussein)
dbGetQuery(con, "DESCRIBE ussein;")

#### Conversion en table spatiale duckdb ####

dbSendQuery(con, "CREATE TABLE ussein_geo AS SELECT * EXCLUDE (geometry), ST_GeomFromText(geometry) as geometry FROM ussein;")
dbGetQuery(con, "DESCRIBE ussein_geo;")

#### Filtrage spatial en SQL pour ne récupérer que les bâtiments de la table building qui sont contenus dans le buffer autour de l'USSEIN ####

dbSendQuery(con, "CREATE TABLE buildings_ussein AS
            SELECT area_in_meters, confidence, buildings.geometry FROM buildings buildings
            JOIN ussein_geo ussein_geo
            ON
            ST_WITHIN(ST_GeomFromWKB(buildings.geometry), ussein_geo.geometry)
            ;")

dbGetQuery(con, "DESCRIBE buildings_ussein;")
dbGetQuery(con, 'SELECT count(*) FROM buildings_ussein;')
dbGetQuery(con, 'SELECT count(*) FROM buildings;')

#### Récupération en objet data.frame des bâtiments inclus dans le buffer ####

buildings_ussein <- tbl(con, 'buildings_ussein') %>%
  collect()

#### Récupération en objet data.frame des bâtiments inclus dans le buffer, puis conversion en sf ####
buildings_ussein <- buildings_ussein %>%
  st_sf(sf_column_name = "geometry", crs = 4326)

#### Travail avec DuckDb fini, on déconnecte la BDD en mémoire, ce qui va libérer l'espace RAM pris ####

dbDisconnect(con)

#### Export des bâtiments en geopackage ####

buildings_ussein %>% st_write(dsn = "Batiments_USSEIN.gpkg")


























####### OLD #########


# download.file("https://data.source.coop/cholmes/google-open-buildings/geoparquet-by-country/country_iso=SN/SN.parquet", destfile = "SN.parquet")

# dbGetQuery(con, "CREATE VIEW buildings as SELECT * FROM read_parquet('https://data.source.coop/cholmes/google-open-buildings/geoparquet-by-country/country_iso=SN/SN.parquet');")

dbGetQuery(con, " CREATE VIEW blob AS SELECT * FROM read_parquet('https://data.source.coop/cholmes/google-open-buildings/geoparquet-by-country/country_iso=SN/SN.parquet';)")

dbGetQuery(con,
           "SELECT count(*) FROM 
   's3://us-west-2.opendata.source.coop/google-research-open-buildings/geoparquet-by-country/country_iso=SN/SN.parquet';
")

my_query <- "CREATE VIEW blob AS SELECT * FROM 's3://us-west-2.opendata.source.coop/google-research-open-buildings/geoparquet-by-country/country_iso=SN/SN.parquet' WHERE quadkey LIKE '03330302320%';"
dbSendQuery(con, "DROP VIEW blob;")
dbSendQuery(con, my_query)
blob <- tbl(con, "blob")
blob
bar <- blob %>% mutate(geometry = ST_GeomFromWKB(geometry)) %>% mutate(geometry = ST_AsWKB(geometry)) %>% collect()

bar %>% st_sf(sf_column_name = "geometry") %>% st_set_crs(4326) %>% plot()

buildings_table <- tbl(con, "buildings")

# buildings_table %>% head(100) %>%
#   mutate(geometry = ST_GeomFromWKB(geometry)) %>%
#   mutate(blob = st_area(geometry))


blob <- buildings_table %>% head(1000) %>%
  mutate(geometry = ST_GeomFromWKB(geometry)) %>%
  mutate(geometry = ST_AsWKB(geometry)) %>%
  collect()

ussein <- st_read("data/GeoSenegal.gpkg", layer = "USSEIN") %>%
  st_buffer(25e3) %>%
  st_transform(4326) %>%
  mutate(geometry = sf::st_as_text(geom)) %>%
  st_drop_geometry()

dbSendQuery(con, "DROP VIEW ussein")
duckdb_register(con, "ussein", ussein)

dbGetQuery(con, 'DESCRIBE ussein;')
dbSendQuery(con, "DROP TABLE buffer_ussein;")
dbGetQuery(con, "CREATE TABLE buffer_ussein AS SELECT NAME, ST_GeomFromText(geometry) as geometry FROM ussein;")
dbGetQuery(con, "FROM buffer_ussein;")
dbGetQuery(con, 'DESCRIBE buffer_ussein;')
dbSendQuery(con, "DROP TABLE buildings_ussein;")
dbGetQuery(con, "CREATE TABLE buildings_ussein AS
SELECT area_in_meters, confidence, ST_GeomFromWKB(a.geometry) AS geom FROM buildings a
JOIN buffer_ussein b
ON ST_Within(ST_GeomFromWKB(a.geometry), b.geometry);")

# foo <- tbl(con, "buildings_ussein")
# foobar <- foo %>% mutate(geom = ST_AsWKB(ST_GeomFromWKB(geom)))
# foo %>% count()
# foobar
# buildings_table %>% count()

dbSendQuery(con, "COPY buildings_ussein TO 'buildings_ussein2.gpkg' WITH (FORMAT GDAL, DRIVER 'GPKG')")

