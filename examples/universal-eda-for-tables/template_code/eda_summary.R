suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
})

df <- readRDS('artifacts/sanitized_data.rds')

row_count <- nrow(df)
col_count <- ncol(df)
col_types <- tibble(
  column = names(df),
  class = vapply(df, function(x) paste(class(x), collapse = '/'), character(1)),
  missing_n = vapply(df, function(x) sum(is.na(x)), integer(1)),
  missing_pct = vapply(df, function(x) if (row_count > 0) mean(is.na(x)) * 100 else 0, numeric(1))
)

dup_rows <- if (row_count > 0) sum(duplicated(df)) else 0
summary_tbl <- tibble(
  metric = c('nrow', 'ncol', 'duplicate_rows', 'numeric_columns', 'character_columns', 'factor_columns', 'logical_columns'),
  value = c(
    row_count,
    col_count,
    dup_rows,
    sum(vapply(df, is.numeric, logical(1))),
    sum(vapply(df, is.character, logical(1))),
    sum(vapply(df, is.factor, logical(1))),
    sum(vapply(df, is.logical, logical(1)))
  )
)

missing_overview <- tibble(
  total_cells = row_count * col_count,
  total_missing = sum(is.na(df)),
  missing_pct = if (row_count * col_count > 0) sum(is.na(df)) / (row_count * col_count) * 100 else 0
)

readr::write_csv(summary_tbl, 'artifacts/eda_summary.csv')
readr::write_csv(col_types, 'artifacts/column_qc.csv')
jsonlite::write_json(list(
  dimensions = list(nrow = row_count, ncol = col_count),
  duplicate_rows = dup_rows,
  missing_overview = as.list(missing_overview),
  column_types = col_types
), 'artifacts/eda_summary.json', auto_unbox = TRUE, pretty = TRUE, null = 'null')
writeLines(c(
  sprintf('Rows: %s', row_count),
  sprintf('Columns: %s', col_count),
  sprintf('Duplicated rows: %s', dup_rows),
  sprintf('Total missing cells: %s', missing_overview$total_missing),
  sprintf('Overall missingness: %.2f%%', missing_overview$missing_pct)
), 'artifacts/eda_summary.txt')
