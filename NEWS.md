# MMV 0.2.0

- Stabilized one-command onboarding with rollback on partial initialization
  failures and clearer output-directory errors.
- Added manifest duplicate-output detection and row-numbered batch failures.
- Added Windows UTF-8 troubleshooting and locale-aware Unicode path tests.
- Deprecated the optional Python hook for compatibility; pure-R plotting remains
  the supported path and the hook is scheduled for removal in 0.3.0.
- Added real-data fixture and geometry-regression hooks, pending author-provided
  anonymized files and redistribution permission.
- Reworked CI and pkgdown publishing around pull requests, coverage, and tagged
  releases; direct-push publisher scripts are no longer supported.

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
