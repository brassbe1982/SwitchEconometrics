## Attaching data to a specification (se_build_data)

test_that("the estimation data are built correctly", {
  d <- sim_esr_data(300)
  sd <- se_build_data(esr_spec(), d)
  expect_s3_class(sd, "switch_data")
  expect_identical(sd$n, 300L)
  expect_identical(sd$S, d$S)
  expect_identical(sd$y, d$y)
  expect_identical(colnames(sd$Z), c("(Intercept)", "x1", "z1"))
  expect_identical(names(sd$X), c("regime_0", "regime_1"))
  expect_identical(colnames(sd$X$regime_1), c("(Intercept)", "x1", "x2"))
  expect_identical(nrow(sd$X$regime_0), 300L)        # all units, not only S = 0
  expect_identical(unname(sd$n_regime), c(sum(d$S == 0), sum(d$S == 1)))
  expect_identical(sd$exclusions, list(regime_0 = "z1", regime_1 = "z1"))
  expect_identical(sd$na_report$n_dropped, 0L)
  expect_output(print(sd), "300 observations")
})

test_that("logical, 0/1 and factor regime indicators are equivalent", {
  d <- sim_esr_data(200)
  base <- se_build_data(esr_spec(), d)$S
  dl <- d; dl$S <- d$S == 1
  expect_identical(se_build_data(esr_spec(), dl)$S, base)
  df <- d; df$S <- factor(ifelse(d$S == 1, "yes", "no"), levels = c("no", "yes"))
  sdf <- se_build_data(esr_spec(), df)
  expect_identical(sdf$S, base)
  expect_identical(sdf$regime_values, c("no", "yes"))
  ## the second factor level is regime 1, whatever its name
  dr <- d; dr$S <- factor(ifelse(d$S == 1, "A", "B"), levels = c("B", "A"))
  expect_identical(se_build_data(esr_spec(), dr)$S, base)
})

test_that("invalid regime indicators are refused", {
  d <- sim_esr_data(100)
  d2 <- d; d2$S[1] <- 2
  expect_error(se_build_data(esr_spec(), d2), "coded 0/1",
               class = "switch_error_data")
  d3 <- d; d3$S <- ifelse(d$S == 1, "yes", "no")
  expect_error(se_build_data(esr_spec(), d3), "factor",
               class = "switch_error_data")
  d4 <- d; d4$S <- factor(sample(c("a", "b", "c"), 100, TRUE))
  expect_error(se_build_data(esr_spec(), d4), "exactly 2 levels",
               class = "switch_error_data")
  expect_error(se_build_data(esr_spec(), d, subset = d$S == 1),
               "no observations", class = "switch_error_data")
})

test_that("outcome equations are matched to regimes by name or position", {
  d <- sim_esr_data(200)
  s_rev <- switch_model(S ~ x1 + z1,
                        list(regime_1 = y ~ x1 + x2, regime_0 = y ~ x1))
  sd <- se_build_data(s_rev, d)
  expect_identical(sd$regimes, c("regime_0", "regime_1"))
  expect_identical(colnames(sd$X$regime_0), c("(Intercept)", "x1"))
  df <- d; df$S <- factor(ifelse(d$S == 1, "yes", "no"))
  s_lev <- switch_model(S ~ x1 + z1, list(yes = y ~ x1 + x2, no = y ~ x1))
  sd2 <- se_build_data(s_lev, df)
  expect_identical(sd2$regimes, c("no", "yes"))
  expect_identical(ncol(sd2$X$yes), 3L)
  s_pos <- switch_model(S ~ x1 + z1, list(non = y ~ x1, adopt = y ~ x1 + x2))
  expect_message(sd3 <- se_build_data(s_pos, d),
                 class = "switch_message_regime_mapping")
  expect_identical(sd3$regimes, c("non", "adopt"))
  ## unnamed lists are positional without a message
  expect_silent(se_build_data(switch_model(S ~ x1 + z1, list(y ~ x1, y ~ x1)),
                              d))
})

test_that("missing values are removed with a report, never silently", {
  d <- sim_esr_data(250)
  d$x1[c(3, 10)] <- NA
  d$z1[c(10, 20, 30)] <- NA
  ids <- which(d$S == 1 & !seq_len(250) %in% c(3, 10, 20, 30))[1:2]
  d$y[ids] <- NA
  expect_message(sd <- se_build_data(esr_spec(), d),
                 class = "switch_message_missing")
  expect_identical(sd$na_report$n_dropped, 6L)
  expect_identical(sd$na_report$n_used, 244L)
  expect_identical(sd$n, 244L)
  bv <- sd$na_report$by_variable
  expect_identical(bv$n_missing[bv$variable == "x1"], 2L)
  expect_identical(bv$n_missing[bv$variable == "z1"], 3L)
  expect_true(any(grepl("in its regime", bv$variable)))
  expect_false(any(sd$index %in% c(3, 10, 20, 30, ids)))
  expect_identical(sort(sd$na_report$rows), sort(c(3L, 10L, 20L, 30L, ids)))
  expect_error(se_build_data(esr_spec(), d, missing = "fail"),
               class = "switch_error_missing")
})

test_that("an outcome missing in the other regime is not a missing value", {
  d <- sim_esr_data(150)
  d$y1 <- ifelse(d$S == 1, d$y, NA)
  d$y0 <- ifelse(d$S == 0, d$y, NA)
  s <- switch_model(S ~ x1 + z1, list(y0 ~ x1, y1 ~ x1))
  expect_silent(sd <- se_build_data(s, d))
  expect_identical(sd$n, 150L)
  expect_identical(sd$y, d$y)
})

test_that("weights, clusters and subsets are resolved in all three forms", {
  d <- sim_esr_data(200)
  s <- esr_spec()
  w1 <- se_build_data(s, d, weights = ~ w)$weights
  w2 <- se_build_data(s, d, weights = "w")$weights
  w3 <- se_build_data(s, d, weights = d$w)$weights
  expect_identical(w1, d$w); expect_identical(w2, w1); expect_identical(w3, w1)
  sd <- se_build_data(s, d, cluster = "cl")
  expect_identical(sd$cluster, as.integer(factor(d$cl)))
  expect_identical(sd$n_clusters, length(unique(d$cl)))
  expect_silent(ss <- se_build_data(s, d, subset = ~ x2 > 0))
  expect_identical(ss$n, sum(d$x2 > 0))
  expect_identical(ss$na_report$n_dropped, 0L)
  dz <- d; dz$w[1] <- 0
  expect_error(se_build_data(s, dz, weights = ~ w), "strictly positive",
               class = "switch_error_data")
  expect_error(se_build_data(s, d, weights = 1:3),
               class = "switch_error_argument")
  expect_error(se_build_data(s, d, cluster = "nope"),
               class = "switch_error_data")
  expect_error(se_build_data(s, d, subset = d$x1),
               class = "switch_error_argument")
  expect_error(se_build_data(s, d, weights = w ~ x),
               class = "switch_error_argument")
})

test_that("non-finite values and rank deficiency are reported", {
  d <- sim_esr_data(200)
  di <- d; di$x2[5] <- Inf
  expect_error(se_build_data(esr_spec(), di), "non-finite",
               class = "switch_error_data")
  d$x3 <- 2 * d$x1
  s <- switch_model(S ~ x1 + z1, list(y ~ x1 + x3, y ~ x1))
  e <- expect_error(se_build_data(s, d), class = "switch_error_rank")
  expect_identical(e$aliased, "x3")
  ## a regressor constant within one regime
  d$c1 <- ifelse(d$S == 1, 1, rnorm(200))
  s2 <- switch_model(S ~ x1 + z1, list(y ~ x1, y ~ x1 + c1))
  expect_error(se_build_data(s2, d), "within its regime",
               class = "switch_error_rank")
  expect_s3_class(se_build_data(s2, d, check_rank = FALSE), "switch_data")
})

test_that("factors, transformations and variables outside the data work", {
  d <- sim_esr_data(240)
  ext <- rnorm(240)
  s <- switch_model(S ~ x1 + z1 + ext, list(y ~ g + log(abs(x2) + 1),
                                           y ~ g + x1))
  sd <- se_build_data(s, d)
  expect_identical(sd$xlevels$regime_0$g, c("a", "b", "c"))
  expect_true("log(abs(x2) + 1)" %in% colnames(sd$X$regime_0))
  expect_true("ext" %in% colnames(sd$Z))
  sd2 <- se_build_data(s, d, subset = d$g != "c")
  expect_identical(sd2$xlevels$regime_0$g, c("a", "b"))
  expect_identical(nrow(sd2$Z), sum(d$g != "c"))
})

test_that("non-numeric outcomes are reserved for Generation 4", {
  d <- sim_esr_data(100)
  d$yf <- factor(d$y > 1)
  s <- switch_model(S ~ x1 + z1, list(yf ~ x1, yf ~ x1))
  expect_error(se_build_data(s, d), "Generation 4",
               class = "switch_error_unsupported")
})

test_that("bad inputs to the data builder give classed errors", {
  expect_error(se_build_data(list(), sim_esr_data(20)),
               class = "switch_error_argument")
  expect_error(se_build_data(esr_spec(), as.matrix(sim_esr_data(20))),
               class = "switch_error_data")
  expect_error(se_build_data(esr_spec(), sim_esr_data(20)[0, ]),
               class = "switch_error_data")
  s <- switch_model(S ~ nothere, list(y ~ x1, y ~ x1))
  expect_error(se_build_data(s, sim_esr_data(20)), "selection formula",
               class = "switch_error_data")
})
