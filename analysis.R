library(tidyverse)
library(dplyr)
library(lubridate)
library(ggplot2)
library(reshape2)
library(zoo)
library(scales)
library(rgdal)
library(maptools)
library(readr)
library(gpclib)
gpclibPermit()

# Plot birth year distribution of NYC Citibike Users

x.min <- quantile(citibank$birth.year, 0.001)

ggplot(citibank) + geom_histogram(aes(birth.year), color = "darkorange",  fill="cornsilk", alpha=0.4) +
  geom_vline(xintercept = 1988, linetype = "dashed", color = "darkgreen") +
  labs(title = "Birth Year of NYC Citibike Users", subtitle = "Data from 01/01/2018 to 31/12/2019") +
  xlab("Birth Year") + ylab("Trips") +
  xlim(c(x.min, 2002)) + theme_bw()

ggsave(path = "Graphs", filename = "birth_year_histogram.png")

# Plot distribution of Subscribers and Customers among NYC Citibike Users

ggplot(citibank) + 
  geom_bar(aes(usertype, y = (..count..)/sum(..count..)), color = "darkorange",  fill="cornsilk", alpha=0.4, width=0.3) + ylab("Proportion") +
  labs(title = "Share of Subscribers and Customers among NYC Citibike Users", subtitle = "Data from 01/01/2018 to 31/12/2019") +
  xlab("User Type") + ylab("Proportion") +
  theme_bw()

ggsave(path = "Graphs", filename = "user_type.png")

# Plot distribution of Male and Female Users of NYC Citibike

ggplot(citibank) + 
  geom_bar(aes(gender, y = (..count..)/sum(..count..)), color = "darkorange",  fill="cornsilk", alpha=0.4, width=0.3) + ylab("Proportion") +
  labs(title = "Gender Distribution of NYC Citibike Users", subtitle = "Data from 01/01/2018 to 31/12/2019") +
  xlab("Gender") + ylab("Proportion") +
  theme_bw()

ggsave(path = "Graphs", filename = "male_female_users.png")

# Density plot of Male and Female NYC Citibike Users

citibank %>% 
  filter(gender != "UNKNOWN") %>% 
  ggplot(.)  + 
  geom_density(aes(birth.year,group=gender, fill=gender, colour=gender), adjust=3, alpha=0.1) +
  labs(title = "Age Distribution of Male and Female Citibike Users", subtitle = "Data from 01/01/2018 to 31/12/2019") +
  scale_fill_brewer(palette="Dark2") + scale_color_brewer(palette="Dark2") +
  xlab("Birth Year") + ylab("Density") + xlim(c(x.min, 2002)) +
  theme_bw()

ggsave(path = "Graphs", filename = "male_female_density.png")

# Histogram of Trip Duration of NYC Citibike

citibank  <- mutate(citibank, tripduration.min = tripduration/60)

x.max <- quantile(citibank$tripduration.min, 0.99)

ggplot(citibank) + geom_histogram(aes(tripduration.min), color = "darkorange",  fill="cornsilk", alpha=0.4) +
  labs(title = "Dsitribution of Trip Duration of NYC Citibike Users", subtitle = "Data from 01/01/2018 to 31/12/2019") +
  xlab("Trip Duration (in minutes)") + ylab("Number of Trips") +
  xlim(c(0, x.max)) + theme_bw()

ggsave(path = "Graphs", filename = "trip_duration_hist.png")

# Daily Use

citibank$weekday = wday(citibank$starttime, label = TRUE)

citibank$hour    = as.factor(hour(citibank$starttime))

ggplot(citibank) +
  geom_bar(aes(x=weekday, y=(..count..)/sum(..count..)), color = "darkorange",  fill="cornsilk", alpha=0.4) +
  labs(title = "Percentage of Trips in Each Day of the Week", subtitle = "Data from 01/01/2018 to 31/12/2019") +
  xlab("Weekday") + ylab("") +
  theme_bw()

ggsave(path = "Graphs", filename = "weekday_use.png")

ggplot(citibank) + 
  geom_bar(aes(x=weekday, y=(..count..)/sum(..count..), fill=usertype), position = position_stack(reverse = TRUE), color = "darkorange", alpha=0.4) +
  labs(title = "Percentage of Daily Trips by User Type", subtitle = "Data from 01/01/2018 to 31/12/2019", fill = "User Type") +
  scale_fill_manual(values = c("darkorange3","cornsilk")) +
  xlab("Weekday") + ylab("") +
  theme_bw()

ggsave(path = "Graphs", filename = "weekday_user_type.png")

# Hourly Use

ggplot(citibank) +
  geom_bar(aes(x=hour, y=(..count..)/sum(..count..)), color = "darkorange",  fill="cornsilk", alpha=0.4) +
  labs(title = "Percentage of Trips in Each Hour of the Day", subtitle = "Data from 01/01/2018 to 31/12/2019") +
  xlab("Hour") + ylab("") +
  theme_bw()

ggsave(path = "Graphs", filename = "hourly_use.png")

ggplot(citibank) + 
  geom_bar(aes(x=hour, y=(..count..)/sum(..count..), fill=usertype), position = position_stack(reverse = TRUE), color = "darkorange", alpha=0.4) +
  labs(title = "Percentage of Hourly Trips by User Type", subtitle = "Data from 01/01/2018 to 31/12/2019", fill = "User Type") +
  scale_fill_manual(values = c("darkorange3","cornsilk")) +
  xlab("Hour") + ylab("") +
  theme_bw()

ggsave(path = "Graphs", filename = "hourly_user_type.png")

# Geo location analysis

# Load NYC map

tracts = spTransform(readOGR("nyct2020_22a", layer = "nyct2020"), CRS("+proj=longlat +datum=WGS84"))
tracts@data$id = as.character(as.numeric(rownames(tracts@data)) + 1)
tracts.points = fortify(tracts, region = "id")
tracts.map = inner_join(tracts.points, tracts@data, by = "id")

nyc_map = tracts.map
ex_staten_island_map = filter(tracts.map, BoroName != "Staten Island")
manhattan_map = filter(tracts.map, BoroName == "Manhattan")
governors_island = filter(ex_staten_island_map, BoroCT2020 == "1000500")

# Location from which trips started 2013 Map

names(Dec_2013) = make.names(names(Dec_2013))

Dec_2013 = na.omit(Dec_2013)

from <- data.frame(lon=as.numeric(Dec_2013$start.station.longitude), lat=as.numeric(Dec_2013$start.station.latitude))

to   <- data.frame(lon=as.numeric(Dec_2013$end.station.longitude), lat=as.numeric(Dec_2013$end.station.latitude))

ggplot() +
  geom_polygon(data = nyc_map, aes(x = long, y = lat, group = group), fill = "white", color = "cornsilk2") +
  coord_sf(xlim = c(-74.10, -73.90), ylim = c(40.65, 40.81)) + xlab("Longitude") + ylab("Latitude") +
  labs(title = "Trips Starting Location", subtitle = "Data from December 2013") +
  stat_density2d(aes(x=lon, y=lat, fill = ..level..), alpha=0.6, size = 2, bins = 8, data=from, geom="polygon") +
  theme(panel.background = element_rect(fill = 'aliceblue')) 

ggsave(path = "Graphs", filename = "trips_starting_location_2013.png")

# Locations from which trips started 2019 Map

from <- data.frame(lon=as.numeric(Dec_2019$start.station.longitude), lat=as.numeric(Dec_2019$start.station.latitude))

to   <- data.frame(lon=as.numeric(Dec_2019$end.station.longitude), lat=as.numeric(Dec_2019$end.station.latitude))

ggplot() +
  geom_polygon(data = nyc_map, aes(x = long, y = lat, group = group), fill = "white", color = "cornsilk2") +
  coord_sf(xlim = c(-74.10, -73.90), ylim = c(40.65, 40.81)) + xlab("Longitude") + ylab("Latitude") +
  labs(title = "Trips Starting Location", subtitle = "Data from December 2019") +
  stat_density2d(aes(x=lon, y=lat, fill = ..level..), alpha=0.6, size = 2, bins = 8, data=from, geom="polygon") +
  theme(panel.background = element_rect(fill = 'aliceblue')) 

ggsave(path = "Graphs", filename = "trips_starting_location_2019.png")

# Comparison between starting locations of Customers and Subscribers

from1   <- data.frame(from, usertype=Dec_2019$usertype)

ggplot() +
  geom_polygon(data = nyc_map, aes(x = long, y = lat, group = group), fill = "white", color = "cornsilk2") +
  coord_sf(xlim = c(-74.10, -73.90), ylim = c(40.65, 40.81)) + xlab("Longitude") + ylab("Latitude") +
  labs(title = "Trips Starting Location", subtitle = "Comparison Between Customers and Subscribers December 2019") +
  stat_density2d(aes(x=lon, y=lat, fill = ..level..), alpha=0.6, size = 2, bins = 8, data=from1, geom="polygon") +
  facet_grid(~ usertype) +
  theme(panel.background = element_rect(fill = 'aliceblue'))

ggsave(path = "Graphs", filename = "trips_user_location_2019.png")

# Comparison of starting locations of Males and Females

Dec_2019$gender = as.factor(Dec_2019$gender)

levels(Dec_2019$gender) = c("UNKNOWN", "MALE", "FEMALE")

from.gender   <- data.frame(from, gender=Dec_2019$gender)

from.gender   <- subset(from.gender, gender %in% c("MALE","FEMALE"))

ggplot() +
  geom_polygon(data = nyc_map, aes(x = long, y = lat, group = group), fill = "white", color = "cornsilk2") +
  coord_sf(xlim = c(-74.10, -73.90), ylim = c(40.65, 40.81)) + xlab("Longitude") + ylab("Latitude") +
  labs(title = "Trips Starting Location", subtitle = "Comparison Between Men and Women December 2019") +
  stat_density2d(aes(x=lon, y=lat, fill = ..level..), alpha=0.6, size = 2, bins = 8, data=from.gender, geom="polygon") +
  facet_grid(~ gender) +
  theme(panel.background = element_rect(fill = 'aliceblue'))

ggsave(path = "Graphs", filename = "trips_gender_location_2019.png")

# Expansion of NYC Citibike Stations between 2013 and 2019

dist1 = Dec_2013 %>% 
  group_by(start.station.id) %>% 
  summarise(count = n()) %>% 
  left_join(., Dec_2013 %>% select(start.station.id, start.station.latitude, start.station.longitude), by = c("start.station.id"))

dist2 = Dec_2019 %>% 
  group_by(start.station.id) %>% 
  summarise(count = n()) %>% 
  left_join(., Dec_2019 %>% select(start.station.id, start.station.latitude, start.station.longitude), by = c("start.station.id"))

dist1 = unique(dist1)

dist2 = unique(dist2)

ggplot() +
  geom_polygon(data = nyc_map, aes(x = long, y = lat, group = group), fill = "white", color = "cornsilk2") +
  coord_sf(xlim = c(-74.05, -73.90), ylim = c(40.65, 40.83)) + xlab("Longitude") + ylab("Latitude") +
  labs(title = "Ctibike Bike Stations", subtitle = "Data from December 2019") +
  geom_point(data = dist2, aes(x = start.station.longitude, y = start.station.latitude), color = "red", size = 1) +
  theme(panel.background = element_rect(fill = 'aliceblue'), plot.margin=grid::unit(c(0,0,0,0), "mm")) 

ggsave(path = "Graphs", filename = "bike_stations_2013.png")

ggplot() +
  geom_polygon(data = nyc_map, aes(x = long, y = lat, group = group), fill = "white", color = "cornsilk2") +
  coord_sf(xlim = c(-74.05, -73.90), ylim = c(40.65, 40.83)) + xlab("Longitude") + ylab("Latitude") +
  labs(title = "Ctibike Bike Stations", subtitle = "Data from December 2013") +
  geom_point(data = dist1, aes(x = start.station.longitude, y = start.station.latitude), color = "red", size = 1) +
  theme(panel.background = element_rect(fill = 'aliceblue'), plot.margin=grid::unit(c(0,0,0,0), "mm"))

ggsave(path = "Graphs", filename = "bike_stations_2019.png")

# NYC Citibike Station Activity

station.info <- Dec_2019 %>%
group_by(start.station.id) %>%
summarise(lat=as.numeric(start.station.latitude[1]),
long=as.numeric(start.station.longitude[1]),
name=start.station.name[1],
n.trips=n())

ggplot() +
  geom_polygon(data = nyc_map, aes(x = long, y = lat, group = group), fill = "white", color = "cornsilk2") +
  coord_sf(xlim = c(-74.05, -73.90), ylim = c(40.65, 40.83)) + xlab("Longitude") + ylab("Latitude") +
  labs(title = "Ctibike Stations Activity", subtitle = "Data from December 2019") +
  geom_point(data = station.info, aes(x = long, y = lat, color = n.trips), size = 1) +
  scale_colour_gradient(high="red",low="green") + 
  theme(panel.background = element_rect(fill = 'aliceblue'))

ggsave(path = "Graphs", filename = "stations_activity_2019.png")
