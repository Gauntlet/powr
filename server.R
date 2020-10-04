#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(RSQLite)
library(dplyr)
library(pool)
library(fuzzyjoin)
library(lubridate)

source("helpers/helpers.R", local = T)

pool <- dbPool(drv = RSQLite::SQLite(), dbname = "data.sqlite")

if (!pool::dbExistsTable(pool, "suppliers"))
{
    conn <- poolCheckout(pool)
    dbWithTransaction(conn,
                      {
                          dbSendQuery(
                              conn,
                              "CREATE TABLE suppliers (supplier TEXT, started TEXT, day_rate REAL, unit_rate REAL)"
                          )
                      })
    poolReturn(conn)
}

if (!pool::dbExistsTable(pool, "readings"))
{
    conn <- poolCheckout(pool)
    dbWithTransaction(conn,
                      {
                          dbSendQuery(conn,
                                      "CREATE TABLE readings (timestamp TEXT, reading INTEGER)")
                      })
    poolReturn(conn)
}

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    data <- reactiveValues(
        suppliers = data.frame(
            supplier = character(),
            started = character(),
            day_rate = numeric(),
            unit_rate = numeric()
        ),
        readings = data.frame(
            timestamp = character(),
            reading = integer(),
            interval = integer(),
            usage = integer(),
            cost = numeric()
        ),
        readings_import_sample = NULL
    )
    
    conn <- poolCheckout(pool)
    data$suppliers <- dbReadTable(conn, "suppliers") %>%
        arrange(desc(started))
    
    data$readings <- dbReadTable(conn, "readings") %>%
        arrange(desc(timestamp))
    poolReturn(conn)
    
    output$table_suppliers <-
        renderTable(data$suppliers, width = "100%")
    
    observeEvent(input$buttonAddSupplier,
                 {
                     conn <- poolCheckout(pool)
                     dbWithTransaction(conn,
                                       {
                                           insert_supplier <- dbSendQuery(
                                               conn,
                                               "INSERT INTO suppliers (supplier, started, day_rate, unit_rate) VALUES (?,?,?,?)"
                                           )
                                           vals <-
                                               list(
                                                   input$supplierName,
                                                   format(input$supplierStartDate, "%Y-%m-%d"),
                                                   input$supplierDayRate,
                                                   input$supplierUnitRate
                                               )
                                           dbBind(insert_supplier, vals)
                                       })
                     
                     data$suppliers <-
                         dbReadTable(conn, "suppliers") %>%
                         arrange(desc(started))
                     poolReturn(conn)
                 })
    
    
    output$table_readings <-
        renderTable(data$readings,
                    width = "100%")
    
    observeEvent(input$reading_button,
                 {
                     conn <- poolCheckout(pool)
                     dbWithTransaction(conn,
                                       {
                                           insert_reading <- dbSendQuery(conn,
                                                                         "INSERT INTO readings (timestamp, reading) VALUES (?,?)")
                                           vals <-
                                               list(as.character(Sys.time()),
                                                    input$reading_input)
                                           
                                           dbBind(insert_reading, vals)
                                           
                                       })
                     
                     data$readings <-
                         dbReadTable(conn, "readings") %>%
                         arrange(desc(timestamp))
                     poolReturn(conn)
                 })
    
    observeEvent(c(data$readings, data$suppliers),
                 {
                     rdngs <- data$readings %>% 
                         compute_intervals_values(data$suppliers)
                     
                     data$readings <- rdngs
                 })
    
    # output$plot_daily_usage <- renderPlot({
    #     
    # })
    
    output$table_import_readings <-
        renderTable({
            req(data$readings_import_sample)
            data$readings_import_sample %>%
                slice(1:5)
        }, width = "100%")
    
    observeEvent(input$readings_import,
                 {
                     data$readings_import_sample <-
                         read.csv(input$readings_import$datapath,
                                  header = TRUE) %>%
                         select(timestamp, reading) %>%
                         mutate(timestamp = as.character(
                             as.POSIXct(timestamp, format = "%d/%m/%Y %H:%M:%S", tz = Sys.timezone())
                         )) %>%
                         arrange(desc(timestamp))
                 })
    
    observeEvent(input$add_imported_readings_button,
                 {
                     req(data$readings_import_sample)
                     
                     conn <- poolCheckout(pool)
                     dbWithTransaction(conn,
                                       {
                                           res <-
                                               dbSendQuery(
                                                   conn,
                                                   'INSERT INTO readings (timestamp, reading) VALUES (:timestamp, :reading)',
                                                   data$readings_import_sample
                                               )
                                           dbClearResult(res)
                                       })
                     data$readings <-
                         dbReadTable(conn, "readings")
                     poolReturn(conn)
                     
                     data$readings_import_sample <- NULL
                 })
    
    
    output$plot_usage <- renderPlot({
        d <- data$readings %>%
            mutate(
                timestamp = as.POSIXct(timestamp, tz = Sys.timezone()),
                date = as.Date(timestamp),
                month = format(date, "%Y %b")
            ) %>%
            arrange(timestamp) %>%
            group_by(month) %>%
            slice(n()) %>% 
            ungroup() %>% 
            as.data.frame() %>% 
            compute_intervals_values(data$suppliers) %>% 
            mutate(timestamp = as.POSIXct(ceiling_date(as.Date(timestamp), unit = "month")-1), tz = Sys.timezone())
        
        coeff <- max(d$cost, na.rm = T) / max(d$usage, na.rm = T)
        
        d %>%
            ggplot() +
            geom_bar(aes(x = timestamp, y = usage),
                     stat = "identity") +
            geom_line(aes(
                x = timestamp,
                y = cost / coeff,
                col = "red"
            )) +
            geom_point(aes(
                x = timestamp,
                y = cost / coeff,
                col = "red",
                size = 5
            )) +
            scale_y_continuous(name = "Units Used",
                               sec.axis = sec_axis( ~ . * coeff, 
                                                    name = "Cost")) +
            scale_x_datetime(date_breaks = "1 month",
                             date_labels = "%Y %b") +
            theme(legend.position = "none")
    })
    
    
    output$info_daily_average_usage <- renderInfoBox({
        d <- data$readings %>%
            arrange(timestamp) %>%
            slice(1, n()) %>%
            data.frame()
        
        interval <-
            as.integer(as.Date(d$timestamp[2]) - as.Date(d$timestamp[1]))
        usage <- d$reading[2] - d$reading[1]
        
        infoBox(
            title = "Daily Usage",
            value = paste(format(usage, nsmall = 1, big.mark=","), "KWh"),
            icon = icon("bolt"),
            width = "100%"
        )
    })
    
    output$info_daily_average_cost <- renderInfoBox({
        
        splyrs <- data$suppliers %>%
            mutate(
                started = as.Date(started),
                ended = as.Date(lag(started)),
                ended = case_when(is.na(ended) ~ as.Date("3099-01-01"),
                                  TRUE ~ ended)
            ) %>%
            distinct() %>%
            arrange(desc(started))
        
        d <- data$readings %>%
            arrange(timestamp) %>%
            mutate(date = as.Date(timestamp)) %>% 
            group_by(date) %>%
            slice(n()) %>% 
            ungroup() %>% 
            as.data.frame() %>% 
            compute_intervals_values(data$suppliers)
        
        average_cost <- round(mean(d$cost_daily, na.rm = T), 2)
        sd_cost = round(sd(d$cost_daily, na.rm = T), 2)
        
        infoBox(
            title = "Daily Usage",
            value = paste0("\u00A3", average_cost, " \u00B1 ", sd_cost),
            icon = icon("credit-card"),
            width = "100%"
        )
    })
})
