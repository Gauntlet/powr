compute_intervals_values <- function(.data, suppliers)
{
	splyrs <- suppliers %>%
		mutate(
			started = as.Date(started),
			ended = as.Date(lag(started)),
			ended = case_when(is.na(ended) ~ as.Date("3099-01-01"),
							  TRUE ~ ended)
		) %>%
		distinct() %>%
		arrange(desc(started))
	
	data <- .data %>% 
		select(timestamp, reading) %>% 
		mutate(timestamp = as.POSIXct(timestamp, tz = Sys.timezone()),
			   date = as.Date(timestamp)) %>% 
		fuzzy_left_join(
			splyrs,
			by = c("date" = "started",
				   "date" = "ended"),
			match_fun = list(`>=`, `<`)
		) %>%
		as.data.frame() %>%
		arrange(timestamp) %>%
		mutate(
			interval_secs = as.numeric(difftime(timestamp, lag(timestamp), units = "secs")),
			interval_days = interval_secs / 3600 / 24,
			usage = reading - lag(reading),
			cost = ((day_rate * interval_days) + (unit_rate * usage)) / 100,
			cost_daily = cost / interval_days
		) %>%
		arrange(desc(timestamp)) %>%
		mutate(timestamp = as.character(timestamp)) %>% 
		select(timestamp, reading, interval_days, usage, cost, cost_daily)
	
	return(data)
}