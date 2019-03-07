library(leaflet)
library(lubridate)
library(shinyBS)
library(shinydashboard)
# library(dashboardthemes)
library(shinyjs)

dashboardPage(
  dashboardHeader(),
  dashboardSidebar(disable = T),
  dashboardBody(useShinyjs(),
                
                fluidRow(
                  includeCSS("styles.css"),
                  
                  box(
                    width = 2,
                    height = 800,
                    
                    # Conditional inputs for local file v GeoJSON/base64 string/URL
                    h4("Points input type"),
                    radioButtons(
                      "GeoJSON_type",
                      "",
                      choices = c("Local file", "GeoJSON string or URL"),
                      selected = "Local file"
                    ),
                    conditionalPanel(condition = "input.GeoJSON_type == 'Local file'",
                                     fileInput("geo_file_input", "")),
                    conditionalPanel(
                      condition = "input.GeoJSON_type == 'GeoJSON string or URL'",
                      textInput("geo_text_input", label = NULL, placeholder = "GeoJSON string or URL")
                    ),
                    
                    selectInput(
                      "layer",
                      "Layer",
                      c(
                        "elev_m" = "elev_m",
                        "dist_to_water_m"
                      ),
                      multiple = TRUE
                    ),

                    
                    br(actionButton("goExtract", "RUN QUERY")),

                    conditionalPanel(condition = "input.goExtract > 0",
                                     br(h4("Download results")),  
                                     downloadButton("downloadData", "Download table"),
                                     downloadButton("downloadGeoData", "Download geojson"))

                  ),
                  
                  box(leafletOutput(
                    "output_map", height = 750, width = "100%"
                  ), height = 800, width = 10),
                  box(DT::DTOutput('output_table'), width = 12)
                ))
)
