# devtools::instAll_github('rstudio/leaflet')
# devtools::instAll_github('bhaskarvk/leaflet.extras')
library(sp)
library(shiny)
library(dplyr)
library(reshape2)
library(lubridate)

## set all maintopics and topics values
maintopics = as.character(unique(sm_full$TopicBig))
topics = as.character(unique(sm_full$Topic))

## set topics drop-down menu contents
subtopic_lst = list()
for (i in seq(44)) {
  subtopic_lst[[i]] = as.character(unique(sm_full$Topic[sm_full$TopicBig==maintopics[i]]))
}

## store data with locations
sm1 = sm_full[!(is.na(sm_full$Latitude) | is.na(sm_full$Longitude)),]

server <- function(input, output, session) {
  
  #### initialize the map
  output$circlemap <- renderLeaflet({
    leaflet() %>%
      addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
      ) %>%
      setView(lng = -118.45, lat = 34.02, zoom = 12)
  })
  
  
  output$heatmap <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = -118.45, lat = 34.02, zoom = 12)
      # addWebGLHeatmap(lng=~Longitude,lat=~Latitude,size=20,units='px',alphaRange=0.2)
  })
  
  ## A reactive syncornization of two maps 
  observe({
    new_center = input$heatmap_center
    new_zoom = input$heatmap_zoom
    leafletProxy('circlemap') %>%
      setView(lng=new_center$lng,lat=new_center$lat,zoom=new_zoom)
    # map1coords <- input$heatmap_bounds
    # map2proxy <- leafletProxy("circlemap")
    # map2proxy %>% fitBounds(lng1 = map1coords$east,
    #                         lat1 = map1coords$north,
    #                         lng2 = map1coords$west,
    #                         lat2 = map1coords$south)
  })
  
  ## A reactive expression that returns the set of requests that are in bounds right now
  # requestsInBounds <- reactive({
  #   if (is.null(input$heatmap_bounds))
  #     return(sm1[FALSE,])
  #   bounds <- input$heatmap_bounds
  #   latRng <- range(bounds$north, bounds$south)
  #   lngRng <- range(bounds$east, bounds$west)
  # 
  #   subset(sm1,
  #          Latitude >= latRng[1] & Latitude <= latRng[2] &
  #            Longitude >= lngRng[1] & Longitude <= lngRng[2])
  # })
  
  #### reset All the circles and auxiliary plots
  observeEvent(input$reset, {
    updateSelectInput(session, 'maintopic', selected = 'All')
    updateSelectInput(session, 'subtopic', selected = 'All')
    updateSelectInput(session, 'dept', selected = 'All')
    updateDateRangeInput(session, 'dateRange', start = Sys.Date()-365, end = Sys.Date())
  }) 

  #### draw the two maps, two charts and summaries
  observe({
    ## set the data for maps, charts and summaries
    # if (length(input$maintopic)==0 || length(input$dept)==0) {
    #   leafletProxy('circlemap') %>% clearGroup('circles')
    #   leafletProxy('heatmap') %>% clearGroup('heat')
    #   # more plots
    if (input$maintopic == 'All') {
      # sub topic menu update
      updateSelectInput(session, 'subtopic', choices = c('All',topics), selected = 'All')
      # print(1)
      # print(input$maintopic)
      # print(input$subtopic)
      if (input$subtopic == 'All' & input$dept == 'All') {
        circle_data = sm1 %>% filter(Request.Date>input$dates[1] & Request.Date<input$dates[2])
        heat_data = sm1 %>% filter(Request.Date>input$dates[1] & Request.Date<input$dates[2])
        full_data = sm_full %>% filter(Request.Date>input$dates[1] & Request.Date<input$dates[2])
      } else if (input$subtopic == 'All') {
        circle_data = sm1 %>% filter(Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        heat_data = sm1 %>% filter(Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        full_data = sm_full %>% filter(Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
      } else if (input$dept == 'All') {
        circle_data = sm1 %>% filter(Topic %in% input$subtopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        heat_data = sm1 %>% filter(Topic %in% input$subtopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        full_data = sm_full %>% filter(Topic %in% input$subtopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        # main topic menu update
        main = sm1 %>% filter(Topic %in% input$subtopic)
        updateSelectInput(session, 'maintopic', selected = main[1,'TopicBig'])
        # print(2)
        # print(input$maintopic)
        # print(input$subtopic)
      } else {
        circle_data = sm1 %>% filter(Topic %in% input$subtopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        heat_data = sm1 %>% filter(Topic %in% input$subtopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        full_data = sm_full %>% filter(Topic %in% input$subtopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        # main topic menu update
        main = sm1 %>% filter(Topic %in% input$subtopic)
        updateSelectInput(session, 'maintopic', selected = main[1,'TopicBig'])
      }
    } else {
      # print(3)
      # print(input$maintopic)
      # print(input$subtopic)
      # subtopic menu update for chaning main topic
      if (!input$subtopic %in% subtopic_lst[[which(maintopics==input$maintopic)]]) {
        updateSelectInput(session, 'subtopic', choices = c('All',subtopic_lst[[which(maintopics==input$maintopic)]]), selected = 'All')
        # print(4)
        # print(input$maintopic)
        # print(input$subtopic)
      }
      if (input$subtopic == 'All' & input$dept == 'All') {
        circle_data = sm1 %>% filter(TopicBig %in% input$maintopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        heat_data = sm1 %>% filter(TopicBig %in% input$maintopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        full_data = sm_full %>% filter(TopicBig %in% input$maintopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
      } else if (input$subtopic == 'All') {
        circle_data = sm1 %>% filter(TopicBig %in% input$maintopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        heat_data = sm1 %>% filter(TopicBig %in% input$maintopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        full_data = sm_full %>% filter(TopicBig %in% input$maintopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
      } else if (input$dept == 'All') {
        circle_data = sm1 %>% filter(TopicBig %in% input$maintopic & Topic %in% input$subtopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        heat_data = sm1 %>% filter(TopicBig %in% input$maintopic & Topic %in% input$subtopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        full_data = sm_full %>% filter(TopicBig %in% input$maintopic & Topic %in% input$subtopic & Request.Date>input$dates[1] & Request.Date<input$dates[2])
      } else {
        circle_data = sm1 %>% filter(TopicBig %in% input$maintopic & Topic %in% input$subtopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        heat_data = sm1 %>% filter(TopicBig %in% input$maintopic & Topic %in% input$subtopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
        full_data = sm_full %>% filter(TopicBig %in% input$maintopic & Topic %in% input$subtopic & Assigned.Department %in% input$dept & Request.Date>input$dates[1] & Request.Date<input$dates[2])
      }
    }

    ## Color and palette are set by the departments
    colorData <- circle_data$TopicBig
    pal <- colorFactor(palette = palette(rainbow(24)),
                       domain=maintopics)

    ## radius are set by response time for the data point divided by max rsponse time multiply 100
    # max_size <- max(circle_data$Days.to.Respond)

    ## add the circles
    leafletProxy("circlemap", data = circle_data) %>%
      clearGroup('circles') %>%
      addCircles(~Longitude, ~Latitude, radius=20, layerId=~Request.ID,
                 stroke=FALSE, fillOpacity=0.6, fillColor=pal(colorData), group='circles')
      # addLegend("bottomleft", pal=pal, values=colorData, title='Departments', layerId="colorLegend")

    ## add the heatmap
    leafletProxy("heatmap", data = heat_data) %>%
      clearGroup('heat') %>%
      addWebGLHeatmap(lng=~Longitude,lat=~Latitude,size=20,units='px',intensity=0.05,alphaRange=0.2,group='heat')

    ## auxiliary charts and summaries
    output$dept_analysis <- renderPlotly({
      # If no requests are in view, don't plot
      # if (nrow(requestsInBounds()) == 0)
      #   return(NULL)
      dept_analysis(input$maintopic,input$dates[1],input$dates[2])
    })

    output$time_analysis <- renderPlotly({
      # If no requests are in view, don't plot
      # if (nrow(requestsInBounds()) == 0)
      #   return(NULL)
      time_analysis(full_data)
    })

    output$numberOfRequest <- renderValueBox({
      valueBox(
        summaries(full_data, input$dates[1], input$dates[2], input$dept)[[1]], 
        "Total Number of Requests", icon = icon("list"),
        color = "light-blue"
      )
    })
    
    output$respondTime <- renderValueBox({
      valueBox(
        summaries(full_data, input$dates[1], input$dates[2], input$dept)[[2]],
        "Average Response Days", icon = icon("calendar-o"),
        color = "light-blue"
      )
    })
    
    output$countTop5 <- renderText({
      paste('Most Frequest Request Topics Top 5:',
            paste(summaries(full_data, input$dates[1], input$dates[2], input$dept)[[3]],collapse = ', '), 
            sep='\n')
    })
    
    output$timeBottom5 <- renderText({
      paste('Slowest Request Topics Top 5:',
            paste(summaries(full_data, input$dates[1], input$dates[2], input$dept)[[4]],collapse = ', '), 
            sep='\n')
    })
    
  })

  #### Show a pop-up for selected request
  showRequestPopup <- function(layer, lat, lng) {
    selectedRequest <- sm1[sm1$Request.ID == layer,]
    content <- as.character(tagList(
      sprintf("Request ID: %s", selectedRequest$Request.ID), tags$br(),
      sprintf("Topic group: %s", selectedRequest$TopicBig), tags$br(),
      sprintf("Request topic: %s", selectedRequest$Topic), tags$br(),
      sprintf("Request date: %s", selectedRequest$Request.Date), tags$br(),
      sprintf("Response date: %s", selectedRequest$Response.Date), tags$br(),
      sprintf("Days to respond: %s", selectedRequest$Days.to.Respond), tags$br()
    ))

    leafletProxy("circlemap") %>% addPopups(lng, lat, content, layerId = layer)
  }

  #### When map is clicked, clear pop-up
  observe({
    leafletProxy("circlemap") %>% clearPopups()
    event <- input$circlemap_shape_click
    if (is.null(event))
      return()

    # isolate({
    showRequestPopup(event$id, event$lat, event$lng)
    # })
  })
    
}

