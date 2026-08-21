# MMV product audit and v0.2.0 release record

Date: 2026-08-21 Repository: `hurry060215-tech/MMV` Branch:
`feat/product-usability-audit`

## Baseline

MMV is an R-first toolkit for water-maze and minefield trajectory plots.
The baseline implementation had working task-specific plotters, but
onboarding, batch diagnostics, generated help, Unicode-path
verification, optional Python boundaries, and direct publishing behavior
were not sufficiently explicit for ordinary users.

The product audit identified these user-facing risks:

- a new user had to discover several low-level functions before
  producing a first plot;
- malformed CSV or manifest rows could produce errors without enough
  context;
- recursive conversion and non-ASCII filenames were not reliably
  exercised on Windows locales;
- the Python hook had no maintained reference module or versioned
  contract;
- direct publishing helpers could encourage unsafe commits or pushes;
- the pkgdown site and generated help could drift from the source
  package.

## v0.2.0 changes

- [`mmviz_init()`](https://hurry060215-tech.github.io/MMV/reference/mmviz_init.md)
  creates an editable starter project and rolls back newly created files
  if initialization fails part-way through.
- [`plot_mmviz()`](https://hurry060215-tech.github.io/MMV/reference/plot_mmviz.md)
  provides one entry point while preserving the existing task-specific
  plotting APIs.
- Batch output collisions are reported by manifest row and do not stop
  later independent jobs.
- Batch input paths expand `~` before manifest-relative resolution, and
  output collision keys respect case-sensitive POSIX filesystems.
- Output directory creation is checked and errors include actionable
  paths.
- Unicode regression tests require a UTF-8-capable R locale and document
  the Windows `C.UTF-8` environment failure mode without changing global
  settings.
- [`use_python_backend()`](https://hurry060215-tech.github.io/MMV/reference/use_python_backend.md)
  is deprecated for v0.2.x compatibility and scheduled for removal in
  v0.3.0; pure-R plotting is the supported path.
- Direct-push publisher scripts are removed in favor of protected-branch
  PR and tag-based release workflows.

## Real-data gate

The repository now has four author-directory water-maze
coordinate-stream files in the intake and corresponding partial
fixtures. They are all the same observed legacy family, not four
distinct exporter formats. No minefield raw export has been located on
the available D: or E: data roots. Before the v0.2.0 Release, the author
must provide at least one minefield export, confirm the water fixtures
contain no indirect identifiers, and confirm redistribution permission.
Raw files stay outside Git; only deterministic, minimal, anonymous
fixtures and their provenance are committed.

Synthetic templates and existing preview images are not accepted as a
substitute for this gate.

## Validation record

The following checks are required before merge and release:

1.  `pkgload::load_all('.', quiet = TRUE, compile = FALSE)` succeeds.
2.  [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
    has zero failures in a UTF-8-capable Windows session; the Unicode
    test has an explicit capability skip when the host locale cannot
    represent such paths.
3.  `R CMD check --as-cran --no-manual` has zero errors and warnings.
4.  A clean temporary installation can initialize and run both starter
    plots.
5.  Real-data fixtures pass parser, geometry, and visual regression
    checks.
6.  Coverage is at least 80 percent.
7.  Windows, macOS, Ubuntu, oldrel Windows, coverage, and pkgdown checks
    pass on the pull request.
8.  The release workflow verifies exact watermaze/minefield fixture mix,
    completed provenance, and tag/package version equality before
    publishing.

The GitHub Release must not be created until the real-data gate and all
checks above are complete.
