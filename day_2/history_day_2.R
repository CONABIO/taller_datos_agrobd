library(tidyverse)
library(ggrepel)
library(janitor)
library(patchwork)
#library(xlsx)
library(readxl)
library(leaflet)
library(ggwordcloud)
library(ghibli)


Tabla <- read_excel("day_2/database/PGM_update2017.xlsx", sheet = "PGM_maices_Alex", col_names = T)

Tabla1 <- Tabla %>% 
  select(Estado, Municipio, Localidad, Longitud, Latitud, Genero, Especie, Complejo_racial, Raza_primaria, AltitudProfundidad)



#Distribución en el país
#Usemos primero el paquete de mxmaps para hacer hexágonos del país

library(mxmaps)


data("df_mxstate_2020")

df_mxstate_2020$value = df_mxstate_2020$afromexican / df_mxstate_2020$pop * 100
mxhexbin_choropleth(df_mxstate_2020, num_colors = 1,
                    title = "Percentage of the population that identifies as Afro-Mexican",
                    legend = "%")

head(Tabla1)

#Cambiar Estado a lower case

Tabla2 <- Tabla1 %>% 
  mutate(Estado = str_to_title(Estado))

base_data <- df_mxstate_2020 %>% 
  select(region, state_name) %>% 
  rename(Estado = state_name) %>% 
  right_join(Tabla2, by = "Estado")

#Ahora hagamos la sumatoria para la raza Tuxpeño

Tabla3 <- base_data %>% 
  select(region, Estado, Raza_primaria) %>% 
  mutate(value = 1) %>% 
  filter(Raza_primaria == "Celaya") %>% 
  group_by(region, Estado, Raza_primaria) %>% 
  summarise_all(sum) %>% 
  drop_na()

mxhexbin_choropleth(Tabla3, num_colors = 1,
                    title = "Maíz Tuxpeño en México",
                    legend = "registros")

# llenar los sitio que están en  negro

base_data1 <- df_mxstate_2020 %>% 
  select(region, state_name) %>% 
  rename(Estado = state_name)

Tabla4 <- Tabla3 %>% 
  full_join(base_data1, by = "Estado") %>% 
  select(region.y, Estado, value) %>% 
  replace_na(., list(value = 0)) %>% 
  rename(region = region.y) %>% 
  arrange(region)

mxhexbin_choropleth(Tabla4, num_colors = 1,
                    title = "Maíz Celaya en México",
                    legend = "registros")

# Ahora vamos hacerlo con leaflet el total de registros

m <- leaflet(data = Tabla2) %>% 
  addTiles() %>% 
  addMarkers(lng = Longitud , lat = Latitud, popup = Raza_primaria )
# No funciona...porqué?

# cambiar los nombres de las columnas x long y lat

Tabla2.1 <- Tabla2 %>% 
  rename(long = Longitud) %>% 
  rename(lat = Latitud) %>% 
  drop_na(long) %>% 
  filter(Raza_primaria != "ND") %>% 
  filter(Raza_primaria == "Tuxpeño")

m <- leaflet(data = Tabla2.1) %>% 
  addTiles() %>% 
  addCircleMarkers(~long , ~lat, popup = ~Raza_primaria, radius = 1, weight = 8, 
                   color = "yellow")

m

#Hagamos una función para ver los distintos 


myMap <- function(raza_maiz, color1){
  Tabla2.1 <- Tabla2 %>% 
    rename(long = Longitud) %>% 
    rename(lat = Latitud) %>% 
    drop_na(long) %>% 
    filter(Raza_primaria != "ND") %>% 
    filter(Raza_primaria == raza_maiz)
  
  m <- leaflet(data = Tabla2.1) %>% 
    addTiles() %>% 
    addCircleMarkers(~long , ~lat, popup = ~Raza_primaria, radius = 1, weight = 8, 
                     color = color1)
  
  m
}

myMap("Tuxpeño", "blue")
myMap("Chalqueño", "red")


ghibli_palette("PonyoLight")
ghibli_palettes
ghibli_palettes$MarnieDark2
# hagamos una nuve de palabras de todas las razas

ghibli_palettes$MononokeMedium

sample(ghibli_palettes$MononokeMedium,1)

myMap("Chalqueño", sample(ghibli_palettes$MononokeMedium,1))
myMap("Nal-tel", sample(ghibli_palettes$MononokeMedium,1))

head(Tabla1)

#Nube de palabras por complejo racial y por raza

Tabla_cloud <- Tabla1 %>% 
  select(Raza_primaria) %>% 
  mutate(value = 1) %>% 
  group_by(Raza_primaria) %>% 
  summarise_all(sum) %>% 
  dplyr::mutate(angle = 0 * sample(c(0, 1), n(), replace = TRUE, prob = c(50, 50))) %>% 
  filter(Raza_primaria != "ND") %>% 
  arrange(desc(value))
  

Figure3T <-  ggplot(Tabla_cloud, aes(label = Raza_primaria, size = log(value), color = value, 
                                angle = angle)) +
  geom_text_wordcloud(shape = "circle", eccentricity = 0.9, tstep = 0.02) +
  theme_minimal() +
  #scale_color_manual(aes(colour = nativa_col)) +
  #scale_colour_ghibli_c("MononokeDark", direction = -1) +
  labs(title = "Razas de maíces en México", x = "", y = "", fill = "") +
  theme(text = element_text(family = "Times"),
        axis.text = element_blank(),
        title = element_text(size = 14)) +
  scale_colour_ghibli_c("PonyoDark", direction = -1)

Figure3T

ggsave(filename = "word_cloud1.png", path = "day_2/figures/", width = 25, height = 20, 
       units = "cm",
       plot = Figure3T) 



