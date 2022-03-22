library(minpack.lm)

scurve = function(x, center, width) {
  1 / (1 + exp(-(x - center) / width))
}

nls_model = nlsLM(
  trips ~ exp(
    const +
      b_weekday * weekday
  ) +
    b_weather * scurve(
      max_temperature + b_precip * precipitation + b_snow * snow_depth,
      weather_scurve_center,
      weather_scurve_width
    ),
  data = weather_data,
  start = list(const = 9,
               b_weekday = 1,
               b_weather = 25000,
               b_precip = -20, b_snow = -2,
               weather_scurve_center = 40,
               weather_scurve_width = 20))

summary(nls_model)
sqrt(mean(summary(nls_model)$residuals^2))

weather_data = weather_data %>%
  mutate(predicted_nls = predict(nls_model, newdata = weather_data),
         resid = trips - predicted_nls)

trips_by_temperature = weather_data %>%
  filter(weekday, precipitation == 0, snow_depth == 0) %>%
  mutate(temperature_bucket = floor(max_temperature / 5) * 5) %>%
  group_by(temperature_bucket) %>%
  summarize(actual = mean(trips),
            avg_max_temperature = mean(max_temperature),
            predicted = mean(predicted_nls),
            count = n()) %>%
  filter(count >= 3)

ggplot(data = trips_by_temperature, aes(x = avg_max_temperature, y = actual)) +
  geom_line(size = 1, color = "darkorange") + geom_point() +
  labs(title = "Temperature vs. NYC Citi Bike Daily Usage", subtitle = "01/01/2017–31/12/2018, Weekdays with no rain or snow") +
  scale_x_continuous("\nMax daily temperature (°F)") +
  scale_y_continuous("Average daily Citi Bike trips\n") +
  theme_bw()

ggsave(path = "Graphs", filename = "temperature_usage.png")

trips_by_precipitation = weather_data %>%
  filter(weekday, snow_depth == 0, max_temperature >= 60) %>%
  mutate(precip_bucket = cut(precipitation, c(0, 0.001, 0.2, 0.4, 0.6, 0.8, 1, 2), right = FALSE)) %>%
  group_by(precip_bucket) %>%
  summarize(actual = mean(trips),
            avg_precip = mean(precipitation),
            predicted = mean(predicted_nls),
            count = n()) %>%
  filter(count >= 3)


ggplot(data = trips_by_precipitation, aes(x = avg_precip, y = actual)) +
  geom_line(size = 1, color = "darkorange") + geom_point() +
  labs(title = "Precipitation vs. NYC Citi Bike Daily Usage", subtitle = "01/01/2017–31/12/2018, weekdays with max temperature ≥ 60 °F") +
  scale_x_continuous("\nDaily precipitation, inches") +
  scale_y_continuous("Average daily Citi Bike trips\n") +
  theme_bw()

ggsave(path = "Graphs", filename = "rain_usage.png")

trips_by_snow_depth = weather_data %>%
  filter(weekday, max_temperature < 40) %>%
  mutate(snow_bucket = cut(snow_depth, c(0, 0.001, 3, 6, 9, 12, 60), right = FALSE)) %>%
  group_by(snow_bucket) %>%
  summarize(actual = mean(trips),
            avg_snow_depth = mean(snow_depth),
            predicted = mean(predicted_nls),
            count = n()) %>%
  filter(count >= 3)

ggplot(data = trips_by_snow_depth, aes(x = avg_snow_depth, y = actual)) +
  geom_line(size = 1, color = "darkorange") + geom_point() +
  labs(title = "Snow Depth vs. NYC Citi Bike Daily Usage", subtitle = "01/2017–12/2018, weekdays with max temperature < 40 °F") +
  scale_x_continuous("\nCentral Park snow depth, inches") +
  scale_y_continuous("Average daily Citi Bike trips\n") +
  theme_bw()

ggsave(path = "Graphs", filename = "snow_usage.png")

ggplot(data = weather_data, aes(x = trips, y = predicted_nls)) +
  geom_point(alpha = 0.7, color = "darkslategray") + geom_abline(intercept = 0, slope = 1, color = "darkorange") +
  labs(title = "Citi Bike Model Predictions") +
  scale_x_continuous("\nActual trips per day") +
  scale_y_continuous("Predicted trips per day\n") +
  theme_bw()

ggsave(path = "Graphs", filename = "actual_predicted.png")

ggplot(data = weather_data, aes(x = resid)) +
  geom_histogram(binwidth = 1000, color = "darkorange",  fill="cornsilk", alpha=0.4) +
  scale_x_continuous("\nResidual (actual - expected)") +
  scale_y_continuous("Count\n") +
  labs(title = "Histogram of Model Residuals") + theme_bw()

ggsave(path = "Graphs", filename = "residuals.png")

predicted_by_date = weather_data %>%
  mutate(actual = rollsum(trips, k = 28, na.pad = TRUE, align = "right"),
         predicted = rollsum(predicted_nls, k = 28, na.pad = TRUE, align = "right")) %>%
  select(date, actual, predicted)

ggplot(data = melt(predicted_by_date, id = "date"),
       aes(x = as.Date(date), y = value, color = variable)) +
  geom_line(size = 1) +
  scale_x_date("Date") +
  scale_y_continuous("Trailing 28 day total\n") +
  scale_color_manual(values=c("#999999", "#E69F00")) +
  labs(title = "Citi Bike Monthly Trips: Actual vs. Model") +
  theme(legend.position = "bottom") + theme_bw()

ggsave(path = "Graphs", filename = "model_actual_pred.png")


cfs = coef(nls_model)
base = exp(cfs['const'] + cfs['b_weekday'])

weather_scurve = data.frame(
  temp = 0:100,
  pred = base + cfs['b_weather'] * scurve(0:100, cfs['weather_scurve_center'], cfs['weather_scurve_width'])
)

ggplot(data = weather_scurve, aes(x = temp, y = pred)) +
  geom_line(size = 1) +
  scale_x_continuous("\nMax daily temperature (°F)") +
  scale_y_continuous("Daily ridership\n") +
  labs(title = "Predicted Impact of Temperature on Citi Bike Ridership", subtitle = "Assumes non-holiday weekday with no rain or snow") +
  theme_bw()

ggsave(path = "Graphs", filename = "temp_impact.png")

ggplot(data = melt(select(trips_by_temperature, actual, predicted, avg_max_temperature), id = "avg_max_temperature"),
       aes(x = avg_max_temperature, y = value, color = variable)) +
  geom_line(size = 1) + 
  labs(title = "Predicted Impact of Temperature on Citi Bike Ridership", subtitle = "Actual vs. Predicted") +
  scale_x_continuous("\nMax daily temperature (°F)") +
  scale_y_continuous("Daily ridership\n") + 
  scale_color_manual(values=c("#999999", "#E69F00")) +
  theme_bw()

ggsave(path = "Graphs", filename = "temp_impact_2.png")

ggplot(data = melt(select(trips_by_precipitation, actual, predicted, avg_precip), id = "avg_precip"),
       aes(x = avg_precip, y = value, color = variable)) +
  geom_line(size = 1) +
  labs(title = "Predicted Impact of Precipitations on Citi Bike Ridership", subtitle = "Actual vs. Predicted") +
  scale_x_continuous("Daily precipitation, inches\n") +
  scale_y_continuous("Daily ridership\n") +
  scale_color_manual(values=c("#999999", "#E69F00")) +
  theme_bw()

ggsave(path = "Graphs", filename = "rain_impact.png")

ggplot(data = melt(select(trips_by_snow_depth, actual, predicted, avg_snow_depth), id = "avg_snow_depth"),
       aes(x = avg_snow_depth, y = value, color = variable)) +
  geom_line(size = 1) +
  labs(title = "Predicted Impact of Snow fall on Citi Bike Ridership", subtitle = "Actual vs. Predicted") +
  scale_x_continuous("Snow depth, inches\n") +
  scale_y_continuous("Daily ridership\n") +
  scale_color_manual(values=c("#999999", "#E69F00")) +
  theme_bw()

ggsave(path = "Graphs", filename = "snow_impact.png")

