suppressPackageStartupMessages({
  library(tidyverse)
  library(corrr)
})

df <- readRDS('artifacts/sanitized_data.rds')

plot_correlation_matrix <- function(df, method = 'pearson') {
  num_df <- df %>% select(where(is.numeric))
  if (ncol(num_df) < 2) {
    message('Need at least 2 numeric columns for a correlation matrix.')
    return(NULL)
  }
  # Base plot with tiles
  p <- num_df %>%
    corrr::correlate(method = method, quiet = TRUE) %>%
    corrr::stretch() %>%
    filter(!is.na(r)) %>%
    ggplot(aes(x = x, y = y, fill = r)) +
    geom_tile(color = 'white')
  # Add numeric labels only when there are <= 10 variables
  if (ncol(num_df) <= 10) {
    p <- p + geom_text(aes(label = sprintf('%.2f', r)), size = 3)
  }
  p <- p +
    scale_fill_gradient2(
      low = '#d73027', mid = '#f7f7f7', high = '#1a9850',
      midpoint = 0, limits = c(-1, 1)
    ) +
    labs(
      title = sprintf('Correlation Heatmap (%s)', stringr::str_to_title(method)),
      x = NULL, y = NULL, fill = expression(r)
    ) +
    theme_minimal(base_size = 12) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid = element_blank()
    )
  # Reduce axis label size when >10 variables
  if (ncol(num_df) > 10) {
    p <- p + theme(axis.text = element_text(size = 6))
  }
  return(p)
}

p <- plot_correlation_matrix(df, method = 'pearson')
if (is.null(p)) {
  writeLines('Skipped: fewer than 2 numeric columns available for correlation heatmap.', 'artifacts/correlation_status.txt')
} else {
  ggplot2::ggsave('plots/correlation_heatmap.png', p, width = 8, height = 6, dpi = 300)
  saveRDS(p, 'artifacts/correlation_heatmap_plot.rds')
}