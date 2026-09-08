suppressPackageStartupMessages({
  library(patchwork)
  library(ggplot2)
  library(plotly)
  library(htmltools)
})

# Provide a fallback for after_stat if ggplot2 version is old
if (!"after_stat" %in% ls("package:ggplot2")) {
  utils::assignInNamespace("after_stat", function(x) x, ns = "ggplot2")
}

plot_paths <- c(
  missingness = 'artifacts/missingness_plot.rds',
  numeric = 'artifacts/numeric_distributions_plot.rds',
  categorical = 'artifacts/categorical_frequencies_plot.rds',
  correlation = 'artifacts/correlation_heatmap_plot.rds',
  pca = 'artifacts/pca_plot.rds'
)

plots <- list()
for (nm in names(plot_paths)) {
  if (file.exists(plot_paths[[nm]])) plots[[nm]] <- readRDS(plot_paths[[nm]])
}

if (length(plots) == 0) {
  writeLines('Skipped: no plot artifacts were available for dashboard composition.', 'artifacts/dashboard_status.txt')
} else {
  # 1. Static combined PNG via patchwork
  combined <- wrap_plots(plots, ncol = 2)
  ggplot2::ggsave('plots/eda_dashboard.png', combined, width = 16, height = 12, dpi = 150)
  saveRDS(combined, 'artifacts/eda_dashboard_plot.rds')

  # 2. Convert each ggplot to an independent plotly widget with standardized height
  plotly_list <- lapply(plots, function(p) {
    ggplotly(p, height = 750)
  })

  # 3. Create Bootstrap tab navigation items
  tab_nav <- tags$ul(
    class = "nav nav-tabs",
    role = "tablist",
    lapply(seq_along(plotly_list), function(i) {
      nm <- names(plotly_list)[i]
      tags$li(
        role = "presentation",
        class = if (i == 1) "active" else "",
        tags$a(
          href = paste0("#tab-", i),
          `aria-controls` = paste0("tab-", i),
          role = "tab",
          `data-toggle` = "tab",
          tools::toTitleCase(nm)
        )
      )
    })
  )

  # 4. Create Bootstrap tab content panels containing the plotly widgets
  tab_content <- tags$div(
    class = "tab-content",
    style = "padding-top: 20px;",
    lapply(seq_along(plotly_list), function(i) {
      tags$div(
        role = "tabpanel",
        class = paste("tab-pane", if (i == 1) "active" else ""),
        id = paste0("tab-", i),
        plotly_list[[i]]
      )
    })
  )

  # 5. Assemble the HTML document shell
  dashboard_doc <- tags$html(
    tags$head(
      tags$meta(charset = "utf-8"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      tags$title("EDA Dashboard"),
      tags$link(
        rel = "stylesheet",
        href = "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
      ),
      tags$script(src = "https://code.jquery.com/jquery-3.6.0.min.js"),
      tags$script(src = "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js")
    ),
    tags$body(
      tags$div(
        class = "container-fluid",
        style = "padding: 30px;",
        tags$h2("Exploratory Data Analysis Dashboard", style = "margin-bottom: 20px; font-weight: 600;"),
        tags$p(class = "text-muted", "Interactive inspection of pipeline metrics and distributions."),
        tags$hr(),
        tab_nav,
        tab_content
      ),
      # Trigger a resize event when switching tabs so Plotly redraws to full width
      tags$script(HTML("
        $('a[data-toggle=\"tab\"]').on('shown.bs.tab', function (e) {
          window.dispatchEvent(new Event('resize'));
        });
      "))
    )
  )

  # 6. Save as a self-contained HTML page
  save_html(dashboard_doc, file = "plots/eda_dashboard.html")
}