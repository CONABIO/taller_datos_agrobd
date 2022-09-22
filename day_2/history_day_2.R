library(tidyverse)
library(ggrepel)
library(janitor)
library(patchwork)
#library(xlsx)
library(readxl)
library(leaflet)
library(ggwordcloud)
library(ghibli)
library(treemapify)



Tabla <- read_excel("day_2/database/PGM_update2017.xlsx", sheet = "PGM_maices_Alex", col_names = T)

Tabla1 <- Tabla %>% 
  select(Estado, Municipio, Localidad, Longitud, Latitud, Genero, Especie, Complejo_racial, Raza_primaria, AltitudProfundidad)



#Distribución en el país
#Usemos primero el paquete de mxmaps para hacer hexágonos del país

library(mxmaps)


#data("df_mxstate_2020")
#
#df_mxstate_2020$value = df_mxstate_2020$afromexican / df_mxstate_2020$pop * 100
#mxhexbin_choropleth(df_mxstate_2020, num_colors = 1,
#                    title = "Percentage of the population that identifies as Afro-Mexican",
#                    legend = "%")

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
                    title = "Maíz Celaya en México",
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

# Ejercicio hacer una función para no repetir todo varias veces

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


# hacer un Treemap

#usemos Tabla_cloud

Tabla_cloud

#Colores para los géneros
razas2 <- Tabla_cloud %>% 
  select(Raza_primaria) %>% 
  distinct()

# otro paquete
library(randomcoloR)


TT <- nrow(razas2)
paletteTT <- distinctColorPalette(TT)


razas2 <- razas2 %>% 
  mutate(colores_razas = paletteTT)


Tabla_cloud1 <- Tabla_cloud %>% 
  left_join(razas2, by = "Raza_primaria")



fig_colores <- ggplot(Tabla_cloud1, aes(area = value, fill = colores_razas, label = Raza_primaria)) + 
  geom_treemap() +
  geom_treemap_text(colour = "black",
                    place = "centre",
                    size = 15) +
  scale_fill_manual(values = Tabla_cloud1$colores_razas, 
                    breaks = Tabla_cloud1$colores_razas) +
  labs(#title = "Figura 7. Colores de la mieles", 
    caption = "Los números al centro de cada cuadro representa el color determinado por los encuestados",
    x = "", y = "", fill = "") +
  theme(text = element_text(family = "Times"),
        legend.position = "none",
        axis.text = element_text(size = 8),
        title = element_text(size = 10)) 

fig_colores

# Pero mejor que sean los colores de los maíces.... busquemos una foto que nos guste de los maíces

# https://www.shutterstock.com/es/image-photo/glass-gem-earsvariety-rainbow-colored-corn-517603063

# https://rdrr.io/cran/colorfindr/man/get_colors.html 

library(colorfindr)


# Extract all colors except white
#pic4 <- system.file("extdata", "day_2/figures/maices.png", package = "colorfindr")
#uno <- get_colors(img =  pic4, exclude_col = "white")


#Prueba
#uno <- get_colors(img =  "day_2/figures/prueba.png", exclude_col = c("white", "black")) %>% 
#  mutate(numero = seq(1:n()))


uno <- get_colors(img =  "day_2/figures/maices.png", exclude_col = c("white", "black")) %>% 
  mutate(numero = seq(1:n()))


uno1 <- uno %>% 
  arrange(col_freq)

dim(Tabla_cloud)

uno2 <- sample(uno1$col_hex, nrow(Tabla_cloud))

head(Tabla_cloud)

Tabla_cloud2 <- Tabla_cloud %>% 
  mutate(colores_razas = uno2)

fig_colores <- ggplot(Tabla_cloud2, aes(area = value, fill = colores_razas, label = Raza_primaria)) + 
  geom_treemap() +
  geom_treemap_text(colour = "black",
                    place = "centre",
                    size = 15) +
  scale_fill_manual(values = Tabla_cloud2$colores_razas, 
                    breaks = Tabla_cloud2$colores_razas) +
  labs(#title = "Figura 7. Colores de la mieles", 
  #  caption = "Los números al centro de cada cuadro representa el color determinado por los encuestados",
    x = "", y = "", fill = "") +
  theme(text = element_text(family = "Times"),
        legend.position = "none",
        axis.text = element_text(size = 8),
        title = element_text(size = 10)) 

fig_colores

ggsave(filename = "tree_plot.png", path = "day_2/figures/", width = 35, height = 20, 
       units = "cm",
       plot = fig_colores) 


dim(uno1)

head(uno1)

#Visualización de la altitud

head(Tabla)
Altitud <- Tabla %>% 
  select(Raza_primaria, AltitudProfundidad) %>% 
  rename(Altitud = AltitudProfundidad) %>% 
  filter(Altitud != "ND") %>% 
  filter(Raza_primaria != "ND") %>% 
  filter(Altitud < 5000) %>% 
  drop_na()

figura1 <- ggplot(data = Altitud) +
 # geom_point(aes(x = Raza_primaria, y = Altitud)) +
  geom_jitter(aes(x = Raza_primaria, y = Altitud, colour = Raza_primaria), alpha = 0.1) +
  coord_flip() +
  theme_minimal() +
  theme(legend.position = "none") 

figura1

# vamos a hacer nuestros colores

colores1 <- data.frame(Raza_primaria = levels(as.factor(Tabla$Raza_primaria))) %>% 
  filter(Raza_primaria != "ND")

uno <- ghibli_palettes$MarnieDark1
dos <- ghibli_palettes$MarnieDark2
tres <- ghibli_palettes$PonyoDark
cuatro <- ghibli_palettes$LaputaDark
cinco <- ghibli_palettes$MononokeDark
seis <- ghibli_palettes$SpiritedDark
siete <- ghibli_palettes$YesterdayDark
ocho <- ghibli_palettes$TotoroDark
nueve <- ghibli_palettes$TotoroMedium
diez <- ghibli_palettes$MononokeMedium

colores <- c(uno, dos, tres, cuatro, cinco, seis, siete, ocho, nueve, diez)
colores <- colores[1:64]

colores1 <- colores1 %>% 
  bind_cols(colores) %>% 
  rename(colores = `...2`)

Altitud1 <- Altitud %>% 
  left_join(colores1, by = "Raza_primaria")

figura2 <- ggplot(data = Altitud1) +
  # geom_point(aes(x = Raza_primaria, y = Altitud)) +
  geom_jitter(aes(x = Raza_primaria, y = Altitud, colour = Raza_primaria), alpha = 0.3) +
  coord_flip() +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_color_manual(values = colores) + 
  labs(title = "Altitud de las diferentes\nRazas de Maíces en México", 
       x = "", y = "Altitud (metro)")

figura2

head(Altitud)

Altitud2 <- Altitud %>% 
  group_by(Raza_primaria) %>% 
  summarise_all(median) %>% 
  left_join(colores1, by = "Raza_primaria") %>% 
  mutate(posicion = seq(1:n())) %>% 
  mutate(origen = 0)


head(Altitud2)

figura3 <- ggplot(data = Altitud2) + 
  geom_curve(aes(x = origen, y = origen, xend = posicion, yend = Altitud, color = colores), curvature = 0.2, alpha = 0.5 ) +
  geom_point(aes(x = posicion, y = Altitud, color = colores), size = 10, alpha = 0.5) +
  scale_color_manual(values = colores) + 
  geom_text_repel(aes(x = posicion, y = Altitud, label = Raza_primaria)) + 
  theme_classic() + 
  theme(legend.position = "none") +
  geom_hline(yintercept = 1000, linetype = "dashed") +
  geom_hline(yintercept = 2000, linetype = "dashed") 
  

figura3
