#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)


source("pages/supplier_ui.R", local=TRUE)
source("pages/readings_ui.R", local=TRUE)
source("pages/dashboard_ui.R", local=TRUE)

header <- dashboardHeader(title = "EnergyTracker")

sidebar <-
    dashboardSidebar(
        numericInput(
            inputId = "reading_input",
            label = NULL,
            value = 0,
            min = 0
        ),
        actionButton(
            inputId = "reading_button",
            label = NULL,
            icon = icon("plus"),
            width = "85%"
        ),
        sidebarMenu(
            id = "tabs",
            menuItem(
                tabName = "Dashboard",
                text = "Dashboard",
                icon = icon("chart-line")
            ),
            menuItem(
                tabName = "Readings",
                text = "Readings",
                icon = icon("table")
            ),
            menuItem(
                tabName = "Suppliers",
                text = "Suppliers",
                icon = icon("receipt")
            )
        )
    )

body <- dashboardBody(tabItems(dashboard_page,
                               readings_page,
                               supplier_page))

ui <- dashboardPage(header, sidebar, body)

# Define UI for application that draws a histogram
shinyUI(ui)
