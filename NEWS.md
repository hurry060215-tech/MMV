# MMV 0.1.0.9000

- Added `mmviz_init()` for one-command starter projects and `plot_mmviz()` as
  a unified plotting entry point.
- Added a Getting Started article to the pkgdown site.
- Fixed the installed package test entry point and generated complete help
  pages for every exported function.
- Made batch manifests resolve relative inputs from the manifest directory and
  report failures per row without aborting later jobs.
- Preserved recursive source subdirectories and Unicode filenames during folder
  conversion to prevent output collisions.
- Tightened schema and plot-configuration validation with actionable errors.
- Accepted signed, decimal, and scientific-notation legacy coordinates while
  preventing malformed standard CSV files from being misclassified as legacy
  streams.
- Added cross-platform R CMD check automation and an installed-package example.
