# Update_Resume.R
# Rebuilds the resume PDF with fresh Google Scholar numbers.
# Keep this file next to Resume_Master.Rnw (Sweave) or Resume_Master.qmd (Quarto),
# set `route` below, then click Source in RStudio or put the script on a schedule.

route <- "sweave"   # "sweave" or "quarto"

if (route == "sweave") {
  # Runs the R chunk, then LaTeX. Needs a LaTeX installation
  # (the quickest one to set up: install.packages("tinytex"); tinytex::install_tinytex()).
  utils::Sweave("Resume_Master.Rnw")
  tools::texi2pdf("Resume_Master.tex", clean = TRUE)
} else {
  # Needs Quarto (it comes with RStudio).
  status <- system2("quarto", c("render", "Resume_Master.qmd"))
  if (status != 0) stop("Quarto could not build the resume. Read the message above.")
}

invisible(file.copy("Resume_Master.pdf", "Resume_Final.pdf", overwrite = TRUE))
message("Wrote Resume_Final.pdf")
