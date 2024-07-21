install.packages("duckdbfs")
install.packages("sfarrow")

library(tidyverse)
library(duckdbfs)
library(sf)
library(sfarrow)

system.time({
blob <- open_dataset("SN.parquet")
blob %>%
  mutate(confidence_disc = floor(confidence * 10) / 10) %>%
  mutate(confidence_disc = if_else(is.na(confidence), 0, confidence_disc)) %>%
  group_by(confidence_disc) %>%
  summarise(
    nb_buildings = n(),
    mean_area = mean(area_in_meters, na.rm = TRUE),
    med_area = median(area_in_meters, na.rm = TRUE),
    Q1_area = quantile(area_in_meters, probs = 0.25, na.rm = TRUE),
    Q3_area = quantile(area_in_meters, probs = 0.75, na.rm = TRUE),
    stdev_area = sd(area_in_meters, na.rm = TRUE)
  ) %>%
  arrange(confidence_disc) %>%
  collect()
})
rm(blob)

system.time({
  blob2 <- sfarrow::st_read_parquet("SN.parquet")
  blob2 %>%
    st_drop_geometry() %>%
    mutate(confidence_disc = floor(confidence * 10) / 10) %>%
    mutate(confidence_disc = if_else(is.na(confidence), 0, confidence_disc)) %>%
    group_by(confidence_disc) %>%
    summarise(
      nb_buildings = n(),
      mean_area = mean(area_in_meters, na.rm = TRUE),
      med_area = median(area_in_meters, na.rm = TRUE),
      Q1_area = quantile(area_in_meters, probs = 0.25, na.rm = TRUE),
      Q3_area = quantile(area_in_meters, probs = 0.75, na.rm = TRUE),
      stdev_area = sd(area_in_meters, na.rm = TRUE)
    ) %>%
    arrange(confidence_disc) %>%
    collect()
})
