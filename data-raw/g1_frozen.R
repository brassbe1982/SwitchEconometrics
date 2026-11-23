## data-raw/g1_frozen.R -- frozen Generation 1 results (version 1.0.0)
##
## Writes tests/testthat/fixtures/g1_frozen_1.0.0.rds: the results of the
## released version 1.0.0 on the `firms` data. tests/testthat/test-g1-frozen.R
## compares every later version with them at 1e-8 (SOFTWARE_ARCHITECTURE.md
## s.7.1; handoff rule: Generation 1 results must not change).
##
## Run once, from the package root, with the INSTALLED release 1.0.0 (not
## with devtools::load_all()):
##   Rscript --no-init-file data-raw/g1_frozen.R
## The script stops unless the loaded package is exactly version 1.0.0.
## Do not regenerate the file with a later version.

library(SwitchEconometrics)
stopifnot(identical(as.character(utils::packageVersion("SwitchEconometrics")),
                    "1.0.0"))

source("tests/testthat/helper-g1-frozen.R")

fr <- g1_frozen_results()
fr$version <- "1.0.0"
fr$R <- R.version.string
dir.create("tests/testthat/fixtures", showWarnings = FALSE)
saveRDS(fr, "tests/testthat/fixtures/g1_frozen_1.0.0.rds", version = 2)
str(fr, max.level = 1)
