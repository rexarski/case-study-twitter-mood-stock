gc()
rm(list=ls())

# https://www.kaggle.com/ndrewgele/omg-nlp-with-the-djia-and-reddit/data

if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, lubridate, textdata,
               tidytext, glue, ggthemes, ggHoriPlot,
               lmtest, patchwork)

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

daily_df <- daily_df %>%
    mutate(SentimentalMean = scale(SentimentalMean,
                                   center = TRUE,
                                   scale = TRUE))

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
    ggtitle("Z-score of sentimental mean of all news post in Reddit",
            "from 2008 to 2016")
ggsave("image/01-reddit-sentmean.png", 
       reddit_sentmean,
       height = 9, width = 16, dpi = 100, device = "png")


djia <- read_csv("djia-vs-reddit/DJIA_table.csv") %>%
    select(Date, `Adj Close`) %>%
    mutate(Year = year(Date),
           Month = month(Date),
           Day = day(Date)) %>%
    drop_na() %>%
    mutate(`Adj Close` = scale(`Adj Close`, 
                               scale=TRUE, center=TRUE))
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
    ggtitle("Z-score of Adjusted Close DJIA",
            "from 2008 to 2016")
ggsave("image/02-djia-plot.png", 
       djia_plot,
       height = 9, width = 16, dpi = 100, device = "png")

reddit_sentmean / djia_plot


join_df <- daily_df %>%
    inner_join(djia, by=c("Year", "Month", "Day"))

# What about a real side-by-side comparison?
side_by_side <- join_df %>%
    mutate(Date = make_date(Year, Month, Day)) %>%
    select(-c(Date.x, Date.y, Year, Month, Day)) %>%
    pivot_longer(cols = c(SentimentalMean, `Adj Close`)) %>%
    ggplot(aes(x = Date, y = value, color = name)) +
        geom_line() +
        theme_fivethirtyeight()

ggsave("image/03-side-by-side.png", 
       side_by_side,
       height = 9, width = 16, dpi = 100, device = "png")

join_df <- join_df %>%
    select(`Adj Close`, SentimentalMean) %>%
    relocate(`Adj Close`)

AdjClose <- join_df$`Adj Close`
SentimentalMean <- join_df$SentimentalMean

grangertest(AdjClose ~ SentimentalMean, order = 1)

# Model 1: attempts to predict AdjClose using the 1 previous  AdjClose and 1 SentimentalMean as predictor variables.
# Model 2: attempts to predict AdjClose using only 1 previous AdjClose

# p>.05, this means we fail to reject the null hypothesis that these two models are essentially no difference. Thus the SentimentalMean does not contribute in predicting the AdjClose.

# What about including some lags?

grangertest(AdjClose ~ SentimentalMean, order = 2)
grangertest(AdjClose ~ SentimentalMean, order = 3)
grangertest(AdjClose ~ SentimentalMean, order = 4)
grangertest(AdjClose ~ SentimentalMean, order = 5)
grangertest(AdjClose ~ SentimentalMean, order = 6)
grangertest(AdjClose ~ SentimentalMean, order = 7)

# Funny thing, if we reverse the order, say does AdjClose affect the SentimentalMean?

grangertest(SentimentalMean ~ AdjClose, order = 1)

# The answer is yes.

grangertest(SentimentalMean ~ AdjClose, order = 2)
grangertest(SentimentalMean ~ AdjClose, order = 3)

grangertest(SentimentalMean ~ AdjClose, order = 7)
grangertest(SentimentalMean ~ AdjClose, order = 14)
grangertest(SentimentalMean ~ AdjClose, order = 21)
grangertest(SentimentalMean ~ AdjClose, order = 28)


# reflections:
# - if we mix the multiple sentiments into one, the impact is insignificant,
# recall the paper only claims certain "mood" is causal.
# - similar reasoning in the paper: the reddit news might not be representative enough to reflect the public mood
#   - if might be the user group of reddit does not overlap with the population who really make investment decisions.
#   - the news coverage: worldwide; the DJIA coverage: US stock market.
# - maybe, if we select a small window of time interval would change the result.

# again, do sentimental analysis but with ncr

daily_df2 <- tidy_df %>%
    right_join(get_sentiments("nrc")) %>%
    right_join(get_sentiments("afinn")) %>%
    drop_na() %>%
    group_by(Date, sentiment) %>%
    summarize(SentimentalMean = mean(value)) %>%
    mutate(SentimentalMean = scale(SentimentalMean,
                                   center=TRUE,
                                   scale=TRUE))

# ten_moods <- ggplot(daily_df2, aes(x=Date, y=SentimentalMean,
#                                    color = sentiment)) +
#     geom_line() +
#     facet_wrap(.~sentiment)
# ten_moods

djia2 <- read_csv("djia-vs-reddit/DJIA_table.csv") %>%
    select(Date, `Adj Close`) %>%
    mutate(`Adj Close` = scale(`Adj Close`, center = TRUE,
                               scale = TRUE)) %>%
    drop_na()

join_df2 <- daily_df2 %>%
    inner_join(djia2, by="Date")

for (senti in unique(join_df2$sentiment)) {
    for (order in 1:14) {
        test <- grangertest(`Adj Close` ~ SentimentalMean,
                            order = order,
                            data = filter(join_df2, sentiment == senti))
        if (test$`Pr(>F)`[2] < 0.05) {
            print(senti)
            print(test)
        }
    }
}

# If we really filter the data, say we only keep data in 2008.
# p-value = 0.1 as a threshold

join_df3 <- join_df2 %>%
    filter(Date < as_date("2009-01-01"))

for (senti in unique(join_df3$sentiment)) {
    for (order in 1:14) {
        test <- grangertest(`Adj Close` ~ SentimentalMean,
                            order = order,
                            data = filter(join_df3, sentiment == senti))
        if (test$`Pr(>F)`[2] < 0.05) {
            print(senti)
            print(test)
        }
    }
}
