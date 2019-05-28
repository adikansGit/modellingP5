library(knitr)

suppressPackageStartupMessages(library(dplyr))
library(dplyr)
suppressPackageStartupMessages(library(tidyverse))
library(tidyverse)

LTdata <- read.table("lowTHeating.csv", sep=",", header = T)
LTdata <- arrange(LTdata,desc(Annual_Heating_Load))
LTdata <- mutate(LTdata, cumSize = cumsum(Installed_Heating_Capacity))
LTdata <- mutate(LTdata, Ymin = lag(cumSize))
LTdata[is.na(LTdata)] <- 0

usePlot <- ggplot(LTdata)
usePlot + geom_col(aes(xmin = 0, ymin = Ymin, xmax = Annual_Heating_Load, ymax = cumSize, fill = Unit), alpha = 0.7) +
  geom_hline(aes(yintercept = 0)) +
  geom_vline(aes(xintercept = 0)) +
  xlim(0,30000) +
  ylim(0,50) +
  scale_x_continuous(breaks = scales::pretty_breaks(n = 10)) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +
  labs(x = "Annual Heat Supply", y = "(Cumulative sum of) Unit Size (kW)")
