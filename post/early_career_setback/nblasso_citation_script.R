###########################################
# Remove all variables from the workspace #
###########################################

rm(list = ls())

##################
# Load libraries #
##################

library(scholar)
library(tidyverse)
library(ggplot2)

##################################################################
# Manually create FWCI data for the paper "A New Bayesian LASSO" #
##################################################################

cites = c(0, 0, 0, 6, 7, 10, 0) # Extracted from Google Scholar (without self-citations)
average_cite<-4.2  # Table 3 of https://www.sciencedirect.com/science/article/pii/S2405844016322800
count<-round(cites/average_cite, 1)

dat <- tibble(year = toupper(c("2014", "2015", "2016", "2017", "2018", "2019", "2020")),
              count = count,
              label = c(as.character(count[-length(count)]), "Not \n enough \n data \n points"),
              code = c("A", "B", "C", "D", "E", "F", "G"))

dat %>% ggplot(aes(year, count, label = label)) +
  geom_bar(stat = "identity", fill = "darkred") +
  geom_text(nudge_y = c(rep(0.2, 6), 0.5), color = "darkred", size = 5) +
  scale_y_continuous(breaks = c(0, 1, 2, 3), 
                     limits = c(0, 3), 
                     sec.axis = sec_axis(~. * 1, 
                                         breaks = 1,
                                         labels = expression(bold("World \naverage")),
                                         name = "")) +  
  geom_hline(aes(yintercept=1), colour="purple",  size = 1.5) + 
  geom_text(aes(2, 1, label = ">1: above the world average :)", vjust = -1)) + 
  geom_text(aes(2, 0.8,label = "<1: below the world average :(", vjust = -1)) + 
  geom_text(aes(6.25, 3.0, label = "Source: Google Scholar")) + 
  ggtitle("Citation analysis of 'A New Bayesian LASSO' by Mallick and Yi (2014)") + 
  xlab("") + ylab("Field-Weighted Citation Impact (FWCI)") + 
  theme_bw() + 
  theme(axis.text.x = element_text(size = 12),
        axis.ticks.x = element_blank(),
        axis.line.x = element_blank(),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        plot.margin = unit(c(0.5,0.5,0.5,0.5), "cm")) 