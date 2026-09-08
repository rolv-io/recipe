suppressPackageStartupMessages({
  library(tidyverse)
})

df <- readRDS('artifacts/sanitized_data.rds')

plot_categorical_frequencies <- function(df, max_categories = 8, ncol = 3) {
  cat_df <- df %>% select(where(~ is.character(.) || is.factor(.))) %>% mutate(across(everything(), as.character))
  if (ncol(cat_df) == 0) {
    message('No categorical/character columns detected.')
    return(NULL)
  }
  # Transform to long format and get counts per category
  df_long <- cat_df %>%
    pivot_longer(everything(), names_to = 'variable', values_to = 'category') %>%
    filter(!is.na(category)) %>%
    group_by(variable, category) %>%
    tally() %>%
    group_by(variable) %>%
    slice_max(n, n = max_categories, with_ties = FALSE) %>%
    ungroup()

  # If more than 15 variables, keep only the top 15 by total count
  limit_vars <- FALSE
  if (n_distinct(df_long$variable) > 15) {
    limit_vars <- TRUE
    top_vars <- df_long %>%
      group_by(variable) %>%
      summarise(total = sum(n), .groups = 'drop') %>%
      slice_max(total, n = 15, with_ties = FALSE) %>%
      pull(variable)
    df_long <- df_long %>% filter(variable %in% top_vars)
  }

  plot_title <- if (limit_vars) {
    'Top 15 Categorical Variable Frequencies'
  } else {
    'Categorical Value Frequencies'
  }

  df_long %>%
    ggplot(aes(x = reorder(category, n), y = n)) +
    geom_col(fill = '#5cb85c', width = 0.7) +
    # Truncate very long category names to keep the plot readable
    scale_x_discrete(labels = function(x) stringr::str_trunc(x, width = 30, side = 'right')) +
    coord_flip() +
    facet_wrap(~ variable, scales = 'free', ncol = ncol) +
    labs(title = plot_title, x = NULL, y = 'Count') +
    theme_minimal(base_size = 11) +
    theme(strip.text = element_text(face = 'bold'))
}

p <- plot_categorical_frequencies(df, max_categories = 8, ncol = 3)
if (is.null(p)) {
  writeLines('Skipped: no categorical/character columns detected.', 'artifacts/categorical_status.txt')
} else {
  ggplot2::ggsave('plots/categorical_frequencies.png', p, width = 12, height = 8, dpi = 150)
  saveRDS(p, 'artifacts/categorical_frequencies_plot.rds')
}
