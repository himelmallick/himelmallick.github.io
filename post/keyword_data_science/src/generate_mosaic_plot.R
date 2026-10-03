counts <- c(20, 20, 20, 20)
data <- gl(n = 2, k = 1, length = 4, labels = c("Near-perfect science", "Imperfect science"))
science <- gl(n = 2, k = 2, length = 4, labels = c("Near-perfect data", "Imperfect data"))
survey_data <- data.frame(counts, data, science)
conting_table <- xtabs(counts ~ data + science)
mosaicplot(conting_table, color = c('red', 'green'), main = "2x2 table of data science",
           xlab = "Data", ylab = "Science", cex.axis = 1.2)