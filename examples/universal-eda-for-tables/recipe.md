---
id: universal-eda-for-tables
name: Universal EDA for tables
version: 3
type: user
---

# Universal EDA for tables

## What this recipe does
This recipe performs exploratory data analysis (EDA) on the input table (CSV/TSV/Excel or other text tables).
It imports and sanitizes the data (auto-detecting delimiter/sheet, cleaning column names, trimming whitespace, and normalizing missing values). It produces QC summaries (rows/columns, duplicates, and missingness stats
and generates a set of standard EDA plots: a missingness profile, numeric distributions (histograms + densities), top categorical frequencies, a correlation heatmap and PCA, and an interactive dashboard.

## Steps
1. Input Data
   Binding node for the user-provided input dataset file and optional workflow parameters. The platform supplies INPUT_FILE and optional ID_COLUMN or color_by values here.
2. Data Output
   This will be automatically populated as the workflow runs.
3. Import Normalize
   Reads the file specified in INPUT_FILE, automatically detects delimiter and header rows, skips non‑header lines, loads the data with fread, cleans column names, trims whitespace, converts common missing markers to NA, and writes the sanitized data and provenance metadata.
   Code: `template_code/import_normalize.R`
4. EDA Summary
   Generate a basic quality-control summary including dimensions, column types, missingness, and duplicated rows. Summary artifacts are written as CSV, JSON, and text for reporting.
   Code: `template_code/eda_summary.R`
5. Missingness Plot
   Create the missingness profile using the provided miss_var_summary workflow. The plot is saved only when there is at least one column in the dataset.
   Code: `template_code/missingness_plot.R`
6. Numeric Plots
   Loads the sanitized data, selects numeric columns, optionally keeps the 20 most variable columns when there are more than 10, and creates faceted histograms with density curves. The plot title is updated to indicate when the most‑variable‑20 subset is used, and the figure is saved as PNG and RDS.
   Code: `template_code/numeric_plots.R`
7. Categorical Plots
   Creates a faceted bar chart of the most frequent categories for each character/factor column. If more than 15 variables are present, it limits the plot to the top 15 variables by total count and updates the title accordingly.
   Code: `template_code/categorical_plots.R`
8. Correlation Plot
   Reads the sanitized dataset, computes pairwise Pearson correlations among numeric columns, and generates a heatmap. If more than ten numeric variables are present, axis text is rendered smaller and cell value labels are omitted. The plot is saved as a PNG and the ggplot object is stored as an RDS file.
   Code: `template_code/correlation_plot.R`
9. PCA Plot
   Loads the sanitized data, optionally colors points by a user‑specified column, performs PCA on numeric columns, and saves both a PNG of the first two components and the ggplot object. Writes a status file if insufficient numeric data are available.
   Code: `template_code/pca_plot.R`
10. EDA Dashboard
   Loads any available EDA plot artifacts, merges them with patchwork, saves a static PNG and RDS, then converts the combined plot to a Plotly interactive object and writes a self‑contained HTML dashboard.
   Code: `template_code/eda_dashboard.R`

## Environment
Dependencies are listed in:
- `env/python-requirements.txt`
- `env/r-packages.txt`
- `env/system-tools.txt`

## Notes
Review steps, code, and dependencies as needed.
