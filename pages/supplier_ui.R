supplier_page <- tabItem(tabName = "Suppliers",
						 column(
						 	width = 12,
						 	box(
						 		title = "New Supplier",
						 		solidHeader = TRUE,
						 		height = "auto",
						 		width = 12,
						 		collapsible = TRUE,
						 		collapsed = TRUE,
						 		textInput(inputId = "supplierName", label = "Supplier Name"),
						 		dateInput(inputId = "supplierStartDate", label = "Start Date"),
						 		numericInput(
						 			inputId = "supplierDayRate",
						 			label = "Day Rate",
						 			value = 0
						 		),
						 		numericInput(
						 			inputId = "supplierUnitRate",
						 			label = "Unit Rate",
						 			value = 0
						 		),
						 		actionButton(
						 			inputId = "buttonAddSupplier",
						 			label = NULL,
						 			icon = icon("save")
						 		)
						 	),
						 	box(width = 12,
						 		tableOutput(outputId = "table_suppliers"))
						 ))
