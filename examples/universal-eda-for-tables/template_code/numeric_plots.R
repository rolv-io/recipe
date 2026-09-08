suppressPackageStartupMessages({
  library(tidyverse)
})

df <- readRDS('artifacts/sanitized_data.rds')

plot_numeric_distributions <- function(df, bins = 30, ncol = 3) {
  num_df <- df %>% select(where(is.numeric))
  if (ncol(num_df) == 0) {
    message('No numeric columns detected.')
    return(NULL)
  }
  # If more than 10 numeric variables, keep the 20 most variable (highest variance) columns
  title_text <- 'Numeric Feature Distributions'
  if (ncol(num_df) > 10) {
    var_df <- num_df %>% summarise(across(everything(), ~ var(.x, na.rm = TRUE)))
    top_vars <- var_df %>%
      pivot_longer(everything(), names_to = 'variable', values_to = 'variance') %>%
      arrange(desc(variance)) %>%
      slice_head(n = 20) %>%
      pull(variable)
    num_df <- num_df %>% select(all_of(top_vars))
    # Append note to title when subsetting occurs
    title_text <- paste0(title_text, ' (most variable 20)')
  }
  num_df %>%
    pivot_longer(everything(), names_to = 'variable', values_to = 'value') %>%
    filter(!is.na(value)) %>%
    ggplot(aes(x = value)) +
    geom_histogram(aes(y = after_stat(density)), bins = bins, fill = '#337ab7', color = 'white', alpha = 0.7) +
    geom_density(color = '#1b4f72', linewidth = 0.8) +
    facet_wrap(~ variable, scales = 'free', ncol = ncol) +
    labs(title = title_text, x = 'Value', y = 'Density') +
    theme_minimal(base_size = 11) +
    theme(strip.text = element_text(face = 'bold'))
}

p <- plot_numeric_distributions(df, bins = 30, ncol = 3)
if (is.null(p)) {
  writeLines('Skipped: no numeric columns detected.', 'artifacts/numeric_status.txt')
} else {
  ggplot2::ggsave('plots/numeric_distributions.png', p, width = 12, height = 8, dpi = 150)
  saveRDS(p, 'artifacts/numeric_distributions_plot.rds')
}