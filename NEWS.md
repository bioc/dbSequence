# dbSequence (development version)

* `read_bed()`, `read_gff()` and `read_vcf()` no longer drop rows. Files with
  chromosome names like `1`, `X` and `MT` lost every non-numeric chromosome;
  UCSC `track` and `browser` lines are now skipped, and a malformed value now
  gives `NA` instead of removing its row.

# dbSequence 0.99.0

* Initial Bioconductor submission candidate.
