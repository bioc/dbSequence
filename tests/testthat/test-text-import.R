bed_line <- function(chr, start) sprintf("%s\t%d\t%d\tfeat\t0\t+", chr, start, start + 10L)
write_lines <- function(lines, ext) {
  path <- tempfile(fileext = ext)
  writeLines(lines, path)
  path
}

# Enough rows on chromosome "1" that DuckDB would otherwise guess the
# chromosome column is a number and drop the X, Y and MT rows.
ensembl_bed <- write_lines(
  c(bed_line("1", seq_len(30000) * 20L), bed_line("X", 20L), bed_line("Y", 20L), bed_line("MT", 20L)),
  ".bed"
)

test_that("BED keeps every chromosome, lazy or imported", {
  for (lazy in c(TRUE, FALSE)) {
    rows <- dplyr::collect(read_bed(ensembl_bed, lazy = lazy, table_name = "ensembl")@value)
    expect_equal(nrow(rows), 30003)
    expect_setequal(unique(rows$seqnames), c("1", "X", "Y", "MT"))
  }
})

test_that("VCF keeps every chromosome", {
  vcf <- write_lines(c(
    "##fileformat=VCFv4.2",
    "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO",
    sprintf("1\t%d\t.\tA\tG\t50\tPASS\t.", seq_len(30000)),
    "X\t100\t.\tA\tG\t.\tPASS\t."
  ), ".vcf")
  rows <- dplyr::collect(read_vcf(vcf)@value)
  expect_equal(nrow(rows), 30001)
  expect_true("X" %in% rows$seqnames)
})

test_that("BED skips track lines and keeps malformed rows as NA", {
  bed <- write_lines(c(
    "browser position chr1:1-1000",
    "track name=peaks",
    "chr1\t100\t110\tf\t0\t+",
    "chr1\tbad\t200\tf\t0\t+"
  ), ".bed")
  rows <- dplyr::collect(read_bed(bed)@value)
  expect_equal(nrow(rows), 2)
  expect_equal(rows$start, c(101, NA))  # 0-based BED start 100 -> 1-based 101
  expect_equal(rows$end, c(110, 200))
})
