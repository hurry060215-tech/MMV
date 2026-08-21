# Real-data fixture provenance

Status: PARTIAL - MINEFIELD SOURCE AND FINAL AUTHOR CONFIRMATION PENDING

This file must be completed before the v0.2.0 release. It is intentionally not
treated as release evidence while any `PENDING`, `TODO`, or `not confirmed`
marker remains.

For every committed fixture, record:

- source file path outside Git and SHA-256;
- exporter/acquisition software and version;
- the exact anonymization and minimization steps;
- confirmation that direct identifiers, dates, machine paths, and comments were
  removed;
- redistribution permission: pending until the data owner explicitly confirms
  that the fixture may be distributed under the repository license;
- expected rows, coordinate ranges, task, group, and subject inference.

## Current water-maze intake

The four files below came from the author's local experiment directory and are
all legacy quoted coordinate-stream exports containing embedded NUL bytes. They
are retained as separate representative trajectories; they are not being
claimed as four distinct exporter formats.

| Fixture | SHA-256 | Rows | Coordinate range |
|---|---|---:|---|
| `watermaze__legacy_nm.csv` | `3F7CAED44B925C29E80E8502FDCE251930B6CED9403DCCE0BB6437EDF39A0300` | 3601 | x 27..525, y 41..526 |
| `watermaze__legacy_nmp.csv` | `5C7F491DE51731F051678274CE2914B3B06CAEDE2085E8E513BC2BF046B9E562` | 1916 | x 94..518, y 14..522 |
| `watermaze__legacy_sah.csv` | `7B3FD610B152748C21AB96596ED6523146BA66E6D0E14C77A74D5F627F66EE0A` | 3599 | x 15..470, y 11..531 |
| `watermaze__legacy_sham.csv` | `295DABBF152A699DC30A8CA9B66B339C7DA6598896FC58E4B75CD2DFD6674EBC` | 1916 | x 96..508, y 25..481 |

Anonymization currently consists of retaining coordinate streams only and
renaming files to group-level fixture names. The author must still confirm that
these files contain no indirect identifiers and may be redistributed.

No minefield raw export has been located on the available D: or E: data roots.
