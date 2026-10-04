# Draws featured.jpg: the 2x2 table of data science, 2026 edition.
# Run from the post folder: Rscript src/generate_table_2026.R

jpeg("featured.jpg", width = 2048, height = 1536, res = 256, quality = 92)
par(mar = c(0, 0, 0, 0))
plot(NULL, xlim = c(0, 10), ylim = c(0, 7.5), axes = FALSE, xlab = "", ylab = "", asp = 1)

green <- "#00FF00"; red <- "#FF0000"
cells <- list(
  list(x = 1.6, y = 3.75, col = green, txt = "Win-win,\nonly faster",              tc = "black"),
  list(x = 5.4, y = 3.75, col = red,   txt = "A missed\nopportunity",             tc = "white"),
  list(x = 1.6, y = 1.3,  col = green, txt = "Still the\nreal test",              tc = "black"),
  list(x = 5.4, y = 1.3,  col = red,   txt = "The new lose-lose,\nwell disguised", tc = "white")
)
w <- 3.65; h <- 2.35
for (cell in cells) {
  rect(cell$x, cell$y, cell$x + w, cell$y + h, col = cell$col, border = "black")
  text(cell$x + w / 2, cell$y + h / 2, cell$txt, col = cell$tc, font = 2, cex = 1.25)
}

text(5.3, 7.1, "2x2 table of data science: 2026 edition", font = 2, cex = 1.7)
text(1.6 + w / 2, 6.3, "Near-perfect science", cex = 1.05)
text(5.4 + w / 2, 6.3, "Imperfect science", cex = 1.05)
text(1.3, 3.75 + h / 2, "Near-perfect data", srt = 90, cex = 1.05)
text(1.3, 1.3 + h / 2, "Imperfect data", srt = 90, cex = 1.05)
text(0.6, 3.7, "Data", srt = 90, font = 2, cex = 1.6)
text(5.3, 0.75, "Science", font = 2, cex = 1.6)
text(5.3, 0.2, "With an AI assistant at work in every cell", font = 3, cex = 0.95)
invisible(dev.off())
