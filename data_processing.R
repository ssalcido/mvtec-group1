# test file!

# load libraries
library(tidyverse)
library(lubridate)
library(generics)
library(cluster)
library(dplyr)
library(readxl)

# load data
covid <- read.csv("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv")
covid$date <- as.Date(covid$date, format = "%Y-%m-%d")
country_info <- read.csv("https://raw.githubusercontent.com/ssalcido/mvtec-group1/main/country-info.csv")

# opens access to using column names (???)
attach(covid)
attach(country_info)

# rename columns
names(country_info) #get list of names
newNames <- c('name', 'region', 'classification', 'gov_type', 'corruption', 'development', 
              'land_cond', 'GDP_per_energy', 'pop_total', 'urban_pop_p')
names(country_info) <- newNames

# reassign values
country_info$gov_type <- as_factor(country_info$gov_type)
levels(country_info$gov_type)
new_gov <- as_factor(c('const_mon', 'pres_rep', 'par_rep', 'semi_pres_rep', 'comm', 'in_trans',
                       'isl_semi_pres_rep', 'abs_mon', 'isl_par_rep', 'pres_lim_dem', 'isl_pres_rep',
                       'dict'))
country_info$gov_type <- new_gov[match(country_info$gov_type, levels(country_info$gov_type))]

country_info$corruption <- as_factor(country_info$corruption)
levels(country_info$corruption)
new_corruption <- as_factor(c('less', 'highly', 'NI'))
country_info$corruption <- new_corruption[match(country_info$corruption, levels(country_info$corruption))]

country_info$development <- as_factor(country_info$development)
levels(country_info$development)
new_dev <- as_factor(c('developing', 'transition', 'developed'))
country_info$development <- new_dev[match(country_info$development, levels(country_info$development))]

country_info$land_cond <- as_factor(country_info$land_cond)
levels(country_info$land_cond)
new_land <- as_factor(c('sea_access', 'landlocked', 'islands'))
country_info$land_cond <- new_land[match(country_info$land_cond, levels(country_info$land_cond))]

covid$tests_units <- as_factor(covid$tests_units)
levels(covid$tests_units)
new_units <- as_factor(c(NA, 'tests_perf', 'unclear', 'people_tested', 'samples_tested',
                         'people_tested_withNonPCR', 'tests_perf_withNonPCR'))
covid$tests_units <- new_units[match(covid$tests_units, levels(covid$tests_units))]

# split up covid data to aggregate
core_info <- covid %>%
  select(iso_code, continent, location)

averages <- covid %>%
  select(location, date, reproduction_rate, icu_patients, 
         icu_patients_per_million, hosp_patients, hosp_patients_per_million, weekly_icu_admissions,
         weekly_icu_admissions_per_million, weekly_hosp_admissions, weekly_hosp_admissions_per_million,
         tests_per_case, positive_rate, stringency_index)

sums <- covid %>%
  select(location, date, new_cases, new_cases_smoothed, new_deaths, 
         new_deaths_smoothed, new_cases_per_million, new_cases_smoothed_per_million, 
         new_deaths_per_million, new_deaths_smoothed_per_million, new_tests, new_tests_per_thousand,
         new_tests_smoothed, new_tests_smoothed_per_thousand)

largest <- covid %>%
  select(location, date, total_cases, total_deaths, total_cases_per_million,
         total_deaths_per_million, total_tests, total_tests_per_thousand)

constant <- covid %>%
  select(location, date, tests_units, population, population_density, median_age,
         aged_65_older, aged_70_older, gdp_per_capita, extreme_poverty, cardiovasc_death_rate,
         diabetes_prevalence, female_smokers, male_smokers, handwashing_facilities,
         hospital_beds_per_thousand, life_expectancy, human_development_index)

# aggregate
core_info <- core_info %>%
  group_by(iso_code, continent, location, week = week(date)) %>%
  summarise()

averages <- averages %>%
  group_by(location, week = week(date)) %>%
  summarise_at(c('reproduction_rate', 'icu_patients', 
                 'icu_patients_per_million', 'hosp_patients', 'hosp_patients_per_million', 'weekly_icu_admissions',
                 'weekly_icu_admissions_per_million', 'weekly_hosp_admissions', 'weekly_hosp_admissions_per_million',
                 'tests_per_case', 'positive_rate', 'stringency_index'), mean, na.rm=T)

sums <- sums %>%
  group_by(location, week = week(date)) %>%
  summarise_at(c('new_cases', 'new_cases_smoothed', 'new_deaths', 
                 'new_deaths_smoothed', 'new_cases_per_million', 'new_cases_smoothed_per_million', 
                 'new_deaths_per_million', 'new_deaths_smoothed_per_million', 'new_tests', 'new_tests_per_thousand',
                 'new_tests_smoothed', 'new_tests_smoothed_per_thousand'), sum, na.rm=T)

largest <- largest %>%
  group_by(location, week = week(date)) %>%
  summarise_at(c('total_cases', 'total_deaths', 'total_cases_per_million',
                 'total_deaths_per_million', 'total_tests', 'total_tests_per_thousand'), max)

constant <- constant %>%
  group_by(location, week = week(date)) %>%
  summarise_at(c('tests_units', 'population', 'population_density', 'median_age',
                 'aged_65_older', 'aged_70_older', 'gdp_per_capita', 'extreme_poverty', 'cardiovasc_death_rate',
                 'diabetes_prevalence', 'female_smokers', 'male_smokers', 'handwashing_facilities',
                 'hospital_beds_per_thousand', 'life_expectancy', 'human_development_index'), first)

## rejoin covid data
covid_agg <- core_info %>%
  left_join(averages, by = c('location', 'week')) %>%
  left_join(sums, by = c('location', 'week')) %>%
  left_join(largest, by = c('location', 'week')) %>%
  left_join(constant, by = c('location', 'week')) %>%
  left_join(country_info, by = c('location' = 'name'))

## export new dataframe as csv
write_csv(covid_agg, 'covid_agg.csv', col_names = T, append = F)
