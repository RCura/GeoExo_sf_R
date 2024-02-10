# Import des données géographique
library(sf)

st_layers("data/GeoSenegal.gpkg")

pays <- st_read(dsn = "data/GeoSenegal.gpkg", layer = "Pays_voisins")
sen <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Senegal")
reg <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Regions")
USSEIN <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "USSEIN")
# dep <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Departements")
# loc <-st_read(dsn = "data/GeoSenegal.gpkg", layer = "Localites")


# Import des données statistiques
pop <- read.csv("data/Population_2015_2024.csv")

# Jointure fond de carte région - données statistique région
reg <- merge(reg, pop, by.x="NAME_1", by.y="NAME")


# Carte thématique 1 - Cercle proportionnel
library(mapsf)

mf_export(x = sen,
          filename = "img/carte_1.png",
          width = 800)

mf_theme(bg = "steelblue3", fg= "grey10")

mf_map(x = sen, col = NA, border = NA)
mf_map(pays, add = TRUE)

mf_inset_on(x = "worldmap",cex = .16, pos = "topright")
mf_worldmap(sen)
mf_inset_off()

mf_shadow(sen, add = TRUE)
mf_map(reg, col = "grey95", add=T)

mf_map(x = reg, 
       var = "P2024",
       type = "prop",
       col = "indianred3",
       inches = 0.3,
       leg_pos = c(806488.1, 1730211),
       leg_frame = TRUE,
       leg_title_cex = 0.7,
       leg_val_cex = 0.5,
       leg_bg = "#FFFFFF99",
       leg_title = "Nombre d'habitants")

mf_annotation(x = USSEIN, 
              txt = "USSEIN", 
              halo = TRUE, 
              bg = "grey85",
              cex = 0.65)

mf_title("Répartition de la population au Sénégal, par régions en 2024", fg = "white")
mf_credits("Auteurs : Hugues Pecout\nSources : GADM & ANSD (2024)", cex = 0.5)

dev.off()


# Carte thématique 2 - Choroplèthe

# Creation variable area
reg$surface <- st_area(reg)
reg$surface
library(units)
reg$surface <- set_units(x= reg$surface, value = km^2)

reg$dens_pop24 <- reg$P2024/reg$surface

hist(log(reg$dens_pop24))
boxplot(reg$dens_pop24)

reg$dens_pop24 <-as.vector(reg$dens_pop24)
bornes <- c(min(reg$dens_pop24), 45, 100, 200, 500, max(reg$dens_pop24))

hist(log(reg$dens_pop24), breaks =30)
abline(v=log(bornes), col = "red")



#------------------

mf_export(x = sen, 
          filename = "img/carte_2.png",
          width = 800)

mf_theme(bg = "steelblue3", fg= "grey10")

mf_map(x = sen, col = NA, border = NA)
mf_map(pays, add = TRUE)

mf_shadow(sen, add = TRUE)

mf_map(x = reg, 
       var = "dens_pop24",
       type = "choro",
       breaks = bornes,
       pal = "Peach",
       leg_title = "Habitants par km2",
       add = TRUE)

mf_label(x = reg,
         var = "NAME_1",
         col= "black",
         halo = TRUE,
         bg = "grey85",
         cex = 0.7,
         overlap = FALSE, 
         lines = FALSE)


text(x = 261744.7, 
     y = 1766915, 
     labels = "Océan\nAtlantique", 
     col="#FFFFFF99", cex = 0.65)


mf_title("Densité de population au Sénégal, par régions en 2024", fg = "white")
mf_credits("Auteurs : Hugues Pecout\nSources : GADM & ANSD (2024)", cex = 0.5)

dev.off()

# Carte thématique 3 - Combinée

# Création variable - Taux Evolution de la population

# Creation variable area
reg$evo_pop_15_24 <- (reg$P2024 - reg$P2015) / reg$P2015 *100
hist(reg$evo_pop_15_24)



mf_export(x = sen, 
          filename = "img/carte_3.png",
          width = 800)


mf_theme(bg = "steelblue3", fg= "grey10")

mf_map(x = sen, col = NA, border = NA)
mf_map(pays, add = TRUE)

mf_shadow(sen, add = TRUE)
mf_map(reg, col = "grey95", add=T)

mf_map(x = reg, 
       var = c("P2024", "evo_pop_15_24"),
       type = "prop_choro",
       border = "grey50",
       lwd = 1,
       inches = 0.3,
       leg_title = c("Nombre d'habitants\nen 2024", "Taux d'évolution (%)\nentre 2015 et 2024"),
       leg_title_cex = 0.7,
       leg_val_cex = 0.5,
       leg_frame = TRUE,
       leg_bg = "#FFFFFF99",
       breaks = "quantile",
       pal = "Magenta",
       leg_val_rnd = c(0,1))

mf_annotation(x = USSEIN, 
              txt = "USSEIN", 
              halo = TRUE, 
              bg = "grey85",
              cex = 0.65)

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


mf_title("Évolution de la population au Sénégal, 2015-2024", fg = "white")
mf_credits("Auteurs : Hugues Pecout\nSources : GADM & ANSD (2024)", cex = 0.5)


dev.off()

