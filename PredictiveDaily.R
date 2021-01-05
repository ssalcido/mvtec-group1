# load libraries
library(tidyverse)
library(lubridate)
library(generics)
library(GGally)
library(forecast)
library(hts)
library(tidyverse)
library(rlang)

# load data (direct from url)
covid <- read.csv("https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/owid-covid-data.csv")
covid$date <- as.Date(covid$date, format = "%Y-%m-%d")
country_info <- read.csv("https://raw.githubusercontent.com/ssalcido/mvtec-group1/main/country-info.csv")


# rename columns
names(country_info) #get list of names
newNames <- c('name', 'region', 'classification', 'gov_type', 'corruption', 'development', 
              'land_cond', 'GDP_per_energy', 'pop_total', 'urban_pop_p')
names(country_info) <- newNames

# reassign values
country_info$gov_type <- as_factor(country_info$gov_type)
levels(country_info$gov_type)
new_gov <- as_factor(c('pres_rep', 'par_rep', 'const_mon', 'semi_pres_rep', 'abs_mon', 
                       'comm', 'pres_lim_dem', 'isl_pres_rep',
                       'dict', 'in_trans', 'isl_semi_pres_rep', 'isl_par_rep')) 
country_info$gov_type <- new_gov[match(country_info$gov_type, levels(country_info$gov_type))]

country_info$corruption <- as_factor(country_info$corruption)
levels(country_info$corruption)
new_corruption <- as_factor(c('highly', 'less', 'NI'))
country_info$corruption <- new_corruption[match(country_info$corruption, levels(country_info$corruption))]

country_info$development <- as_factor(country_info$development)
levels(country_info$development)
new_dev <- as_factor(c('developing', 'transition', 'developed'))
country_info$development <- new_dev[match(country_info$development, levels(country_info$development))]

country_info$land_cond <- as_factor(country_info$land_cond)
levels(country_info$land_cond)
new_land <- as_factor(c('landlocked', 'sea_access', 'islands'))
country_info$land_cond <- new_land[match(country_info$land_cond, levels(country_info$land_cond))]

unique(covid$tests_units)
covid$tests_units[covid$tests_units == 'NA']  <- ""
covid$tests_units[covid$tests_units == "people tested"] <- "people_tested"
covid$tests_units[covid$tests_units == "tests performed"]  <- "tests_perf"
covid$tests_units[covid$tests_units == "units unclear"] <- "unclear"
covid$tests_units[covid$tests_units == "samples tested"]  <- "samples_tested"
covid$tests_units <- as_factor(covid$tests_units)
levels(covid$tests_units)

#merge datasets
covid_daily <- covid %>%
  left_join(country_info, by = c('location' = 'name'))


# filter data — include only variables that change over time, eliminate all NAs
toConsider <- covid_daily %>%
  select(location, date, total_deaths_per_million, reproduction_rate, 
         stringency_index, new_cases_smoothed,
         new_cases_smoothed_per_million, total_cases,  
         total_cases_per_million, total_tests, total_tests_per_thousand) 

toConsider <- toConsider[complete.cases(toConsider),] 

# create the models
toModel <- toConsider[toConsider$location %in% names(which(table(toConsider$location) >= 4)), ] # eliminate countries with less than 4 weeks of data/rows
countries <- unique(as.character(toModel$location)) 


#if forecasts objects exist use the created file (and so on accumulate the past predictions), if it doesn't (the first time it runs, create a new file)
if(exists('forecasts')) {
  return
} else {
  forecasts <- data.frame(matrix(ncol = 5, nrow = 0)) # remember to re-run this line if anything goes wrong with the for loop!!
  colnames <- c('location', 'date', 'fcasted_deaths_avg', 'fcasted_deaths_low', 'fcasted_deaths_high')
  colnames(forecasts) <- colnames }

coeffs <- data.frame(matrix(ncol = 6, nrow =0))
colnames2 <- c('location', 'rep_rate', 'string_index', 'new_cases_smoothed_per_mil',
               'total_cases_per_mil', 'total_tests')
colnames(coeffs) <- colnames2

for(i in countries) {
  # create time series for single country
  forTS <- toModel[toModel$location == i,]
  ts <- ts(forTS) # makes data frame into a time series
  ts <- ts[,2:dim(ts)[2]] # gets rid of first column, which is just the location
  
  # create model
  model <- tslm(total_deaths_per_million ~ reproduction_rate +  
                  stringency_index + new_cases_smoothed_per_million +   
                  total_cases_per_million + total_tests,
                data = ts)
  #checkresiduals(model) #prints out a separate plot for each country!
  
  # create new data
  lastMonthData <- tail(forTS, 30)
  # these can just be averaged for the past month
  new_repRate <- mean(lastMonthData %>% pull(reproduction_rate))
  new_strinIndex <- mean(lastMonthData %>% pull(stringency_index))
  new_newCases <- mean(lastMonthData %>% pull(new_cases_smoothed_per_million))
  # for these, we have to find the amount that the total cases/tests has been increasing by
  new_totalCases <- mean(diff(lastMonthData %>% pull(total_cases_per_million)))
  new_totalTests <- mean(diff(lastMonthData %>% pull(total_tests)))
  
  # find the most recent value for the total cases/tests column (will be the max by default)
  lastTotalCases <- lastMonthData %>% pull(total_cases_per_million) %>% max()
  lastTotalTests <- lastMonthData %>% pull(total_tests) %>% max()
  
  # combine data into one data frame
  newData <- data.frame(
    reproduction_rate = c(rep(new_repRate, 7)),
    stringency_index = c(rep(new_strinIndex, 7)),
    new_cases_smoothed_per_million = c(rep(new_newCases, 7)),
    total_cases_per_million = c(lastTotalCases + new_totalCases, 
                                lastTotalCases + 2*new_totalCases,
                                lastTotalCases + 3*new_totalCases,
                                lastTotalCases + 4*new_totalCases,
                                lastTotalCases + 5*new_totalCases,
                                lastTotalCases + 6*new_totalCases,
                                lastTotalCases + 7*new_totalCases),
    total_tests = c(lastTotalTests + new_totalTests,
                    lastTotalTests + 2*new_totalTests,
                    lastTotalTests + 3*new_totalTests,
                    lastTotalTests + 4*new_totalTests,
                    lastTotalTests + 5*new_totalTests,
                    lastTotalTests + 6*new_totalTests,
                    lastTotalTests + 7*new_totalTests))
  
  
  
  # create the forecast -- we could plot this directly in R!
  fcast <- forecast(model, newdata = newData)
  
  # get the data out of the forecast object
  maxWeek <- max(lastMonthData$date)
  
  current_country <- c(as.character(rep(i, 7))) 
  date <- as.character(c(Sys.Date() + days(1), Sys.Date() + days(2), Sys.Date() + days(3), Sys.Date() + days(4), Sys.Date() + days(5),Sys.Date() + days(6),Sys.Date() + days(7)))
  fcasted_deaths_avg <- fcast$mean
  fcasted_deaths_low <- fcast[['lower']][,2] # 95% confidence interval lower limit
  fcasted_deaths_high <- fcast[['upper']][,2] # 95% confidence interval upper limit
  elaboration <- as.character(c(Sys.Date()))
  
  fcasted_data <- cbind(current_country, date, fcasted_deaths_avg, 
                        fcasted_deaths_low, fcasted_deaths_high, elaboration )
  
  
  # combine all the forecasts into one big data frame
  forecasts <- rbind(forecasts, fcasted_data)
  forecasts$date <- as.Date(forecasts$date)
  forecasts$elaboration <- as.Date(forecasts$elaboration)
  
  # make another data frame containing the model coefficients
  new_coeffs <- cbind(i, fcast[['model']][["coefficients"]][['reproduction_rate']],
                      fcast[['model']][["coefficients"]][['stringency_index']],
                      fcast[['model']][["coefficients"]][['new_cases_smoothed_per_million']],
                      fcast[['model']][["coefficients"]][['total_cases_per_million']],
                      fcast[['model']][["coefficients"]][['total_tests']])
  coeffs <- rbind(coeffs, new_coeffs)
}
#Remove the predictions that are duplicate and keep only the newests ones
# & only keep those that predict what is going to happen after december 2020
forecasts2 <- forecasts %>% 
  arrange(desc(elaboration), .by_group = FALSE) %>%
  distinct(current_country, date, .keep_all = TRUE)


#Take real data and join with predictions in the same dataset
FromDecember <- toConsider %>%
  filter(date >= "2020-09-01")
AllData <- FromDecember %>%
  full_join(forecasts2, by = c('location' = 'current_country', 'date'))
write_csv2(AllData, 'forecasts.csv') # save the real data with the final data

