readings_page <- tabItem(tabName = "Readings",
						 box(width = "100%",
						 	title = "Import Readings",
						 	fileInput(inputId = "readings_import",
						 			  label = "Choose a CSV file"),
						 	tableOutput(outputId = "table_import_readings"),
						 	actionButton(inputId = "add_imported_readings_button", label = "Import")),
						 box(width = "100%",
						 	tableOutput(outputId = "table_readings")))