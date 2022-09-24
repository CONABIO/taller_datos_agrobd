library(httr)
library(jsonlite)
library(dplyr)
library(stringr)

get_from_graphQL <- function(query1, url1){
  
  ### This function queries a GraphiQL API and outpus the data into a single data.frame 
  
  ## Arguments
  # query: a graphQL query. It should work if you try it in graphiQL server. Must be a character string.
  # url = url of the server to query. Must be a character string.
  
  ## Needed libraries:
  # library(httr)
  # library(jsonlite)
  # library(dplyr)
  # library(stringr)
  
  ### Function
  
  ##  query the server
  result <- POST(url1, body = list(query = query1), encode = c("json"))
  
  ## check server response
  satus_code <- result$status_code
  
  if (satus_code != 200) {
    print(paste0("Oh, oh: status code ", satus_code, ". Check your query and that the server is working"))
  }
  
  else{
    
    # get data from query result
    jsonResult <- content(result, as = "text") 
    
    # check if data downloaded without errors
    # graphiQL will send an error if there is a problem with the query and the data was not dowloaded properly, even if the connection status was 200. 
    ### FIX this when != TRUE because result is na
    errors <- grepl("errors*{10}", jsonResult)
    if (errors == TRUE) {
      print("Sorry :(, your data downloaded with errors, check your query and API server for details")
    } 
    else{ 
      # transform to json
      readableResult <- fromJSON(jsonResult, 
                                 flatten = T) # this TRUE is to combine the different lists into a single data frame (because data comming from different models is nested in lists)
      
      # get data
      data <- as.data.frame(readableResult$data[1]) 
      
      # rename colnames to original variable names
      x <- str_match(colnames(data), "\\w*$")[,1] # matches word characters (ie not the ".") at the end of the string
      colnames(data) <- x # assing new colnames
      return(data)
    }
  }
}

no_records <- get_from_graphQL(query = "{countRegistros}", 
                               url = "https://maices-siagro.conabio.gob.mx/api/graphql")

# change to vector, we don't need a df
no_records <- no_records[1,1]

# Define desired number of records and limit. Number of pages and offset will be estimated based on the number of records to download
no_records <- no_records # this was estimated above with a query to count the total number of records, but you can also manually change it to a custom desired number
my_limit <- 1000 # max 1000
no_pages <- ceiling(no_records/my_limit)

#no_pages <- 2

## Define offseet.
# You can use the following loop:
# to calculate offset automatically basedon 
# on the number of pages needed.
my_offset <- 0 # start in 0. Leave like this
for (i in 1:no_pages) { # loop to 
  my_offset <- c(my_offset, my_limit*i)
}

# Or you can define the offset manually 
# uncommenting the following line
# and commenting the loop above:
# offeset<-c(#manually define your vector) 

## create obtjet where to store downloaded data. Leave empity
data <- character()

##
## Loop to download the data from GraphQL using pagination
## 

for (i in c(1:length(my_offset))) {
  
  # Define pagination
  pagination <- paste0("limit:", my_limit, ", offset:", my_offset[i])
  
  # Tell the user in which page we are processing:
  print(paste("processing pagination with", pagination))
  
  # Define query looping through desired pagination:
  my_query <- paste0("{
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
  data <- rbind(data, get_from_graphQL(query = my_query, 
                                       url = "https://maices-siagro.conabio.gob.mx/api/graphql"))
  
  #end of loop
}

head(data)
dim(data)

writexl::write_xlsx(data, path = "day_2/database/Tabla1.xlsx", col_names = T)

