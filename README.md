# README

2021-09-29 rq47

[Twitter mood predicts the stock market](https://arxiv.org/abs/1010.3003) by Johan Bollen, Huina Mao, Xiao-Jun Zeng

[pdf](./1010.3003.pdf)

**Requirement**: Review this paper. Create a presentation/tutorial that explains the topic, explains the goals, discusses the methods, and presents conclusions. How might this relate to ARM and/or networks?

## Major takeaways

public mood states -> collective decision making?

**public mood correlated or even predictive of economic indicators?**

- I. Intro
  - previously, random walk + Efficient Market Hypothesis (EMH)
    - content: stock prices -> driven by new information (rather than past and present prices)
    - issues:
      - not a random walk
      - news unpredictable, but very early indicators from social media can be extracted
  - news does impact stock market prices, but public mood states might be just equally important, but **HOW**?
  - public mood **data sources**: blog content, **large-scale Twitter feeds**, etc.
  - Analysis:
    1. OpinionFinder (+/- mood)
    2. Google-Profile of Mood States (GPOMS) (6-dim mood measures)
       - **Calm, Alert, Sure, Vital, Kind, and Happy**
  - Method: Granger causality analysis and a Self-Organizing Fuzzy Neural Network
  - Findings:
    - improved prediction accuracy of Dow Jones Industrial Average (DJIA) by the inclusion of public mood dimensions
    - public mood states are predictive of changes in DJIA closing values
    - Calm and Happiness by GPOMS seem to have a predictive effect, but not general happiness by OpnionFinder.
- II.Results
  - A. Data and methods
    - 9.8M tweets from 2.7M users
    - cleaned by
      - removing stop-words and punctuation
      - grouping by date (unified timezone)
      - filtering by explicit mood states ("i am feeling", "i don't feel", "I'm", etc.)
    - 3 phases
      - 1st phase: generate 7 (1 + 6) mood time series and 1 DJIA closing-value time series
      - 2nd phase: hypothesis testing that the 7-dim mood is predictive of future DJIA values; with a Granger causality analysis in which we correlate DJIA values to GPOMS and OF values of the past $n$ days
      - 3rd phase: deploy a Self-Organizing Fuzzy Neural Network to test the hypothesis that the prediction accuracy of DJIA can be improved by including the mood measurements
  - B. Generating public mood time series from two sources
    - OpinionFinder (OF), [link](https://mpqa.cs.pitt.edu/opinionfinder/)
      - identifies the emotional polarity (+/-) of sentences
      - adapt the OF's subjective lexicon from previous studies, select both positive and negative words, marked as either "weak" and "strong"
      - use the occurrences of +/- words to score the tweet and collectively score the day by aggregating all tweets on the same day
    - GPOMS
      - 6 dimensions, 6 moods
        - *Calm, Alert, Sure, Vital, Kind* and *Happy*.
        - dimensions and lexicon dervied from existing psychometric instrument Profile of Mood State (POMS-bi)
      - Google apparently utilizes its computational power and exposure to immense amount of text data to fine tune the model
      - tweet -> POMS mood dimensions (quite complex here mapping back and forth, but eventually) -> a score which is the weighted sum of the co-occurrence weights of each tweet term that matched the GPOMS lexicon
    - comparison between GPOMS and OF: normalization to z-score (with a moving 2k days' average) (See the formula)
  - C. Cross-validating against socio-cultural events
    - Test run on U.S. presidential election and Thanksgiving
    - Visual inspection -> *Happy* approximates the OF's results -> MLR to quantify such relationship (`Y_OF` vs `X_GPOMS`)
    - (nothing really interesting here)
  - D. Bivariate Granger Causality Analysis of Mood vs. DJIA prices
    - Granger causality analysis: daily time series vs the DJIA
    - Recall the assumption: if a variable X causes Y then changes in X will systematically occur before changes in Y -> the lagged values of X will exhibit a statistically significant correlation with Y
    - It's not a direct proof of causality. It's only testing if one time series has predictive information about the other.
    - two models `L_1` and `L_2` (excluding exceptional public mood response)
      - `L_1`: only n lagged values of DJIA
      - `L_2`: n lagged values + GPOMS + OF mood time series
    - Interpret the result table
    - Interpret the overlapping plots together (same directions, etc.)
  - E. Non-linear models for emotion-based stock prediction
    - Granger causality analysis is based on linear regression. This is too ideal, almost certainly not linear.
    - So here we introduce another approach, the Self-Organizing Fuzzy Neural Network (SOFNN), which has 2 inputs:
      - (1) the past 3 days of DJIA
      - (2) the same combined with various permutations of our mood time series
    - see if SOFNN confirms or rejects the null hypothesis that public mood does not improve predictive models of DJIA
    - model came from a previous study, `n` days of DJIA, `n=3` since `n=4` the Granger causality between *Calm* and DJIA decreases.
    - result: only *Calm* (and to some degree *Happy*) is Granger-causative of DJIA, but others combined could be informative as well.
    - result2: previous one is about the mood dimensions of GPOMS, what about OF? Solely use SOFNN with OF (Table III for the performance)
      - (1) adding OF has no effect on prediction accuracy compared to using only historical DJIA
      - (2) adding *Calm*, the prediction accuracy is the highest
      - (3) `I_1,3` and `I_1,4` (*Calm* + *Sure* and *Calm* + *Vital*) reduce the accuracy
    - last check: test the linear effect of *Calm* and *Happy* -> confirm a nonlinear relation among the different dimensions of moods.
- III. Discussion
  - (Basically reiterate everything mentioned above.)
  - But the last paragraph does have some insights on the drawbacks of this experiment.
    - (1) not limited to a geolocation, or a population subset (because DJIA is for US stock market)
    - (2) no ground truth about Twitter's tweets and the real public mood states, just one perspective
    - (3) still hints for strong correlation between the two, but offers nothing substantial about the causality
      - maybe the general public at that moment are all financial experts who strongly invested in DJIA, therefore their mood states will affect their investment decisions -> stock market prices (no one could know this)

## Background knowledge

**Granger causality analysis**:

**Self-Organizing Fuzzy Neural Network**:

## Demo

It's very hard to replicate the experiment since the main website of that project is down. Think about it, it's rather hard to acquire large-scale data today to reflect a collective public mood state. But we can do it from an opposite direction, namely, we get some specific high-level metric, and see if it is predictive of its followers' mood states.

This is almost certain since the followers will react to what they are following no matter what, unless they are no longer followers. For example, we get stock prices of a stock, then we see if the rise and fall of that stock is reflected in a subreddit's collective sentimental changes.

## Referneces

- [Sentiment Analysis of Twitter Data for Predicting Stock Market Movements](https://arxiv.org/abs/1610.09225), [pdf](./1610.09225.pdf)
- [you915/Sentiment-Analysis-of-Twitter-Data-for-predicting-Apple-stock-price](https://github.com/you915/Sentiment-Analysis-of-Twitter-Data-for-predicting-Apple-stock-price)
- [Make Your Presentations Fun in Xaringan](http://svmiller.com/blog/2018/02/r-markdown-xaringan-theme/)