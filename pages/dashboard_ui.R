library(ggplot2)

dashboard_page <- tabItem(tabName = "Dashboard",
						  column(
						  	width = 12,
						  	box(
						  		title = "Usage",
						  		width = "100%",
						  		plotOutput(outputId = "plot_usage")
						  	),
						  	infoBoxOutput(outputId = "info_daily_average_usage"),
						  	infoBoxOutput(outputId = "info_daily_average_cost")
						  ))
