# Import des données géographique
library(sf)

st_layers("data/GeoSenegal.gpkg")

pays <- st_read(dsn = "data/GeoSenegal.gpkg", layer = "Pays_voisins")
loc <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Localites")
reg <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Regions")
USSEIN <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "USSEIN")
# dep <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Departements")
# loc <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Localites")

road <-st_read(dsn = "data/TR_SEGMENT_ROUTIER_L.shp")


loc$tt_services <- rowSums(loc[,5:17,drop=TRUE])



loc[loc$TYPELOCAL == -1 , "TYPELOCAL"] <- NA


kaoloack <- loc[loc$NOM %in% "Kaolack", ]



library(mapview)
mapview(USSEIN)

# Import des données statistiques
pop <- read.csv("data/Population_2015_2024.csv")

# Jointure fond de carte région - données statistique région
reg <- merge(reg, pop, by.x="NAME_1", by.y="NAME")


# Carte thématique 1 - Cercle proportionnel
library(mapsf)

# mf_export(x = sen,
#           filename = "img/carte_1.png",
#           width = 800)

mf_theme(bg = "steelblue3", fg= "grey10")

mf_map(x = reg, col = NA, border = NA)
mf_map(pays, add = TRUE)

mf_shadow(reg, add = TRUE)
mf_map(reg, col = "grey95", add=T)

mf_map(road, col = "grey50", add=T)

mf_map(x = loc, 
       var = c("tt_services", "TYPELOCAL"),
       type = "prop_typo",
       pal = "Reds", 
       rev = TRUE,
       inches = 0.08,
       leg_pos = NA)


mf_annotation(x = kaoloack, 
              txt = "Kaolack", 
              halo = TRUE, 
              bg = "grey85",
              cex = 1.5)

mf_legend(type = "typo", 
          val = c("Chef-lieu de région", 	
                                 "Chef-lieu de département",
                                 "Chef-lieu d’arrondissement",
                                 "Chef-lieu de communauté rurale ",
                                 "Commune",
                                 "Village important",
                                 "Village",
                                 "Commune d’arrondissement",
                                 "Habitat isolé"), 
          pal = mf_get_pal(n = 9, palette = c("Reds")),
          title = "Types de localités")

mf_legend(type = "prop", 
          val = c(1,2,3,4,5,6,7,8,9,10), 
          inches = 0.08,
          title = "Nombre de services",
          horiz = TRUE,
          pos = "right")

mf_title("Répartition de la population au Sénégal, par régions en 2024", fg = "white")
mf_credits("Auteurs : Hugues Pecout\nSources : GADM & ANSD (2024)", cex = 0.5)




c("Chef-lieu de région", 	
"Chef-lieu de département",
"Chef-lieu d’arrondissement",
"Chef-lieu de communauté rurale ",
"Commune",
"Village important",
"Village",
"Commune d’arrondissement",
"Habitat isolé")



################################################################################
# Carte des prix de l’immobilier (4 points)
################################################################################ 





################################################################################ 
# Prix de l’immobilier dans le voisinnage de la Mairie de Montreuil (4 points)
################################################################################ 



# Calcul d'un buffer de 500 mètre
buf <- st_buffer(USSEIN, 50000)
# intersection entre les appartement et le buffer
inter <- st_intersection(loc, buf)

mf_map(loc)
mf_map(buf, col=NA,  add=TRUE)

value <- sum(inter$SERV_ECOLE)

cat(paste0("Le prix de l'immobilier dans un voisinnage de 500 mètres ",
           "autour de la mairie de Montreuil est de ", 
           round(value, 0), 
           " eécole"))





################################################################################ 
# Utilisation d’un maillage régulier (4 points)
################################################################################ 

# Créer une grille régulière avec st_make_grid()
grid <- st_make_grid(reg, cellsize = 50000, square = TRUE)
# Transformer la grille en objet sf avec st_sf()
grid <- st_sf(geometry = grid)
# Ajouter un identifiant unique, voir chapitre 3.7.6
# dans https://rcarto.github.io/geomatique_avec_r/
grid$id_grid <- 1:nrow(grid)
# Compter le nombre de transaction dans chaque carreau, voir chapitre 3.7.7 
# dans https://rcarto.github.io/geomatique_avec_r/
inter_grid_loc<- st_intersects(grid, loc, sparse = TRUE)
grid$n_loc <- sapply(inter_grid_loc, length)
# Calculez le prix median par carreau, voir chapitre 3.7.8
# dans https://rcarto.github.io/geomatique_avec_r/
# st_intersection(), aggregate(), merge()
# loc_grid <- st_intersection(loc, grid)
# loc_agg <- aggregate(x = list(prixmed = loc_grid$tt_services),
#                      by = list(id_grid = loc_grid$id_grid), 
#                      FUN = median)
# grid <- merge(x = grid, y = loc_agg, by = "id_grid", all.x = TRUE)
# Selectionner les carreaux ayant plus de 10 transactions, voir chapitre 3.5
# dans https://rcarto.github.io/geomatique_avec_r/

# Découpage de la grille en fonction des communes (optionel)
grid <- st_intersection(grid, st_union(reg))


# Justification de la discrétisation (statistiques, boxplot, histogramme, 
# beeswarm...)
hist(grid$n_loc)

# Cartographie
bks <- mf_get_breaks(grid$n_loc ,nbreaks = 6, breaks =  "msd")


mf_map(grid, "n_loc", "choro",
       add = T, border = NA,
       leg_pos = NA,breaks = bks, pal = "Burg")
mf_map(road, lwd = .2, col ="#b5b3b5", add=T )
mf_map(loc, add=T, col = "white", pch = ".", cex = .01)
mf_map(reg, col = NA, border = "white", add = T)
mf_legend(type = "choro", pos = "bottomright", val = bks, 
          pal = "Burg", val_rnd = -2, frame = T)
mf_title("Brouillon")







