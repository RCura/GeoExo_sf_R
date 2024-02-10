################################################################################
# Importer les couches d’information et les cartographier (4 points)
################################################################################ 

# Import des couches d'information
library(sf)
com <- st_read("data/dvf.gpkg", layer = "com", quiet = TRUE)
parc <- st_read("data/dvf.gpkg", layer = "parc", quiet = TRUE)
route <- st_read("data/dvf.gpkg", layer = "route", quiet = TRUE)
rail <- st_read("data/dvf.gpkg", layer = "rail", quiet = TRUE)
apt <- st_read("data/dvf.gpkg", layer = "dvf", quiet = TRUE)


# Export de la carte
library(mapsf)
mf_export(com, filename = "img/map1.png", theme = "darkula",width = 800, expandBB = c(0,0,.01,0))
mf_map(parc, col = "grey7", border = "grey7", add=T)
mf_map(route, lwd = .2, col ="#b5b3b5", add=T )
mf_map(rail, lwd = .2, col ="#b5b3b5", add=T, lty = 2 )
mf_map(apt, add=T, col = "tomato", pch = 20, cex = .1)
mf_map(com, col = NA, border = "white", add = T, lwd = 1.2)
mf_title("Brouillon : Les ventes d'appartements à Vincennes et Montreuil (2016 - 2021)")
mf_scale(500, unit = "m")
mf_arrow()
mf_credits("BD CARTO®, IGN, 2021\n© les contributeurs d’OpenStreetMap, 2021\nDemandes de valeurs foncières géolocalisées, Etalab, 2021")
dev.off()





################################################################################
# Carte des prix de l’immobilier (4 points)
################################################################################ 



# Justification de la discrétisation (statistiques, boxplot, histogramme, 
# beeswarm...)
v <- apt$prix
hist(v)
boxplot(v)
# La distribution est normale, gaussienne, en cloche
# définition des bornes de classe
bks <- mf_get_breaks(v, breaks = "msd")
# Definition d'une palette de couleurs
pal <- mf_get_pal(n = c(3,3), palette = c("TealGrn", 'SunsetDark'))
# export de la carte
mf_export(com, filename = "img/map2.png", 
          theme = "darkula", width = 800)
mf_map(parc, col = "grey7", border = "grey7", add=T)
mf_map(route, lwd = .2, col ="#b5b3b5", add=T )
mf_map(rail, lwd = .2, col ="#b5b3b5", add=T, lty = 2 )
# carte choroplethe
mf_map(apt, "prix", "choro", 
       add = TRUE, 
       breaks = bks, 
       pal= pal, 
       cex = .5, 
       pch=20)
mf_map(com, col = NA, border = "white", add = T)
mf_legend(type = "choro", pos = "bottomright", 
          val = bks, pal = pal,
          title = "Prix au metre carré",
          val_rnd = -2, frame = T)
mf_title("Brouillon")
dev.off()





################################################################################ 
# Prix de l’immobilier dans le voisinnage de la Mairie de Montreuil (4 points)
################################################################################ 


# creation d'une couche sf pour la mairie
mairie <- st_as_sf(data.frame(x = 2.4410, y = 48.8624), 
                   coords = c("x", "y"), 
                   crs = 4326)
# reprojection dans la projection des communes
mairie <- st_transform(mairie, st_crs(apt))
# Calcul d'un buffer de 500 mètre
buf <- st_buffer(mairie, 500)
# intersection entre les appartement et le buffer
inter <- st_intersection(apt, buf)
value <- median(inter$prix)

cat(paste0("Le prix de l'immobilier dans un voisinnage de 500 mètres ",
           "autour de la mairie de Montreuil est de ", 
           round(value, 0), 
           " euros par m²"))





################################################################################ 
# Utilisation d’un maillage régulier (4 points)
################################################################################ 

# Créer une grille régulière avec st_make_grid()
grid <- st_make_grid(com, cellsize = 250, square = TRUE)
# Transformer la grille en objet sf avec st_sf()
grid <- st_sf(geometry = grid)
# Ajouter un identifiant unique, voir chapitre 3.7.6
# dans https://rcarto.github.io/geomatique_avec_r/
grid$id_grid <- 1:nrow(grid)
# Compter le nombre de transaction dans chaque carreau, voir chapitre 3.7.7 
# dans https://rcarto.github.io/geomatique_avec_r/
inter_grid_apt <- st_intersects(grid, apt, sparse = TRUE)
grid$n_apt <- sapply(inter_grid_apt, length)
# Calculez le prix median par carreau, voir chapitre 3.7.8
# dans https://rcarto.github.io/geomatique_avec_r/
# st_intersection(), aggregate(), merge()
apt_grid <- st_intersection(apt, grid)
apt_agg <- aggregate(x = list(prixmed = apt_grid$prix),
                     by = list(id_grid = apt_grid$id_grid), 
                     FUN = median)
grid <- merge(x = grid, y = apt_agg, by = "id_grid", all.x = TRUE)
# Selectionner les carreaux ayant plus de 10 transactions, voir chapitre 3.5
# dans https://rcarto.github.io/geomatique_avec_r/
grid <- grid[grid$n_apt>10, ]
# Découpage de la grille en fonction des communes (optionel)
grid <- st_intersection(grid, st_union(com))


# Justification de la discrétisation (statistiques, boxplot, histogramme, 
# beeswarm...)
hist(grid$prixmed)
plot(grid)

# Cartographie
bks <- mf_get_breaks(grid$prixmed,nbreaks = 6, breaks =  "msd")
mf_export(com, filename = "img/map4.png",
          theme = "darkula", width = 800)
mf_map(parc, col = "grey7", border = "grey7", add=T)
mf_map(grid, "prixmed", "choro",
       add = T, border = NA,
       leg_pos = NA,breaks = bks, pal = "Burg")
mf_map(route, lwd = .2, col ="#b5b3b5", add=T )
mf_map(rail, lwd = .2, col ="#b5b3b5", add=T, lty = 2 )
mf_map(apt, add=T, col = "white", pch = ".", cex = .01)
mf_map(com, col = NA, border = "white", add = T)
mf_legend(type = "choro", pos = "bottomright", val = bks, 
          pal = "Burg", val_rnd = -2, frame = T)
mf_title("Brouillon")
dev.off()






