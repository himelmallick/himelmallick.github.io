# Refreshes the numbers shown on the Papers and Software pages.
#
# Open the site project in RStudio and click Source, or run in a terminal:
#   Rscript assets/update-stats.R
#
# Citations come from Google Scholar through the `scholar` package. Downloads
# come from Bioconductor's public download statistics. The numbers are written
# to the "stats" block of _variables.yml. Commit and push that file to publish
# them. A number that cannot be refreshed keeps its last value.
#
# The papers and packages to track are listed in assets/stats.json:
#   "papers":   name used on the pages -> title on Google Scholar
#   "packages": name used on the pages -> name of the package on Bioconductor
# A list of titles or names gives the combined count.
#
# GitHub runs assets/update-stats.py before every build. It refreshes the
# downloads and keeps the citations saved here, because Google Scholar turns
# away requests from GitHub's servers.

for (pkg in c("scholar", "jsonlite")) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

root      <- if (file.exists("_quarto.yml")) "." else ".."
settings  <- jsonlite::fromJSON(file.path(root, "assets", "stats.json"), simplifyVector = FALSE)
variables <- file.path(root, "_variables.yml")
header    <- "# The numbers under \"stats\" are written by assets/update-stats.R and assets/update-stats.py."
bioc_url  <- Sys.getenv("STATS_BIOCONDUCTOR_URL",
                        "https://bioconductor.org/packages/stats/bioc/{name}/{name}_stats.tab")
options(timeout = 20)

plain         <- function(x) gsub("[^a-z0-9]", "", tolower(x))
pretty_number <- function(n) format(n, big.mark = ",", scientific = FALSE, trim = TRUE)
pretty_date   <- function(d) paste0(format(d, "%B "), as.integer(format(d, "%d")), format(d, ", %Y"))
today         <- pretty_date(Sys.Date())

# ---- The values currently saved ---------------------------------------------

old   <- if (file.exists(variables)) readLines(variables, warn = FALSE) else header
saved <- list(citations = list(), downloads = list(), citations_date = "", downloads_date = "")
section <- NULL
for (line in old) {
  if (grepl('^  (citations_date|downloads_date): *".*" *$', line)) {
    saved[[sub('^  ([a-z_]+):.*$', "\\1", line)]] <- sub('^[^"]*"(.*)" *$', "\\1", line)
  } else if (grepl("^  (citations|downloads): *$", line)) {
    section <- sub("^  ([a-z]+):.*$", "\\1", line)
  } else if (!is.null(section) && grepl('^    [A-Za-z0-9_]+: *".*" *$', line)) {
    saved[[section]][[sub("^    ([A-Za-z0-9_]+):.*$", "\\1", line)]] <- sub('^[^"]*"(.*)" *$', "\\1", line)
  } else if (!startsWith(line, "    ")) {
    section <- NULL
  }
}

# ---- Citations from Google Scholar ------------------------------------------

citations      <- saved$citations
citations_date <- saved$citations_date
pubs <- tryCatch(suppressWarnings(scholar::get_publications(settings$scholar_id)),
                 error = function(e) NULL)
if (is.data.frame(pubs) && nrow(pubs) > 0 && all(c("title", "cites") %in% names(pubs))) {
  pubs <- pubs[!is.na(pubs$cites), ]
  keys <- plain(pubs$title)
  cites_of <- function(title) {
    want <- plain(title)
    hit  <- which(keys == want)
    if (length(hit) == 0) {
      similarity <- 1 - as.vector(utils::adist(want, keys)) / pmax(nchar(keys), nchar(want))
      if (max(similarity) >= 0.9) hit <- which.max(similarity)
    }
    if (length(hit) == 0) NA else max(pubs$cites[hit])
  }
  missing <- character(0)
  for (name in names(settings$papers)) {
    counts <- vapply(unlist(settings$papers[[name]]), cites_of, numeric(1))
    if (anyNA(counts)) missing <- c(missing, name) else citations[[name]] <- pretty_number(sum(counts))
  }
  citations_date <- today
  message("Citations: Google Scholar answered, ", length(settings$papers) - length(missing),
          " of ", length(settings$papers), " counts refreshed.")
  if (length(missing) > 0) {
    message("  Not found on Google Scholar under the title given: ", paste(missing, collapse = ", "))
  }
} else {
  message("Citations: Google Scholar did not answer, kept the numbers of ",
          if (nzchar(citations_date)) citations_date else "the last run", ".")
}

# ---- Downloads from Bioconductor --------------------------------------------

downloads      <- saved$downloads
downloads_date <- saved$downloads_date
total_downloads <- function(package) {
  tryCatch({
    stats <- utils::read.delim(gsub("{name}", package, bioc_url, fixed = TRUE))
    total <- sum(stats$Nb_of_downloads[stats$Month != "all"])
    if (total > 0) total else NA
  }, error = function(e) NA, warning = function(w) NA)
}
fresh <- 0
for (name in names(settings$packages)) {
  totals <- vapply(unlist(settings$packages[[name]]), total_downloads, numeric(1))
  if (!anyNA(totals)) {
    downloads[[name]] <- pretty_number(sum(totals))
    fresh <- fresh + 1
  }
}
if (fresh == length(settings$packages)) downloads_date <- today
message("Downloads: ", fresh, " of ", length(settings$packages), " counts refreshed from Bioconductor",
        if (fresh == length(settings$packages)) "." else ", kept the saved numbers for the rest.")

# ---- Write the "stats" block of _variables.yml ------------------------------

value <- function(x, name) if (is.null(x[[name]])) "" else x[[name]]
block <- c("stats:",
           sprintf('  citations_date: "%s"', citations_date),
           sprintf('  downloads_date: "%s"', downloads_date),
           "  citations:",
           sprintf('    %s: "%s"', names(settings$papers),
                   vapply(names(settings$papers), function(n) value(citations, n), character(1))),
           "  downloads:",
           sprintf('    %s: "%s"', names(settings$packages),
                   vapply(names(settings$packages), function(n) value(downloads, n), character(1))))

kept <- character(0)
skipping <- FALSE
for (line in old) {
  if (startsWith(line, "stats:")) { skipping <- TRUE; next }
  if (skipping && (startsWith(line, " ") || !nzchar(trimws(line)))) next
  skipping <- FALSE
  kept <- c(kept, line)
}
while (length(kept) > 0 && !nzchar(trimws(kept[length(kept)]))) kept <- kept[-length(kept)]
new <- c(kept, block)
if (!identical(new, old)) {
  writeLines(new, variables)
  message("_variables.yml updated. Commit and push it to publish the new numbers.")
} else {
  message("_variables.yml is already up to date.")
}
