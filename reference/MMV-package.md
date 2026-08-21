# MMV: water-maze and minefield trajectory visualization

MMV reads a shared trajectory schema, converts supported legacy
coordinate streams, and creates water-maze or minefield plots in R.
Start with
[`read_mmviz_csv()`](https://hurry060215-tech.github.io/MMV/reference/read_mmviz_csv.md),
[`plot_watermaze()`](https://hurry060215-tech.github.io/MMV/reference/plot_watermaze.md),
or
[`plot_minefield()`](https://hurry060215-tech.github.io/MMV/reference/plot_minefield.md).
Use
[`plot_batch()`](https://hurry060215-tech.github.io/MMV/reference/plot_batch.md)
for manifest-driven rendering.

## Details

Standard CSV files require the columns `subject_id`, `group`,
`trial_id`, `frame`, `x`, and `y`. The optional columns are `time_sec`
and `event`.

## See also

Useful links:

- <https://hurry060215-tech.github.io/MMV/>

- <https://github.com/hurry060215-tech/MMV>

- Report bugs at <https://github.com/hurry060215-tech/MMV/issues>

## Author

**Maintainer**: Haoliang Zhu <hurry060215@gmail.com>

Authors:

- Haoliang Zhu <hurry060215@gmail.com>
