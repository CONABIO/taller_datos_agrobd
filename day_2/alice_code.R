
library(httr)
library(jsonlite)
library(dplyr)
library(stringr)

# Define desired number of records and limit. Number of pages and offset will be estimated based on the number of records to download
no_records<- no_records # this was estimated above with a query to count the total number of records, but you can also manually change it to a custom desired number
my_limit <- 1000 # max 1000
no_pages <- ceiling(no_records/my_limit)

## Define offseet.
# You can use the following loop:
# to calculate offset automatically basedon 
# on the number of pages needed.
my_offset<-0 # start in 0. Leave like this
for(i in 1:no_pages){ # loop to 
  my_offset<-c(my_offset, my_limit*i)
}

# Or you can define the offset manually 
# uncommenting the following line
# and commenting the loop above:
# offeset<-c(#manually define your vector) 

## create obtjet where to store downloaded data. Leave empity
data<-character()

##
## Loop to download the data from GraphQL using pagination
## 

for(i in c(1:length(my_offset))){
  
  # Define pagination
  pagination <- paste0("limit:", my_limit, ", offset:", my_offset[i])
  
  # Tell the user in which page we are processing:
  print(paste("processing pagination with", pagination))
  
  # Define query looping through desired pagination:
  my_query<- paste0("{
  registros(pagination: {",pagination, "}) {
    taxon(search: {field: taxon_id}) {
      genero
      especie
      raza
    }
    sitio(search: {field: id}) {
      latitud
      longitud
      altitud
      estado
    }
    proyecto
    procedencia
    fecha_colecta_observacion
    colector_observador
    coleccion
    numero_catalogo
    fecha_determinacion
    determinador
    licencia_uso
    referencias
    forma_citar
  }
}
")
  
  # Get data and add it to the already created df
  data<-rbind(data, get_from_graphQL(query=my_query, url="https://maices-siagro.conabio.gob.mx/api/graphql"))
  
  #end of loop
}
