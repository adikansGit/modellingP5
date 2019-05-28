
library(knitr)

suppressPackageStartupMessages(library(dplyr))
library(dplyr)
suppressPackageStartupMessages(library(tidyverse))
library(tidyverse)

sizeData <- read.table("unitSizing.csv", sep=",", header = T)
sizeData <- arrange(sizeData,desc(Installed.Capacity))


sizePlot <- ggplot(sizeData, aes(x = Unit, y = Installed.Capacity, fill = Unit))
  sizePlot + geom_bar(stat = "identity", alpha = 0.7) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 10)) +
  labs(title = "Scenario 3 - Minimal carbon dioxide emissions",x = "Unit", y = "Installed Capacity (MW)") +
  theme(plot.title = element_text(hjust = 0.5))
  
    
  