#!/usr/bin/env Rscript

# Load required libraries
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(naniar)
})

# Ensure output directories exist
if (!dir.exists('artifacts')) dir.create('artifacts', recursive = TRUE)
if (!dir.exists('plots')) dir.create('plots', recursive = TRUE)

# Verify input data exists
input_path <- 'artifacts/sanitized_data.rds'
if (!file.exists(input_path)) {
  writeLines('Skipped: input file artifacts/sanitized_data.rds not found.',
             'artifacts/missingness_status.txt')
  quit(status = 0)
}

# Load the data frame from the RDS file
df <- readRDS(input_path)

# Guard against empty data
if (is.null(df) || ncol(df) == 0) {
  writeLines('Skipped: no columns available for missingness plot.',
             'artifacts/missingness_status.txt')
  quit(status = 0)
}

# Compute missingness percentage per variable (using naniar for convenience)
miss_summary <- miss_var_summary(df) %>%
  select(variable, pct_miss)

# Keep top 30 variables with the highest missingness
miss_top <- miss_summary %>%
  arrange(desc(pct_miss)) %>%
  slice_head(n = 30)

if (nrow(miss_top) == 0) {
  writeLines('Skipped: no missingness information available for plotting.',
             'artifacts/missingness_status.txt')
  quit(status = 0)
}

# Create a clean, publication‑ready horizontal bar plot
p <- ggplot(miss_top, aes(x = pct_miss, y = reorder(variable, pct_miss))) +
  geom_col(fill = '#D55E00') +
  scale_x_continuous(labels = scales::percent_format(scale = 1), limits = c(0, 100)) +
  labs(x = '% Missing Values', y = NULL,
       title = paste0('Missingness by Variable (Top ', nrow(miss_top), ')')) +
  theme_minimal(base_size = 12) +
  theme(axis.text.y = element_text(hjust = 1))

# Save PNG at high resolution
plot_path <- 'plots/missingness_profile.png'
ggsave(filename = plot_path, plot = p, width = 10, height = 7, dpi = 300, units = 'in')

# Serialize the ggplot object for downstream nodes
rds_path <- 'artifacts/missingness_plot.rds'
saveRDS(p, file = rds_path)

# Clean exit
quit(status = 0)
