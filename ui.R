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
                  
                  box(p("This app allows you to extract values of a curated set of raster layers at supplied points
                  using", a("this", href = "https://github.com/disarm-platform/fn-covariate-extractor/blob/master/SPECS.md"),
                        " algorithm. 
                      You can run with your own data using the input boxes below, 
                        or using the prepopulated demo points (4 random points in Swaziland)"),

                    width = 2,
                    height = 800,
                    
                    # Conditional inputs for local file v GeoJSON/base64 string/URL
                    br(""),
                    radioButtons(
                      "GeoJSON_type",
                      "Points input type",
                      choices = c("Local file", "GeoJSON string or URL"),
                      selected = "GeoJSON string or URL"
                    ),
                    conditionalPanel(condition = "input.GeoJSON_type == 'Local file'",
                                     fileInput("geo_file_input", "")),
                    conditionalPanel(
                      condition = "input.GeoJSON_type == 'GeoJSON string or URL'",
                      textInput("geo_text_input", label = NULL, 
                                value = "https://www.dropbox.com/s/i7r4ws1hziy45m6/test_points.geojson?dl=1")
                    ),
                    
                    selectInput(
                      "layer",
                      "Layer",
                      c(
                        "elev_m",
                        "dist_to_water_m",
                        paste0("bioclim", 1:19)
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
