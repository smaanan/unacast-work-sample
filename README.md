# Unacast Work Sample Data Scientist 2022

This repository contains the code and the supporting data files for recreating the answers I provided for the Unacast Work Sample Data Scientist 2022, which was about extracting insights from the NYC Citibike data set found [here](https://console.cloud.google.com/marketplace/details/city-of-new-york/nyc-citi-bike?filter=solution-type:dataset&q=citi&id=fcfc44d2-8502-4d73-ac4d-10030a80e48b).

Besides the database in the link above, I also used the NYC weather data from January 01 2017 to December 31 2018, which I downloaded from the National Climate Data Center, and the shapefile of NYC downloaded from the NYC Planning. Both data sets are attached above.

## The Data

Since my computer has a limited memory, I decided not to work with the whole data set, and instead chose to years, 2017 and 2018, to extract knowledge from. In the provided code I do not show how I compiled the data, but it was very simple; I just downloaded the zip files of every month from January 2017 to December 2018 and compiled them together using the readr package. There was no much coding involved at this level.

## The Analysis

The analysis of the NYC Citibike data consisted in three parts:

-   The first part was exploratory data analysis to understand how NYC Citibike was used over time and have better idea about the users;

-   The second part consisted of a geographic location data analysis to understand the pattern of movement between different types of users and changes over time;

-   The third part was a statistical analysis of the impact of weather factors on the use of NYC Citibike (Temperature, Rain, Snow).

## Explore and understand the dataset

### The most popular start station

```sql

SELECT
  start_station_name,
  COUNT(*) AS num_trips
FROM
  `bigquery-public-data.new_york.citibike_trips`
GROUP BY 1
ORDER BY num_trips DESC
LIMIT 1

```

## The most popular end station

```sql

SELECT
  end_station_name,
  COUNT(*) AS num_trips
FROM
  `bigquery-public-data.new_york.citibike_trips`
GROUP BY 1
ORDER BY num_trips DESC
LIMIT 1

```

## Gender distribution of Citibike users

```sql

SELECT 
100*SUM(CASE WHEN gender = 'male' THEN 1 ELSE 0 END)/ COUNT (*) Male_prc,
100*SUM(CASE WHEN gender = 'female' THEN 1 ELSE 0 END)/ COUNT (*) Female_prc,
FROM 
 `bigquery-public-data.new_york.citibike_trips`

```

## Trip duration distribution

## New bike stations introduced

```sql

SELECT
  EXTRACT (YEAR FROM starttime)  AS year,
  count(DISTINCT start_station_id)              AS Stations
FROM `bigquery-public-data.new_york.citibike_trips`
GROUP BY 1
ORDER BY year;
```
