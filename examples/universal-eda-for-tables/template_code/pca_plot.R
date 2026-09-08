suppressPackageStartupMessages({
  library(tidyverse)
})

df <- readRDS('artifacts/sanitized_data.rds')
input <- jsonlite::fromJSON('input.json')
color_by <- input$color_by
if (is.null(color_by) || !nzchar(color_by)) color_by <- NULL

plot_pca <- function(df, color_by = NULL) {
  num_df <- df %>% select(where(is.numeric)) %>% select(where(~ mean(is.na(.)) < 0.2)) %>% na.omit()
  if (ncol(num_df) < 2) {
    message('Not enough clean numeric columns for PCA.')
    return(NULL)
  }
  pca_res <- prcomp(num_df, scale. = TRUE, center = TRUE)
  var_explained <- (pca_res$sdev^2) / sum(pca_res$sdev^2) * 100
  pca_coords <- as.data.frame(pca_res$x)
  if (!is.null(color_by) && color_by %in% colnames(df)) {
    pca_coords$color_group <- df[[color_by]][complete.cases(num_df)]
  }
  p <- ggplot(pca_coords, aes(x = PC1, y = PC2)) +
    labs(
      title = 'PCA Projection (First Two Components)',
      x = sprintf('PC1 (%.1f%% Variance)', var_explained[1]),
      y = sprintf('PC2 (%.1f%% Variance)', var_explained[2])
    ) +
    theme_minimal(base_size = 12)
  if (!is.null(color_by) && 'color_group' %in% colnames(pca_coords)) {
    p <- p + geom_point(aes(color = as.factor(color_group)), alpha = 0.7, size = 2) + labs(color = color_by)
  } else {
    p <- p + geom_point(color = '#2c3e50', alpha = 0.6, size = 2)
  }
  p
}

p <- plot_pca(df, color_by = color_by)
if (is.null(p)) {
  writeLines('Skipped: not enough clean numeric columns for PCA.', 'artifacts/pca_status.txt')
} else {
  ggplot2::ggsave('plots/pca_projection.png', p, width = 10, height = 8, dpi = 150)
  saveRDS(p, 'artifacts/pca_plot.rds')
}
