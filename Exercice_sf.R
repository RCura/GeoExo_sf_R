###################################################################################################
#                                                                                                 #
#                             Geomatique avec R - Exercice appliqué                               #
#                                                                                                 #
###################################################################################################


###################################################################################################
# Chargement des librairies
###################################################################################################

library(sf)
library(mapsf)




###################################################################################################
# A. Import des données
###################################################################################################

# Lister les couches géographiques d'un fichier GeoPackage


# Import des données géographiques





###################################################################################################
# B. Séléction et intersection spatiale
###################################################################################################

## B.1 Séléctionnez (par attribut ou par localisation) uniquement les localités du Sénégal.

# Solution 1 - par attribut

# Solution 2 - par localisation




## B.2 Calculez le nombre de services présents dans chaque localité. 
#Assignez le résultat dans une nouvelle colonne de la couche géographique des localités sénégalaises.



## B.3 Découpez le réseau routier en fonction des limites du Sénégal.





###################################################################################################
# C. Carte thématique des localités
###################################################################################################







###################################################################################################
# D. Nombre d'écoles dans un rayon de 50km ?
###################################################################################################

## D.1. Calculez un buffer de 50 km autour d'USSEIN
# Vérification de l'unité de la projection


# Calcul d'un buffer de 50 kilomètres



## D.2. Séléctionnez les localités situées dans la zone tampon de 50km
# Intersection entre les localités et le buffer



## D.3 Combien de ces localités abritent au moins une école ?
# Nombre de localités dans un rayon de 50km ?


# Affichage du résultat dans la console
cat(paste0("Le nombre de localités abritant (au moins) une école dans un rayon de 50 km autour de l'",
           USSEIN$NAME, " est de ", ...))




###################################################################################################
# E. Utilisation d’un maillage régulier
###################################################################################################

## E.1 Créez un maillage régulier de carreaux de 50km de côté sur l'ensemble du Sénégal

# Transformer la grille en objet sf avec st_sf()

# Ajouter un identifiant unique, voir chapitre 3.7.6



## E.2 Récuperez le carreau d'appartenance (id) de chaque localité.


## E.3 Comptez le nombre de localités dans chacun des carreaux.


# E.4 Découpez la grille en fonction des limites du sénégal (optionel)






###################################################################################################
# F. Enregistrez la grille régulière dans le fichier GeoSenegal.gpkg
###################################################################################################







###################################################################################################
# G. Construisez une carte représentant le nombre de localités par carreau.
###################################################################################################

# Justification de la discrétisation (statistiques, boxplot, histogramme, beeswarm...) ?


## CARTE



