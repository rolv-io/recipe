suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
  library(readxl)
  library(data.table)
})

input <- jsonlite::fromJSON('input.json')
source_file <- input$INPUT_FILE
if (is.null(source_file) || !nzchar(source_file)) stop('INPUT_FILE is required.')

safe_dir_create <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

safe_dir_create('artifacts')
safe_dir_create('plots')
safe_dir_create('reports')

# -------------------------------------------------------------------
# Detect delimiter, header row and number of rows to skip for generic text files
# -------------------------------------------------------------------

detect_csv_structure <- function(file, n_sample = 25, sep_candidates = c("\t", ",", ";", "|")) {
  lines <- readLines(file, n = n_sample, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))] # Remove empty rows
  
  if (length(lines) < 2) return(list(sep = ",", skip = 0))
  
  # 1. Detect delimiter by frequency & consistency across lines
  sep_scores <- sapply(sep_candidates, function(sep) {
    counts <- sapply(strsplit(lines, sep, fixed = TRUE), length)
    if (max(counts) <= 1) return(-1) # Delimiter not present
    # Favor high column counts with consistent field numbers across rows
    median(counts) - sd(counts)
  })
  
  best_sep <- sep_candidates[which.max(sep_scores)]
  
  # 2. Tokenize rows using the detected separator
  tokenized <- strsplit(lines, best_sep, fixed = TRUE)
  
  # 3. Detect the first data row:
  # Look for rows containing purely numeric/measurement values
  is_data_row <- sapply(tokenized, function(tokens) {
    clean_tokens <- trimws(tokens)
    # Check what proportion of fields look like numbers/dates
    num_matches <- grepl("^[0-9]+(\\.[0-9]+)?$", clean_tokens)
    sum(num_matches) >= 3 || (sum(num_matches) / max(1, length(clean_tokens)) > 0.2)
  })
  
  first_data_idx <- which(is_data_row)[1]
  
  # If data is found, header row is immediately before it
  header_idx <- if (!is.na(first_data_idx) && first_data_idx > 1) {
    first_data_idx - 1
  } else {
    1
  }
  
  list(
    sep = best_sep,
    header_line = header_idx,
    skip = header_idx - 1
  )
}

read_table_auto <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c('xlsx', 'xls')) {
    sheets <- readxl::excel_sheets(path)
    sheet <- if (length(sheets) > 0) sheets[1] else 1
    df <- readxl::read_excel(path, sheet = sheet)
    return(list(data = as_tibble(df), source_type = 'excel', sheet = sheet, delimiter = NA_character_))
  }
  
  # Detect delimiter and header/skipping information
  detection <- detect_csv_structure(path)
  delimiter <- detection$sep
  skip_rows <- detection$skip
  
  # Use data.table::fread for fast reading while returning a tibble
  df <- data.table::fread(
    input = path,
    sep = delimiter,
    skip = skip_rows,
    showProgress = FALSE
  ) %>% tibble::as_tibble()
  
  list(data = df, source_type = 'delimited_text', sheet = NA_character_, delimiter = delimiter)
}

imp <- read_table_auto(source_file)
df <- imp$data %>% janitor::clean_names()

df <- df %>% mutate(across(where(is.character), ~ trimws(.x)))
df <- df %>% mutate(across(where(is.character), ~ na_if(.x, '')))
missing_markers <- c('NA', 'N/A', 'NaN', 'NULL', 'null', '.', '?')
df <- df %>% mutate(across(where(is.character), ~ ifelse(.x %in% missing_markers, NA_character_, .x)))

# Log number of numeric columns after cleaning
numeric_cols <- df %>% select(where(is.numeric)) %>% ncol()
message('Number of numeric columns: ', numeric_cols)

saveRDS(df, 'artifacts/sanitized_data.rds')
jsonlite::write_json(
  list(
    source_file = source_file,
    source_type = imp$source_type,
    sheet = imp$sheet,
    delimiter = imp$delimiter,
    nrow = nrow(df),
    ncol = ncol(df)
  ),
  'artifacts/import_metadata.json',
  auto_unbox = TRUE,
  pretty = TRUE,
  null = 'null'
)
