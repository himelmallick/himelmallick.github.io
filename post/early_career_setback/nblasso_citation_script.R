# Citation analysis of "A New Bayesian LASSO" (Mallick and Yi, 2014).
#
# Click Source in RStudio. The script
#   1. asks Google Scholar for the paper's citations in each year,
#   2. saves them in citation_history.csv (and reuses that file when
#      Google Scholar does not answer),
#   3. redraws featured.jpg, the figure at the top of the post.

library(scholar)
library(ggplot2)

scholar_id   <- "twbXG-wAAAAJ"
paper_title  <- "A New Bayesian LASSO"
average_cite <- 4.2  # citations per paper per year in statistics; Table 3 of
                     # https://www.sciencedirect.com/science/article/pii/S2405844016322800

# Files are written next to this script, whether you run it from the site folder
# (the RStudio project) or from the post folder.
folder <- if (dir.exists("post/early_career_setback")) "post/early_career_setback" else "."
saved  <- file.path(folder, "citation_history.csv")

# 1. Citations per year, from Google Scholar or from the saved copy
history <- tryCatch({
  pubs  <- get_publications(scholar_id)
  pubid <- pubs$pubid[tolower(pubs$title) == tolower(paper_title)][1]
  h <- get_article_cite_history(scholar_id, pubid)
  if (!is.data.frame(h) || nrow(h) == 0) stop("empty answer")
  h[, c("year", "cites")]
}, error = function(e) NULL)

if (!is.null(history)) {
  write.csv(history, saved, row.names = FALSE)
} else if (file.exists(saved)) {
  history <- read.csv(saved)
  message("Google Scholar did not answer. Using the numbers saved on ",
          format(file.mtime(saved), "%B %d, %Y"), ".")
} else {
  stop("Google Scholar did not answer and there are no saved numbers yet. Try again later.")
}

# 2. One row per complete year since publication (the current year is left out)
this_year <- as.integer(format(Sys.Date(), "%Y"))
dat <- merge(data.frame(year = 2014:(this_year - 1)), history, all.x = TRUE)
dat$cites[is.na(dat$cites)] <- 0
dat$fwci <- round(dat$cites / average_cite, 1)
print(dat)

# 3. The figure, in the same style as the 2020 version
draw <- function(dat, source_label) {
  n   <- nrow(dat)
  top <- max(3, ceiling(max(dat$fwci)))
  ggplot(dat, aes(factor(year), fwci, label = fwci)) +
    geom_bar(stat = "identity", fill = "darkred") +
    geom_text(nudge_y = 0.2, color = "darkred", size = 5) +
    scale_y_continuous(breaks = 0:top,
                       limits = c(0, top + 0.3),
                       sec.axis = sec_axis(~ . * 1,
                                           breaks = 1,
                                           labels = expression(bold("World \naverage")),
                                           name = "")) +
    geom_hline(aes(yintercept = 1), colour = "purple", linewidth = 1.5) +
    annotate("text", x = 0.6, y = top + 0.25, label = ">1: above the world average :)", hjust = 0) +
    annotate("text", x = 0.6, y = top - 0.02, label = "<1: below the world average :(", hjust = 0) +
    annotate("text", x = n + 0.4, y = top + 0.25, label = source_label, hjust = 1) +
    ggtitle("Citation analysis of 'A New Bayesian LASSO' by Mallick and Yi (2014)") +
    xlab("") + ylab("Field-Weighted Citation Impact (FWCI)") +
    theme_bw() +
    theme(axis.text.x = element_text(size = 12),
          axis.ticks.x = element_blank(),
          axis.line.x = element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"))
}

ggsave(file.path(folder, "featured.jpg"), draw(dat, "Source: Google Scholar"),
       width = 8, height = 6, dpi = 256, quality = 90)
message("Wrote ", file.path(folder, "featured.jpg"), " and ", saved)

# 4. A second figure without self-citations.
# Google Scholar does not separate self-citations, so they are listed by hand in
# self_citations.csv: one row per year, with the number of citing papers that
# year on which Himel Mallick is an author (columns: year, self_cites).
self_file <- file.path(folder, "self_citations.csv")
if (file.exists(self_file)) {
  self <- read.csv(self_file)
  dat2 <- merge(dat[, c("year", "cites")], self, all.x = TRUE)
  dat2$self_cites[is.na(dat2$self_cites)] <- 0
  dat2$cites <- pmax(dat2$cites - dat2$self_cites, 0)
  dat2$fwci  <- round(dat2$cites / average_cite, 1)
  print(dat2)
  ggsave(file.path(folder, "fwci_without_self_citations.jpg"),
         draw(dat2, "Source: Google Scholar, self-citations excluded"),
         width = 8, height = 6, dpi = 256, quality = 90)
  message("Wrote ", file.path(folder, "fwci_without_self_citations.jpg"))
}
