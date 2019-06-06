library(raster)
library(sp)
library(leaflet)
library(rjson)
library(httr)
library(readr)
library(DT)
library(sf)
library(RColorBrewer)
library(geojsonio)
library(base64enc)
library(MapPalettes)

source('utils.R')

# Define map
map <- leaflet() %>%
  addTiles(
    "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png"
  )

shinyServer(function(input, output) {
  
  map_data <- eventReactive(input$goExtract, {

    
  withProgress(message = 'Crunching data..',{
    
    geo_in <- input$geo_file_input
    
    # If input is local file, read in
    if (!is.null(geo_in)) {
      input_geo <- geojson_list(st_read(geo_in$datapath))
    } else{
      
      if(!(input$geo_text_input == "")){
          input_geo <- geojson_list(st_read(input$geo_text_input))
      }else{
          input_geo <- geojson_list(st_read(input$geo_demo_input))
      }
    }
    

    # Make call to algorithm
    input_data_list <- list(
      points = input_geo,
      layer_names = paste(input$layer)
    )

    response <-
      httr::POST(
        url = "https://faas.srv.disarm.io/function/fn-covariate-extractor",
        body = as.json(input_data_list),
        content_type_json(),
        timeout(90)
      )

    # Check status
    if (response$status_code != 200) {
      stop('Sorry, there was a problem with your request - check your inputs and try again')
    }
    
    # Return geojson as sf object
    response_content <- content(response)
    return(st_read(as.json(response_content$result)))
  })
})
  
  output$output_table <-
    
    DT::renderDT({
      
      output_table <- eventReactive(input$goExtract, {
        map_data_no_geom <- map_data()
        st_geometry(map_data_no_geom) <- NULL
        output_table <- as.data.frame(map_data_no_geom)
        DT::datatable(output_table,
                      options = list(pageLength = 15),
                      rownames = F)
      })
      
      return(output_table())
    })
  
  
  
  output$output_map <- renderLeaflet({
    
    if(input$goExtract[1]==0){
    return(map %>% setView(0,0,zoom=2))
    }
    
    output_map <- eventReactive(input$goExtract, {
      
      # Map data
      extracted_layer = as.data.frame(as.data.frame(map_data())[, input$layer])
      names(extracted_layer) <- input$layer
      
      # Define color palettes
      col_pals_list <-
        define_color_palettes(extracted_layer)
      
      # Define layer to hide
      if (length(input$layer) == 1) {
        to_hide <- NULL
      } else{
        to_hide <- input$layer[-1]
      }
      
      # Map
      map %>%
        add_all_map_layers(map_data(), col_pals_list, input$layer) %>%
        addLayersControl(overlayGroups = input$layer,
                         options = layersControlOptions(collapsed = FALSE)) %>%
        hideGroup(to_hide)
    })
    return(output_map())
    
  })
  
  # Handle downloads
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("extraction.csv")
    },
    content = function(file) {
      map_data_no_geom <- map_data()
      st_geometry(map_data_no_geom) <- NULL
      output_table <- as.data.frame(map_data_no_geom)
      write.csv(output_table, file, row.names = FALSE)
    }
  )
  
  output$downloadGeoData <- downloadHandler(
    filename = function() {
      paste("extraction.geojson")
    },
    content = function(file) {
      st_write(map_data(), file)
    }
  )
  
})
