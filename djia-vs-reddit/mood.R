gc()
rm(list=ls())

# https://www.kaggle.com/ndrewgele/omg-nlp-with-the-djia-and-reddit/data

if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, lubridate, textdata,
               tidytext, glue, ggthemes, ggHoriPlot)

reddit <- read_csv('djia-vs-reddit/RedditNews.csv') %>%
    group_by(Date) %>%
    mutate(DailyText = paste0(News, collapse = " ")) %>%
    ungroup() %>%
    distinct(Date, DailyText)

tidy_df <- reddit %>%
    unnest_tokens(word, DailyText,  to_lower = TRUE) %>%
    anti_join(stop_words, by = "word")

tidy_df %>%
    right_join(get_sentiments("nrc")) %>%
    filter(!is.na(sentiment)) %>%
    count(sentiment, sort = TRUE)

tidy_df %>%
    right_join(get_sentiments("afinn")) %>%
    filter(!is.na(value))

daily_df <- tidy_df %>%
    right_join(get_sentiments("afinn")) %>%
    filter(!is.na(value)) %>%
    group_by(Date) %>%
    summarize(SentimentalMean = mean(value))

cutpoints <- daily_df %>%
    mutate(
        outlier = between(
            SentimentalMean,
            quantile(SentimentalMean, 0.25, na.rm=T)-
                1.5*IQR(SentimentalMean, na.rm=T),
            quantile(SentimentalMean, 0.75, na.rm=T)+
                1.5*IQR(SentimentalMean, na.rm=T))) %>%
    filter(outlier)

ori <- sum(range(cutpoints$SentimentalMean)) / 2
sca <- seq(range(cutpoints$SentimentalMean)[1],
           range(cutpoints$SentimentalMean)[2],
           length.out = 7)[-4]

daily_df <- daily_df %>%
    mutate(Year = year(Date),
           Month = month(Date),
           Day = day(Date)) %>%
    drop_na()

year(daily_df$Date) <- 2021

reddit_sentmean <- daily_df %>% ggplot() +
    geom_horizon(aes(Date, SentimentalMean,
                     fill = ..Cutpoints..),
                 origin = ori, horizonscale = sca) +
    scale_fill_hcl(palette = "RdBu", reverse = T) +
    facet_grid(Year~.) +
    theme_fivethirtyeight() +
    theme(
        panel.spacing.y=unit(0, "lines"),
        strip.text.y = element_text(size = 7, angle = 0, hjust = 0),
        # legend.position = 'none',
        axis.text.y = element_blank(),
        axis.title.y = element_blank(),
        axis.ticks.y = element_blank(),
        panel.border = element_blank()
    ) +
    scale_x_date(expand=c(0,0), 
                 date_breaks = "1 month", 
                 date_labels = "%b") +
    xlab("Date") +
    ggtitle("Average daily sentimental value of all news post in Reddit",
            "from 2008 to 2016")
ggsave("djia-vs-reddit/reddit-sentmean.png", 
       reddit_sentmean,
       height = 9, width = 16, dpi = 100, device = "png")


djia <- read_csv("djia-vs-reddit/DJIA_table.csv") %>%
    select(Date, `Adj Close`) %>%
    mutate(Year = year(Date),
           Month = month(Date),
           Day = day(Date)) %>%
    drop_na()
year(djia$Date) <- 2021

cutpoints2 <- djia %>%
    mutate(
        outlier = between(
            `Adj Close`,
            quantile(`Adj Close`, 0.25, na.rm=T)-
                1.5*IQR(`Adj Close`, na.rm=T),
            quantile(`Adj Close`, 0.75, na.rm=T)+
                1.5*IQR(`Adj Close`, na.rm=T))) %>%
    filter(outlier)

ori2 <- sum(range(cutpoints2$`Adj Close`)) / 2
sca2 <- seq(range(cutpoints2$`Adj Close`)[1],
           range(cutpoints2$`Adj Close`)[2],
           length.out = 7)[-4]

djia_plot <- djia %>% ggplot() +
    geom_horizon(aes(Date, `Adj Close`,
                     fill = ..Cutpoints..),
                 origin = ori2, horizonscale = sca2) +
    scale_fill_hcl(palette = "RdBu", reverse = T) +
    facet_grid(Year~.) +
    theme_fivethirtyeight() +
    theme(
        panel.spacing.y=unit(0, "lines"),
        strip.text.y = element_text(size = 7, angle = 0, hjust = 0),
        # legend.position = 'none',
        axis.text.y = element_blank(),
        axis.title.y = element_blank(),
        axis.ticks.y = element_blank(),
        panel.border = element_blank()
    ) +
    scale_x_date(expand=c(0,0), 
                 date_breaks = "1 month", 
                 date_labels = "%b") +
    xlab("Date") +
    ggtitle("Daily Adjusted Close DJIA",
            "from 2008 to 2016")
ggsave("djia-vs-reddit/djia-plot.png", 
       djia_plot,
       height = 9, width = 16, dpi = 100, device = "png")
