library(sf)
library(lubridate)
library(terra)
library(glue)
library(ncdf4)
library(cmsafops)
library(elevatr)
library(tidyverse)

loggers <- read_csv(file.path("data/loggers.csv"))
crs_loggers <- 4326
loggers_sf <- st_as_sf(loggers, coords = c("lon", "lat"), crs = crs_loggers)

loggers_elev <- get_elev_point(loggers_sf, prj = crs_loggers, src = "epqs")

logger_data <- list.files(path = "data", pattern = "US_DEV_.*.csv", full.names = TRUE) %>%
    map_df(~ read_csv(., skip = 1, col_names = c("X", "Date", "Temp", "target_region", "peak", "aspect", "code"))) %>%
    mutate(
        Date = parse_date_time(Date, orders = "mdY HM"),
        Year = year(Date),
        Yday = yday(Date),
        Temp = (Temp - 32) * 5/9
    )

logger_temp_data <- logger_data %>%
    group_by(peak, Year, Yday, aspect) %>%
    summarize(
        Tavg = mean(Temp),
        Tmin = min(Temp),
        Tmax = max(Temp)
    )


### Download tmmn and tmmx data from MACA thredds NCSS
tmmx_url <- "http://thredds.northwestknowledge.net:8080/thredds/dodsC/agg_met_tmmx_1979_CurrentYear_CONUS.nc#fillmismatch"
tmmx_ds <- nc_open(tmmx_url)
selpoint.multi("daily_maximum_temperature", nc=tmmx_ds, outpath = "data/gridmet-tmmx/", lon1 = loggers$lon, lat1 = loggers$lat, station_names = loggers$Logger, format = "csv", verbose = TRUE)

tmmn_url <- "http://thredds.northwestknowledge.net:8080/thredds/dodsC/agg_met_tmmn_1979_CurrentYear_CONUS.nc#fillmismatch"
tmmn_ds <- nc_open(tmmn_url)
selpoint.multi("daily_minimum_temperature", nc=tmmn_ds, outpath = "data/gridmet-tmmn/", lon1 = loggers$lon, lat1 = loggers$lat, station_names = loggers$Logger, format = "csv", verbose = TRUE)

gridmet_all <- tibble()
for (logger in loggers$Logger) {
    print(logger)
    tmmn <- read_delim(glue("data/gridmet-tmmn/{logger}.csv"), skip = 1, delim = ";", col_names = c("Date", "tmmn", "lon", "lat"))
    tmax <- read_delim(glue("data/gridmet-tmmx/{logger}.csv"), skip = 1, delim = ";", col_names = c("Date", "tmmx", "lon", "lat"))
    gridmet_all <- bind_rows(gridmet_all, left_join(tmmn, tmax, by = c("Date", "lat", "lon")) %>%
        mutate(
            Logger = logger,
            Tmin = tmmn - 273.15,
            Tmax = tmmx - 273.15,
            Tavg = (Tmin + Tmax) / 2,
            Year = year(Date),
            Yday = yday(Date),
            peak = case_match(Logger,
                "dev_tel" ~ "TEL",
                "dev_ben" ~ "BEN",
                "dev_mid" ~ "MID",
                "dev_low" ~ "LOW"
            )
        ))
}


combined_temp <- left_join(logger_temp_data, gridmet_all, by = c("peak", "Year", "Yday"), suffix = c(".logger", ".gridmet")) %>%
    mutate(bias_tavg = Tavg.logger - Tavg.gridmet,
           bias_tmin = Tmin.logger - Tmin.gridmet,
           bias_tmax = Tmax.logger - Tmax.gridmet)

## Average Temps
combined_temp %>%
    ggplot() +
    geom_line(mapping = aes(x = Date, y = Tavg.logger), color = "blue") +
    facet_wrap(~ peak + aspect, scales = "fixed", ncol = 4) +
    geom_line(mapping = aes(x = Date, y = Tavg.gridmet), color = "red")

## Max Temps
combined_temp %>%
    ggplot() +
    geom_line(mapping = aes(x = Date, y = Tmax.logger), color = "blue") +
    facet_wrap(~ peak + aspect, scales = "fixed", ncol = 4) +
    geom_line(mapping = aes(x = Date, y = Tmax.gridmet), color = "red")

## Min Temps
combined_temp %>%
    ggplot() +
    geom_line(mapping = aes(x = Date, y = Tmin.logger), color = "blue") +
    facet_wrap(~ peak + aspect, scales = "fixed", ncol = 4) +
    geom_line(mapping = aes(x = Date, y = Tmin.gridmet), color = "red")



bias <- combined_temp %>%
    mutate(month = month(Date)) %>%
    group_by(peak, aspect, month) %>%
    summarize(
        mean_bias_tavg = mean(bias_tavg),
        sd_bias_tavg = sd(bias_tavg),
        n = n(),
        se_bias_tavg = sd_bias_tavg / sqrt(n),
        mean_bias_tmin = mean(bias_tmin),
        sd_bias_tmin = sd(bias_tmin),
        se_bias_tmin = sd_bias_tmin / sqrt(n),
        mean_bias_tmax = mean(bias_tmax),
        sd_bias_tmax = sd(bias_tmax),
        se_bias_tmax = sd_bias_tmax / sqrt(n)        
    )


## Tavg bias
bias %>% ggplot() +
    geom_point(mapping = aes(x = month, y = mean_bias_tavg, color = aspect)) +
    geom_line(mapping = aes(x = month, y = mean_bias_tavg, color = aspect), linetype = "dashed") +
    geom_line(mapping = aes(x = month, y = mean_bias_tavg + 1.96 * se_bias_tavg, color = aspect), linetype = "dotted") +
    geom_line(mapping = aes(x = month, y = mean_bias_tavg - 1.96 * se_bias_tavg, color = aspect), linetype = "dotted") +
    scale_x_continuous(breaks = 1:12) +
    facet_wrap(~ peak)

## Tmin bias
bias %>% ggplot() +
    geom_point(mapping = aes(x = month, y = mean_bias_tmin, color = aspect)) +
    geom_line(mapping = aes(x = month, y = mean_bias_tmin, color = aspect), linetype = "dashed") +
    geom_line(mapping = aes(x = month, y = mean_bias_tmin + 1.96 * se_bias_tmin, color = aspect), linetype = "dotted") +
    geom_line(mapping = aes(x = month, y = mean_bias_tmin - 1.96 * se_bias_tmin, color = aspect), linetype = "dotted") +
    scale_x_continuous(breaks = 1:12) +
    facet_wrap(~ peak)

## Tmax bias
bias %>% ggplot() +
    geom_point(mapping = aes(x = month, y = mean_bias_tmax, color = aspect)) +
    geom_line(mapping = aes(x = month, y = mean_bias_tmax, color = aspect), linetype = "dashed") +
    geom_line(mapping = aes(x = month, y = mean_bias_tmax + 1.96 * se_bias_tmax, color = aspect), linetype = "dotted") +
    geom_line(mapping = aes(x = month, y = mean_bias_tmax - 1.96 * se_bias_tmax, color = aspect), linetype = "dotted") +
    scale_x_continuous(breaks = 1:12) +
    facet_wrap(~ peak)

bias %>% ggplot() +
    geom_boxplot(mapping = aes(x = month, y = mean_bias_tmax, group = month)) +
    geom_hline(yintercept = 0) +
    scale_x_continuous(breaks = 1:12)
