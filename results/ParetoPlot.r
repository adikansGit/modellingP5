
library(knitr)

suppressPackageStartupMessages(library(dplyr))
library(dplyr)
suppressPackageStartupMessages(library(tidyverse))
library(tidyverse)

Pareto <- read.table("Pareto_CAPEX_CO2.csv", sep=",", header = T)

ParetoCurve <- ggplot(Pareto)

ParetoCurve + geom_line(aes(x = CAPEX.CHF., y = CO2.Emissions.tons.), alpha = 0.4, color = 'blue', size = 1) +
  scale_x_continuous(breaks = scales::pretty_breaks(n = 10)) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +
  labs(title = "Pareto Curve for Investment Cost vs. CO2 emissions", x = "Capital Expenditure (CHF/year)", y = "CO2 Emissions, tons") +
  theme(plot.title = element_text(hjust = 0.5))
