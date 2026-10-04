# Google Scholar numbers for a CV or resume written in Quarto.
#
# What happens each time a document is rendered:
#   1. Google Scholar is asked for your totals and for the citation count of
#      every paper on your profile.
#   2. The answer is saved in scholar-cache.json, next to this file.
#   3. If Google Scholar cannot be reached (it sometimes blocks repeated
#      requests), the saved numbers are used, so the document always builds.
#   4. "[Citations: N]" is added to each paper with at least `min_citations`
#      citations.
#
# The settings live at the top of the .qmd files (scholar_id, min_citations,
# citation_format, max_age_hours, title_aliases). This file rarely needs editing.
#
# To see how your entries were matched to Google Scholar, run in the R console:
#     source("scholar.R"); scholar_check("Resume_Master.qmd")

scholar_cache_file <- function(dir) file.path(dir, "scholar-cache.json")

# Progress notes go to the Render log, never into the document.
scholar_say <- function(...) cat("scholar.R: ", ..., "\n", sep = "", file = stderr())

scholar_no_papers <- function() {
  data.frame(title = character(0), cites = numeric(0), stringsAsFactors = FALSE)
}

# ---- Saved numbers ---------------------------------------------------------

scholar_read_cache <- function(dir) {
  f <- scholar_cache_file(dir)
  if (!file.exists(f)) return(NULL)
  x <- tryCatch(jsonlite::fromJSON(f, simplifyDataFrame = TRUE), error = function(e) NULL)
  if (!is.list(x)) return(NULL)
  pubs <- x$publications
  if (!is.data.frame(pubs) || nrow(pubs) == 0 || !all(c("title", "cites") %in% names(pubs))) {
    pubs <- scholar_no_papers()
  }
  x$publications <- pubs
  x
}

scholar_write_cache <- function(dir, x) {
  out <- jsonlite::toJSON(x, auto_unbox = TRUE, pretty = TRUE, na = "null")
  con <- file(scholar_cache_file(dir), open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(enc2utf8(as.character(out)), con)
}

# ---- Asking Google Scholar ---------------------------------------------------

# Returns list(profile = <list or NULL>, publications = <data frame or NULL>).
scholar_fetch_live <- function(id) {
  res <- list(profile = NULL, publications = NULL)
  if (!requireNamespace("scholar", quietly = TRUE)) {
    scholar_say("the 'scholar' package is missing; run install.packages(\"scholar\").")
    return(res)
  }
  one <- function(v) {
    v <- suppressWarnings(as.numeric(v))
    if (length(v) == 1 && !is.na(v)) v else NULL
  }
  p <- tryCatch(suppressWarnings(scholar::get_profile(id)), error = function(e) NULL)
  if (is.list(p) && !is.null(one(p$total_cites)) && !is.null(one(p$h_index)) &&
      !is.null(one(p$i10_index))) {
    res$profile <- list(total_cites = one(p$total_cites), h_index = one(p$h_index),
                        i10_index = one(p$i10_index))
  }
  pubs <- tryCatch(suppressWarnings(scholar::get_publications(id)), error = function(e) NULL)
  if (is.data.frame(pubs) && nrow(pubs) > 0 && all(c("title", "cites") %in% names(pubs))) {
    pubs <- data.frame(title = as.character(pubs$title),
                       cites = suppressWarnings(as.numeric(pubs$cites)),
                       stringsAsFactors = FALSE)
    pubs <- pubs[!is.na(pubs$title) & nzchar(pubs$title), , drop = FALSE]
    pubs$cites[is.na(pubs$cites)] <- 0
    if (nrow(pubs) > 0) res$publications <- pubs
  }
  res
}

# Fresh numbers when possible, saved numbers otherwise.
#   dir            folder that holds scholar-cache.json
#   max_age_hours  saved numbers newer than this are used without asking again
#   fetch          the function that asks Google Scholar
scholar_get <- function(id, dir = ".", max_age_hours = 12, fetch = scholar_fetch_live) {
  cache <- scholar_read_cache(dir)
  if (is.null(cache)) {
    cache <- list(fetched = NA, total_cites = NA, h_index = NA, i10_index = NA,
                  publications = scholar_no_papers())
  }
  age <- Inf
  if (length(cache$fetched) == 1 && !is.na(cache$fetched)) {
    t0 <- suppressWarnings(as.POSIXct(cache$fetched, tz = ""))
    if (!is.na(t0)) age <- as.numeric(difftime(Sys.time(), t0, units = "hours"))
  }
  if (nrow(cache$publications) > 0 && age >= 0 && age < max_age_hours) {
    scholar_say("using the Google Scholar numbers saved on ", cache$fetched, ".")
    return(cache)
  }
  live <- fetch(id)
  if (is.null(live$profile) && is.null(live$publications)) {
    scholar_say("Google Scholar could not be reached; using the numbers saved on ",
            cache$fetched, ".")
    return(cache)
  }
  if (!is.null(live$profile)) {
    cache$total_cites <- live$profile$total_cites
    cache$h_index <- live$profile$h_index
    cache$i10_index <- live$profile$i10_index
  }
  if (!is.null(live$publications)) cache$publications <- live$publications
  if (!is.null(live$profile) && !is.null(live$publications)) {
    cache$fetched <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    scholar_say("fresh numbers from Google Scholar (", nrow(cache$publications),
            " papers).")
  } else {
    scholar_say("Google Scholar answered only in part; the rest comes from saved numbers.")
  }
  scholar_write_cache(dir, cache)
  cache
}

# ---- Matching entries to Google Scholar --------------------------------------

# "Multi-omics Prediction and Classification." -> "multiomicspredictionandclassification"
scholar_norm <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- gsub("\\\\[A-Za-z]+\\*?", " ", x)   # LaTeX commands
  x <- gsub("[{}$~^_]", "", x)
  y <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT", sub = "")
  y[is.na(y)] <- ""
  gsub("[^a-z0-9]", "", tolower(y))
}

# The title of one entry, or NA when none can be found.
scholar_entry_title <- function(entry) {
  # \href{link}{Title}
  m <- regmatches(entry, gregexpr("\\\\href\\{[^{}]*\\}\\s*\\{(?:[^{}]|\\{[^{}]*\\})*\\}",
                                  entry, perl = TRUE))[[1]]
  for (h in m) {
    title <- sub("^\\\\href\\{[^{}]*\\}\\s*\\{", "", h, perl = TRUE)
    title <- sub("\\}$", "", title, perl = TRUE)
    if (nchar(scholar_norm(title)) >= 12) return(title)
  }
  # (2026+). Title. \ul{\textsl{Journal}}
  m <- regmatches(entry, regexec("(?s)\\(\\d{4}\\+?\\)\\.?\\s+(.+?)\\.\\s+\\\\ul\\{",
                                 entry, perl = TRUE))[[1]]
  if (length(m) == 2) return(m[2])
  # (2025). \textit{Title}. In ...
  m <- regmatches(entry, regexec("(?s)\\(\\d{4}\\+?\\)\\.?\\s+\\\\textit\\{([^{}]+)\\}",
                                 entry, perl = TRUE))[[1]]
  if (length(m) == 2) return(m[2])
  NA_character_
}

# Citation count for one title: list(cites, matched) or NULL when the paper is
# not on the Google Scholar profile.
scholar_lookup <- function(title, pubs, aliases = list()) {
  if (is.na(title) || nrow(pubs) == 0) return(NULL)
  key <- scholar_norm(title)
  if (length(aliases) > 0) {
    a <- which(scholar_norm(names(aliases)) == key)
    if (length(a) > 0) key <- scholar_norm(aliases[[a[1]]])
  }
  if (nchar(key) < 12) return(NULL)
  keys <- scholar_norm(pubs$title)
  hit <- which(keys == key)
  if (length(hit) == 0) {
    # one title is the beginning of the other (a subtitle dropped on one side)
    n <- pmin(nchar(keys), nchar(key))
    hit <- which(n >= 30 & substr(keys, 1, n) == substr(key, 1, n))
  }
  if (length(hit) == 0) {
    # small differences in spelling or wording; short titles must agree more closely
    sim <- 1 - as.vector(utils::adist(key, keys)) / pmax(nchar(keys), nchar(key))
    best <- which.max(sim)
    need <- if (nchar(key) >= 40) 0.80 else 0.92
    if (length(best) == 1 && sim[best] >= need) hit <- best
  }
  if (length(hit) == 0) return(NULL)
  hit <- hit[which.max(pubs$cites[hit])]
  list(cites = pubs$cites[hit], matched = pubs$title[hit])
}

# ---- Adding the counts to the document ---------------------------------------

# Cuts `text` into pieces that each start where `pattern` matches.
scholar_cut <- function(text, pattern) {
  pos <- gregexpr(pattern, text, perl = TRUE)[[1]]
  if (pos[1] == -1) return(text)
  starts <- unique(c(1, as.integer(pos)))
  substring(text, starts, c(starts[-1] - 1, nchar(text)))
}

# Entries of one region: the items of a list, or paragraphs when there are no items.
scholar_entries <- function(region) {
  if (grepl("\\\\item\\b", region, perl = TRUE)) {
    pieces <- scholar_cut(region, "\\\\item\\b")
    list(pieces = pieces, is_entry = grepl("^\\\\item\\b", pieces, perl = TRUE))
  } else {
    pieces <- scholar_cut(region, "(?<=\n)[ \t]*\n+(?=[ \t]*\\S)")
    list(pieces = pieces, is_entry = grepl("\\\\ul\\{|\\\\href\\{", pieces, perl = TRUE))
  }
}

# Puts the tag at the end of the last line of text in the entry, ahead of any
# closing \vspace{...} and of any % comment.
scholar_append <- function(entry, tag) {
  body <- sub("\\s+$", "", entry, perl = TRUE)
  if (!nzchar(body)) return(entry)
  rest <- substring(entry, nchar(body) + 1)
  lines <- strsplit(body, "\n", fixed = TRUE)[[1]]
  is_text <- nzchar(trimws(lines)) & !grepl("^\\s*%", lines, perl = TRUE)
  if (!any(is_text)) return(entry)
  i <- max(which(is_text))
  m <- regmatches(lines[i], regexec(
    "^(.*?)((?:\\s|\\\\vspace\\*?\\{[^{}]*\\})*)((?<!\\\\)%.*)?$", lines[i], perl = TRUE))[[1]]
  if (length(m) != 4) return(entry)
  lines[i] <- paste0(m[2], " ", tag, m[3], m[4])
  paste0(paste(lines, collapse = "\n"), rest)
}

# "[Citations: 1,234]" wrapped in \\GSCount{}, which keeps the count in one piece
# and lets it move to a new line when it does not fit.
scholar_format <- function(n, fmt) {
  paste0("\\GSCount{", sprintf(fmt, format(n, big.mark = ",", scientific = FALSE, trim = TRUE)), "}")
}

scholar_tag_region <- function(region, pubs, min_citations, fmt, aliases) {
  e <- scholar_entries(region)
  for (i in which(e$is_entry)) {
    hit <- scholar_lookup(scholar_entry_title(e$pieces[i]), pubs, aliases)
    if (!is.null(hit) && hit$cites >= min_citations) {
      e$pieces[i] <- scholar_append(e$pieces[i], scholar_format(hit$cites, fmt))
    }
  }
  paste(e$pieces, collapse = "")
}

# The regions that hold papers: every reverse-numbered list (etaremune), and
# anything between these two comment lines:
#     %% citation counts: on
#     %% citation counts: off
scholar_region_patterns <- c(
  "(?s)(\\\\begin\\{etaremune\\})(.*?)(\\\\end\\{etaremune\\})",
  "(?s)(%% citation counts: on[^\n]*\n)(.*?)(%% citation counts: off)"
)

scholar_add_counts <- function(text, pubs, min_citations = 50,
                               fmt = "[Citations: %s]", aliases = list()) {
  if (nrow(pubs) == 0) return(text)
  for (p in scholar_region_patterns) {
    m <- gregexpr(p, text, perl = TRUE)
    hits <- regmatches(text, m)[[1]]
    if (length(hits) == 0) next
    regmatches(text, m)[[1]] <- vapply(hits, function(h) {
      parts <- regmatches(h, regexec(p, h, perl = TRUE))[[1]]
      paste0(parts[2], scholar_tag_region(parts[3], pubs, min_citations, fmt, aliases), parts[4])
    }, character(1), USE.NAMES = FALSE)
  }
  text
}

# ---- The one call made from the .qmd files -----------------------------------

# Gets the numbers, defines \GSCitations, \GSHIndex and \GSIIndex for use in the
# text, and arranges for the per-paper counts to be added as the document is built.
scholar_setup <- function(id, dir = ".", min_citations = 50,
                          citation_format = "[Citations: %s]", max_age_hours = 12,
                          title_aliases = list(), fetch = scholar_fetch_live) {
  gs <- scholar_get(id, dir = dir, max_age_hours = max_age_hours, fetch = fetch)
  show <- function(v) {
    if (length(v) != 1 || is.na(v)) "n/a" else format(v, scientific = FALSE, trim = TRUE)
  }
  pubs <- gs$publications
  aliases <- as.list(title_aliases)
  knitr::knit_hooks$set(document = function(x) {
    scholar_add_counts(paste(x, collapse = "\n"), pubs, min_citations = min_citations,
                       fmt = citation_format, aliases = aliases)
  })
  knitr::asis_output(paste0(
    "\n```{=latex}\n",
    "\\newcommand{\\GSCitations}{", show(gs$total_cites), "}\n",
    "\\newcommand{\\GSHIndex}{", show(gs$h_index), "}\n",
    "\\newcommand{\\GSIIndex}{", show(gs$i10_index), "}\n",
    "\\newcommand{\\GSCount}[1]{\\unskip\\hskip 0pt plus 1fil\\penalty 200",
    "\\hskip 0pt plus -1fil\\ \\mbox{#1}}\n",
    "```\n"))
}

# ---- A report you can run by hand --------------------------------------------

# Shows, for every paper entry in a .qmd file, the citation count found for it,
# and lists the well-cited Google Scholar papers that matched no entry.
scholar_check <- function(qmd, dir = dirname(qmd), min_citations = 50, title_aliases = list()) {
  text <- paste(readLines(qmd, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  cache <- scholar_read_cache(dir)
  if (is.null(cache) || nrow(cache$publications) == 0) {
    message("No saved Google Scholar papers yet. Render the document once first.")
    return(invisible(NULL))
  }
  pubs <- cache$publications
  rows <- list()
  for (p in scholar_region_patterns) {
    for (h in regmatches(text, gregexpr(p, text, perl = TRUE))[[1]]) {
      e <- scholar_entries(regmatches(h, regexec(p, h, perl = TRUE))[[1]][3])
      for (piece in e$pieces[e$is_entry]) {
        title <- scholar_entry_title(piece)
        hit <- scholar_lookup(title, pubs, as.list(title_aliases))
        rows[[length(rows) + 1]] <- data.frame(
          entry = if (is.na(title)) substr(gsub("\\s+", " ", piece), 1, 60) else title,
          citations = if (is.null(hit)) NA else hit$cites,
          scholar_title = if (is.null(hit)) NA else hit$matched,
          stringsAsFactors = FALSE)
      }
    }
  }
  tab <- do.call(rbind, rows)
  shown <- !is.na(tab$citations) & tab$citations >= min_citations
  message(nrow(tab), " entries; ", sum(!is.na(tab$citations)), " found on Google Scholar; ",
          sum(shown), " show a count (", min_citations, " or more citations).")
  missed <- pubs[pubs$cites >= min_citations & !(pubs$title %in% tab$scholar_title), , drop = FALSE]
  if (nrow(missed) > 0) {
    message("Google Scholar papers with ", min_citations,
            " or more citations that matched no entry:")
    for (i in order(-missed$cites)) message("  ", missed$cites[i], "  ", missed$title[i])
  }
  invisible(tab)
}
