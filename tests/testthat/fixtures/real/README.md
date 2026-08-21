# MMV real-data fixture intake

This directory is reserved for the smallest anonymous fixtures that can be
redistributed with MMV. Raw source files must stay outside Git in
`D:\MMV_real_data_inbox`.

Before adding a fixture, record all of the following in this file or an adjacent
provenance note:

- exporter/acquisition format and software version;
- source file SHA-256 and the deterministic anonymization steps;
- confirmation that names, dates, machine paths, and other identifiers were
  removed;
- permission to redistribute the resulting fixture under the repository
  license;
- expected row count, coordinate range, task, group, and subject inference.

Use these names so the regression test can determine the task:

- `watermaze__<format>.csv` for each distinct water-maze format;
- `minefield__<format>.csv` for each distinct minefield format.

The v0.2.0 release requires at least two water-maze files from distinct formats
and one minefield file. Synthetic templates and rendered preview images do not
count toward this requirement.
