# Import des données géographique
library(sf)

st_layers("data/GeoSenegal.gpkg")

pays <- st_read(dsn = "data/GeoSenegal.gpkg", layer = "Pays_voisins")
sen <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Senegal")
reg <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Regions")
dep <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Departements")
loc <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Localites")
USSEIN <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "USSEIN")
routes <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Routes")


# Carte de localités


# Séléctionner uniquement les localités localisées au Sénégal
# loc_sen <- loc[loc$PAYS == "SN", ]
# OU
loc_sen <- st_filter(x = loc, 
                     y = sen,
                     .predicate = st_intersects)

# Nombre total de services dans les localités
loc_sen$SERV_TT <- rowSums(loc_sen[,5:17,drop=TRUE])



# Découper le réseau routier en fonction des limites du Sénégal
routes_sen <- st_intersection(x = routes, y = sen)


# st_write(obj = ..., dsn = "data/GeoSenegal.gpkg", layer = "...")


# library(mapview)
# mapview(USSEIN)



# Carte thématique 1 - Cercle proportionnel
library(mapsf)

mf_export(x = sen,
          filename = "img/carte_1.png",
          width = 800)

mf_theme(bg = "steelblue3", fg= "grey10")

mf_map(x = reg, col = NA, border = NA)
mf_map(pays, add = TRUE)

mf_shadow(reg, add = TRUE)
mf_map(reg, col = "grey95", add=T)

mf_map(routes_sen, 
       col = "grey50",
       lwd = 0.4,
       add = TRUE)

mf_map(x = loc_sen, 
       var = c("SERV_TT", "TYPELOCAL"),
       type = "prop_typo",
       pal = "Reds", 
       rev = TRUE,
       inches = 0.06,
       leg_pos = NA)

mf_annotation(x = USSEIN, 
              txt = "USSEIN", 
              halo = TRUE, 
              bg = "grey85",
              cex = 1.1)

text(x = 261744.7, 
     y = 1766915, 
     labels = "Océan\nAtlantique", 
     col="#FFFFFF99", cex = 0.65)

text(x = 456008.1, 
     y = 1490739, 
     labels = "Gambie", 
     col="#00000099", cex = 0.6)

text(x = 496293.2, 
     y = 1364960, 
     labels = "Guinée-Bissau", 
     col="#00000099", cex = 0.6)

text(x = 748298.6, 
     y = 1355112, 
     labels = "Guinée", 
     col="#00000099", cex = 0.6)

text(x = 875867.9, 
     y = 1541766, 
     labels = "Mali", 
     col="#00000099", cex = 0.6)

text(x = 683394.9, 
     y = 1818838, 
     labels = "Mauritanie", 
     col="#00000099", cex = 0.6)

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
          title_cex = 0.7,
          val_cex = 0.5,
          size = 0.6,
          frame = TRUE,
          bg = "#FFFFFF99",
          title = "Statut des localités")

mf_legend(type = "prop", 
          val = c(1,3,5,7,10), 
          inches = 0.06,
          title_cex = 0.7,
          title = "Nombre de\nservices",
          horiz = TRUE,
          frame = TRUE,
          bg = "#FFFFFF99",
          pos = "right")

mf_title("Répartition des localités sénégalaises en 2024", fg = "white")
mf_credits("Auteurs : Hugues Pecout\nSources : GADM & GeoSénégal, 2014", cex = 0.5)

dev.off()




################################################################################ 
# Nombre école dans le voisinage de USSEIN
################################################################################ 

st_crs(USSEIN)

# Calcul d'un buffer de 5 kilomètres
buf_5km <- st_buffer(USSEIN, 50000)

# intersection entre les appartement et le buffer
inters_loc_buff <- st_intersection(loc, buf_5km)

nb_loc_ecole_50km_USSEIN <- sum(inters_loc_buff$SERV_ECOLE)

cat(paste0("Le nombre de localités abritant (au moins) une école dans un rayon de 50 km autour de l'",
           USSEIN$NAME, " est de ", nb_loc_ecole_50km_USSEIN))



################################################################################ 
# Utilisation d’un maillage régulier 
################################################################################ 

# Créer une grille régulière avec st_make_grid()
grid <- st_make_grid(sen, cellsize = 15000, square = TRUE)
# Transformer la grille en objet sf avec st_sf()
grid <- st_sf(geometry = grid)

# Ajouter un identifiant unique, voir chapitre 3.7.6
grid$id_grid <- 1:nrow(grid)

# Compter le nombre de transaction dans chaque carreau
grid_loc<- st_intersects(grid, loc, sparse = TRUE)
grid$n_loc <- sapply(grid_loc, FUN = length)

# Découpage de la grille en fonction des communes (optionel)
grid_sen <- st_intersection(grid, sen)


# Justification de la discrétisation (statistiques, boxplot, histogramme, 
# beeswarm...)
hist(grid_sen$n_loc)

# Cartographie

library(mapsf)
mf_export(x = sen,
          filename = "img/carte_2.png",
          width = 800)

mf_theme(bg = "steelblue3", fg= "grey10")

mf_map(x = reg, col = NA, border = NA)
mf_map(pays, add = TRUE)

mf_shadow(reg, add = TRUE)
mf_map(reg, col = "grey95", add=T)


mf_map(x = grid_sen, 
       var = "n_loc", 
       type = "choro",
       add = T, 
       border = NA,
       leg_pos = "topright",
       leg_title = "Nombre de\nlocalités",
       leg_val_rnd = 0,
       breaks = c(0,0.1,1,2,3,4,5, max(grid_sen$n_loc)), 
       pal = "SunsetDark")

mf_map(routes_sen, lwd = .3, col ="#b5b3b5", add=T )
mf_map(loc_sen, add=T, col = "white", pch = ".", cex = .1)
mf_map(reg, col = NA, border = "white", add = T)


mf_annotation(x = USSEIN, 
              txt = "USSEIN", 
              halo = TRUE, 
              bg = "grey85",
              cex = 1.1)

text(x = 261744.7, 
     y = 1766915, 
     labels = "Océan\nAtlantique", 
     col="#FFFFFF99", cex = 0.65)

text(x = 456008.1, 
     y = 1490739, 
     labels = "Gambie", 
     col="#00000099", cex = 0.6)

text(x = 496293.2, 
     y = 1364960, 
     labels = "Guinée-Bissau", 
     col="#00000099", cex = 0.6)

text(x = 748298.6, 
     y = 1355112, 
     labels = "Guinée", 
     col="#00000099", cex = 0.6)

text(x = 875867.9, 
     y = 1541766, 
     labels = "Mali", 
     col="#00000099", cex = 0.6)

text(x = 683394.9, 
     y = 1818838, 
     labels = "Mauritanie", 
     col="#00000099", cex = 0.6)

mf_title("Nombre de localités sénégalaises dans un carroaye de 15km", fg = "white")
mf_credits("Auteurs : Hugues Pecout\nSources : GADM & GeoSénégal, 2014", cex = 0.5)

dev.off()



#---------------------------------------------------------------------------------------

# BONUS

library(potential)

# create_grid() is used to create a regular grid with the extent of an existing layer (x) and a specific resolution (res).
y <- create_grid(x = sen, res = 10000)

# create_matrix() is used to compute distances between objects.
d <- create_matrix(x = loc_sen, y = y)


# The potential() function computes potentials.
y$pot <- potential(x = loc_sen, y = y, d = d,
                   var = "SERV_POSTE", fun = "e",
                   span = 20000, beta = 2)

# It’s possible to express the potential relatively to its maximum in order to display more understandable values (Rich 1980).
y$pot2 <- 100 * y$pot / max(y$pot)




# It’s also possible to compute areas of equipotential with equipotential().
bks <- mf_get_breaks(y$pot, breaks = "q6")
iso <- equipotential(x = y, var = "pot", breaks = bks, mask = sen)




mf_theme(bg = "steelblue3", fg= "grey10")

mf_map(x = reg, col = NA, border = NA)
mf_map(pays, add = TRUE)

mf_shadow(reg, add = TRUE)
mf_map(reg, col = "grey95", add=T)


mf_map(x = iso, var = "min", type = "choro", 
       breaks = bks, 
       pal = hcl.colors(10, 'Teal'),
       lwd = .2,
       border = "#121725", 
       leg_pos = "topright",
       leg_val_rnd = 0,
       leg_title = "Potential of\nservices", add = TRUE)

mf_map(routes_sen, lwd = .3, col ="#b5b3b5", add=T )
mf_map(loc_sen, add=T, col = "white", pch = ".", cex = .1)
mf_map(reg, col = NA, border = "white", add = T)


mf_annotation(x = USSEIN, 
              txt = "USSEIN", 
              halo = TRUE, 
              bg = "grey85",
              cex = 1.1)

text(x = 261744.7, 
     y = 1766915, 
     labels = "Océan\nAtlantique", 
     col="#FFFFFF99", cex = 0.65)

text(x = 456008.1, 
     y = 1490739, 
     labels = "Gambie", 
     col="#00000099", cex = 0.6)

text(x = 496293.2, 
     y = 1364960, 
     labels = "Guinée-Bissau", 
     col="#00000099", cex = 0.6)

text(x = 748298.6, 
     y = 1355112, 
     labels = "Guinée", 
     col="#00000099", cex = 0.6)

text(x = 875867.9, 
     y = 1541766, 
     labels = "Mali", 
     col="#00000099", cex = 0.6)

text(x = 683394.9, 
     y = 1818838, 
     labels = "Mauritanie", 
     col="#00000099", cex = 0.6)

mf_title("Potentiel d'accès à des services", fg = "white")
mf_credits("Auteurs : Hugues Pecout\nSources : GADM & GeoSénégal, 2014", cex = 0.5)

