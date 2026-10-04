# Update_Resume.R
# Puts your Google Scholar numbers into a Word resume.
# Change the three lines below, then click Source in RStudio.

scholar_id  <- "twbXG-wAAAAJ"        # the id in the address of your Google Scholar profile
input_file  <- "Resume_Master.docx"  # the resume you edit
output_file <- "Resume_Final.docx"   # the copy with the numbers filled in

for (pkg in c("officer", "scholar")) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

# 1. Get the numbers. If Google Scholar does not answer, reuse the last saved ones.
saved <- "scholar_metrics.rds"
profile <- tryCatch(scholar::get_profile(scholar_id), error = function(e) NULL)
answered <- is.list(profile) && length(profile$total_cites) == 1 && !is.na(profile$total_cites)

if (answered) {
  metrics <- c(GS_a = profile$total_cites, GS_b = profile$h_index, GS_c = profile$i10_index)
  saveRDS(metrics, saved)
} else if (file.exists(saved)) {
  metrics <- readRDS(saved)
  message("Google Scholar did not answer. Using the numbers saved on ",
          format(file.mtime(saved), "%B %d, %Y"), ".")
} else {
  stop("Google Scholar did not answer and there are no saved numbers yet. Try again later.")
}

# 2. Write them at the bookmarks GS_a, GS_b and GS_c.
doc <- officer::read_docx(input_file)
absent <- setdiff(names(metrics), officer::docx_bookmarks(doc))
if (length(absent) > 0) {
  stop("Add these bookmarks to ", input_file, " first: ", paste(absent, collapse = ", "))
}
for (bookmark in names(metrics)) {
  number <- format(metrics[[bookmark]], big.mark = ",")
  doc <- officer::body_replace_text_at_bkm(doc, bookmark, number)
}
print(doc, target = output_file)
message("Wrote ", output_file)
