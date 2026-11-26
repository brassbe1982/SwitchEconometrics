## Layer 6: bootstrap (specification s.5.7, s.16; API_SPECIFICATION.md s.2).

#' Bootstrap a fitted switching model
#'
#' Re-estimates the model on `R` bootstrap samples and returns bootstrap
#' standard errors, the covariance matrix and percentile and normal
#' confidence intervals. For two-step fits this gives standard errors of
#' \eqn{\sigma_j} and \eqn{\rho_j}, which have no closed form.
#'
#' * `type = "nonparametric"` resamples observations with replacement, or
#'   whole clusters when the fit has clusters (or `cluster` is given).
#' * `type = "parametric"` keeps the covariates and redraws the regimes and
#'   outcomes from the fitted model: \eqn{u \sim N(0, 1)},
#'   \eqn{S = 1\{z'\hat\gamma + u > 0\}} and, for the realised regime,
#'   \eqn{\varepsilon_j \mid u \sim N(\hat\sigma_j\hat\rho_j u,
#'   \hat\sigma_j^2(1 - \hat\rho_j^2))}. No assumption on the unidentified
#'   correlation of \eqn{\varepsilon_1} and \eqn{\varepsilon_0} is needed.
#'
#' Each replicate is refitted with the original method and controls; FIML
#' starts from the original estimate (one start), and from the two-step
#' estimate if that fails. Replicates whose estimation fails or does not
#' converge are excluded and counted in `failures`.
#'
#' Replication `r` uses the `r`-th L'Ecuyer-CMRG stream derived from `seed`,
#' so the results do not depend on `cores`. The global random-number state
#' and generator kind are restored afterwards. With `seed = NULL` a seed is
#' drawn from the current random-number stream.
#'
#' @param object A `switch_fit` fitted with `keep_data = TRUE`.
#' @param R Number of bootstrap replicates.
#' @param type `"nonparametric"` or `"parametric"`.
#' @param cluster `NULL` (use the fit's clusters, if any), `FALSE` (resample
#'   observations), or a vector of cluster identifiers for the estimation
#'   sample (length `nobs(object)`).
#' @param statistics Statistics to bootstrap: `"coef"` (natural-scale
#'   parameters) or `"effects"` (ATT, ATU, ATE, TH, BH1, BH0 of
#'   [switch_effects()], recomputed on each bootstrap sample, so that their
#'   intervals reflect the sampling variation of the covariates).
#' @param cores Number of worker processes. Examples and tests use at most 2.
#' @param seed Seed of the bootstrap streams.
#' @param level Confidence level of the intervals.
#' @param x,parm Arguments of the `print`, `vcov` and `confint` methods.
#' @param digits Significant digits printed.
#' @param ... Not used.
#' @return An object of class `switch_bootstrap` with elements `replicates`
#'   (successful replicates x parameters), `estimate`, `bias`, `se`, `vcov`,
#'   `ci_percentile`, `ci_normal`, `failures` and the settings.
#' @examples
#' set.seed(2)
#' n <- 400
#' d <- data.frame(x1 = rnorm(n), z1 = rnorm(n))
#' u <- rnorm(n)
#' d$S <- as.integer(0.3 + 0.5 * d$x1 - 0.6 * d$z1 + u > 0)
#' d$y <- ifelse(d$S == 1, 1 + d$x1 + 0.5 * u + rnorm(n),
#'               0.5 * d$x1 + 0.3 * u + rnorm(n))
#' fit <- switch_fit(S ~ x1 + z1, list(y ~ x1, y ~ x1), data = d,
#'                   method = "two_step")
#' b <- switch_bootstrap(fit, R = 20, seed = 1)
#' b
#' @export
switch_bootstrap <- function(object, R = 999L,
                             type = c("nonparametric", "parametric"),
                             cluster = NULL, statistics = c("coef", "effects"),
                             cores = 1L, seed = NULL, level = 0.95, ...) {
  dots <- list(...)
  eff_args <- dots$.effects
  if (!inherits(object, "switch_fit")) {
    se_abort("'object' must be a switch_fit", "argument")
  }
  sd <- object$data
  if (is.null(sd)) {
    se_abort("the bootstrap needs the data; refit with switch_control(keep_data = TRUE)",
             "argument")
  }
  type <- match.arg(type)
  statistics <- match.arg(statistics)
  ## effects: groups and subset carried by original row index so that they
  ## follow the units through resampling
  eff <- NULL
  if (statistics == "effects") {
    lk <- function(v) {
      if (is.null(v)) return(NULL)
      out <- v[rep(NA_integer_, max(sd$index))]
      out[sd$index] <- v
      out
    }
    eff <- list(by = lk(eff_args$by), subset = lk(eff_args$subset))
  }
  if (!is.numeric(R) || length(R) != 1L || R < 2 || R != round(R)) {
    se_abort("'R' must be a whole number of at least 2", "argument")
  }
  if (!is.numeric(cores) || length(cores) != 1L || cores < 1) {
    se_abort("'cores' must be a positive whole number", "argument")
  }
  cl_ids <- if (isFALSE(cluster)) NULL
            else if (is.null(cluster)) sd$cluster
            else {
              if (length(cluster) != sd$n) {
                se_abort(sprintf("'cluster' must have length nobs(object) = %d",
                                 sd$n), "argument")
              }
              as.integer(factor(cluster))
            }
  if (type == "parametric" && object$method == "two_step" &&
      any(object$two_step$rho_out_of_range)) {
    se_abort("parametric bootstrap impossible: a two-step rho lies outside (-1, 1)",
             "argument")
  }

  ## streams (restore the caller's RNG kind and state afterwards)
  if (is.null(seed)) seed <- sample.int(.Machine$integer.max, 1L)
  genv <- globalenv()
  old_kind <- RNGkind()
  had <- exists(".Random.seed", envir = genv, inherits = FALSE)
  old_seed <- if (had) get(".Random.seed", envir = genv, inherits = FALSE)
  on.exit({
    RNGkind(old_kind[1L], old_kind[2L], old_kind[3L])
    if (had) assign(".Random.seed", old_seed, envir = genv)
    else if (exists(".Random.seed", envir = genv, inherits = FALSE)) {
      rm(".Random.seed", envir = genv)
    }
  })
  RNGkind("L'Ecuyer-CMRG")
  set.seed(seed)
  s <- get(".Random.seed", envir = genv)
  seeds <- vector("list", R)
  for (r in seq_len(R)) {
    s <- parallel::nextRNGStream(s)
    seeds[[r]] <- s
  }

  t0 <- proc.time()[["elapsed"]]
  res <- if (cores > 1L) {
    pcl <- parallel::makeCluster(min(as.integer(cores), R),
                                 rscript_args = "--no-init-file")
    on.exit(parallel::stopCluster(pcl), add = TRUE)
    parallel::clusterEvalQ(pcl, suppressPackageStartupMessages(
      requireNamespace("SwitchEconometrics", quietly = TRUE)))
    parallel::parLapply(pcl, seeds, se_boot_worker,
                        obj = object, dat = sd, ty = type, ids = cl_ids,
                        stat = statistics, eff = eff)
  } else {
    lapply(seeds, function(sd_r) se_boot_one(object, sd, type, cl_ids, sd_r,
                                             statistics, eff))
  }
  elapsed <- proc.time()[["elapsed"]] - t0

  ok <- vapply(res, function(x) isTRUE(x$ok), logical(1))
  est <- if (statistics == "coef") object$coefficients
         else se_boot_stat(object$coefficients, sd, object$map, eff)
  B <- if (any(ok)) do.call(rbind, lapply(res[ok], `[[`, "coef"))
       else matrix(NA_real_, 0, length(est), dimnames = list(NULL, names(est)))
  reasons <- table(vapply(res[!ok], function(x) x$reason %||% "unknown",
                          character(1)))
  if (sum(ok) < 2L) {
    se_abort("fewer than 2 bootstrap replicates succeeded", "bootstrap")
  }
  if (mean(!ok) > 0.1) {
    se_warn(sprintf("%d of %d bootstrap replicates failed (%s)", sum(!ok), R,
                    paste(names(reasons), reasons, sep = ": ", collapse = "; ")),
            "bootstrap")
  }
  se <- apply(B, 2, stats::sd)
  a <- (1 - level) / 2
  z <- stats::qnorm(1 - a)
  perc <- t(apply(B, 2, stats::quantile, probs = c(a, 1 - a), names = FALSE))
  pct <- paste(format(100 * c(a, 1 - a), trim = TRUE, digits = 3), "%")
  dimnames(perc) <- list(names(est), pct)
  norm <- cbind(est - z * se, est + z * se)
  dimnames(norm) <- list(names(est), pct)
  structure(list(
    replicates = B, estimate = est, bias = colMeans(B) - est, se = se,
    vcov = stats::cov(B), ci_percentile = perc, ci_normal = norm,
    level = level, R = R, successful = sum(ok),
    failures = list(n = sum(!ok), reasons = reasons),
    type = type, clustered = !is.null(cl_ids),
    n_clusters = if (!is.null(cl_ids)) max(cl_ids), method = object$method,
    statistics = statistics, seed = seed, cores = as.integer(cores),
    time = elapsed), class = "switch_bootstrap")
}

## Worker function: defined at top level so that it is sent to parallel
## workers by namespace reference.
se_boot_worker <- function(sd_r, obj, dat, ty, ids, stat = "coef", eff = NULL) {
  se_boot_one(obj, dat, ty, ids, sd_r, stat, eff)
}

## Effects on a (bootstrap) sample; groups and subset looked up by original
## row index.
se_boot_stat <- function(coef, sd, map, eff) {
  g <- if (!is.null(eff$by)) eff$by[sd$index]
  s <- if (!is.null(eff$subset)) {
    v <- eff$subset[sd$index]
    !is.na(v) & v
  }
  if (!is.null(g)) g <- factor(g, levels = levels(eff$by))
  se_eff_values(coef, sd, map, groups = g, set = s)
}

## One bootstrap replicate (also run on parallel workers).
se_boot_one <- function(object, sd, type, cl_ids, seed, stat = "coef",
                        eff = NULL) {
  assign(".Random.seed", seed, envir = globalenv())
  sdb <- tryCatch(
    if (type == "nonparametric") se_resample_data(sd, cl_ids)
    else se_simulate_data(object, sd),
    error = function(e) e)
  if (inherits(sdb, "error")) {
    return(list(ok = FALSE, reason = se_reason(sdb)))
  }
  fit <- tryCatch(se_refit(object, sdb), error = function(e) e)
  if (inherits(fit, "error")) return(list(ok = FALSE, reason = se_reason(fit)))
  if (fit$code != 0L) return(list(ok = FALSE, reason = "not converged"))
  if (stat == "effects") {
    v <- tryCatch(se_boot_stat(fit$coef, sdb, object$map, eff),
                  error = function(e) e)
    if (inherits(v, "error")) return(list(ok = FALSE, reason = se_reason(v)))
    return(list(ok = TRUE, coef = v))
  }
  list(ok = TRUE, coef = fit$coef)
}

se_reason <- function(e) {
  cls <- grep("^switch_error_", class(e), value = TRUE)
  if (length(cls)) sub("^switch_error_", "", cls[1L]) else "error"
}

## Resample observations (or clusters) from a switch_data object.
se_resample_data <- function(sd, cl_ids = NULL) {
  idx <- if (is.null(cl_ids)) {
    sample.int(sd$n, sd$n, replace = TRUE)
  } else {
    rows <- split(seq_len(sd$n), cl_ids)
    unlist(rows[sample.int(length(rows), length(rows), replace = TRUE)],
           use.names = FALSE)
  }
  se_subset_data(sd, idx)
}

se_subset_data <- function(sd, idx) {
  out <- sd
  out$S <- sd$S[idx]
  out$y <- sd$y[idx]
  out$Z <- sd$Z[idx, , drop = FALSE]
  out$X <- lapply(sd$X, function(X) X[idx, , drop = FALSE])
  out$weights <- if (!is.null(sd$weights)) sd$weights[idx]
  out$cluster <- NULL
  out$n_clusters <- NULL
  out$n <- length(idx)
  out$index <- sd$index[idx]
  se_check_sample(out)
}

## Redraw regimes and outcomes from the fitted model (covariates fixed).
se_simulate_data <- function(object, sd) {
  th <- object$coefficients
  map <- object$map
  w <- drop(sd$Z %*% th[map$index$gamma])
  u <- stats::rnorm(sd$n)
  S <- as.integer(w + u > 0)
  y <- numeric(sd$n)
  for (r in 1:2) {
    lab <- sd$regimes[r]
    sel <- S == (r - 1L)
    sig <- th[[map$index$sigma[[lab]]]]
    rho <- th[[map$index$rho[[lab]]]]
    mu <- drop(sd$X[[lab]][sel, , drop = FALSE] %*% th[map$index$beta[[lab]]])
    y[sel] <- mu + sig * (rho * u[sel] + sqrt(1 - rho^2) * stats::rnorm(sum(sel)))
  }
  out <- sd
  out$S <- S
  out$y <- y
  out$cluster <- NULL
  out$n_clusters <- NULL
  se_check_sample(out)
}

## Regime sizes and within-regime rank of a (resampled) data object.
se_check_sample <- function(sd) {
  sd$n_regime <- stats::setNames(c(sum(sd$S == 0L), sum(sd$S == 1L)),
                                 sd$regimes)
  if (any(sd$n_regime == 0L)) se_abort("a regime is empty", "data")
  se_check_rank(sd$Z, "selection equation")
  for (r in 1:2) {
    Xr <- sd$X[[r]][sd$S == r - 1L, , drop = FALSE]
    if (nrow(Xr) <= ncol(Xr)) se_abort("too few observations in a regime", "data")
    se_check_rank(Xr, "outcome equation")
  }
  sd
}

## Refit with the original method; returns list(coef, code).
se_refit <- function(object, sd) {
  map <- object$map
  if (object$method == "two_step") {
    ts <- est_two_step(sd, map, "model")
    return(list(coef = ts$coefficients,
                code = if (isTRUE(ts$probit$converged)) 0L else 1L))
  }
  ctl <- object$record$control
  ctl$starts <- 1L
  est <- est_fiml(sd, map, list(list(theta = object$coef_working,
                                     origin = "original")),
                  rep(NA_real_, map$p), ctl, "hessian")
  if (est$convergence$code != 0L) {
    ts <- tryCatch(est_two_step(sd, map, "model"), error = function(e) NULL)
    if (!is.null(ts)) {
      est2 <- est_fiml(sd, map, list(list(theta = est_two_step_start(ts, map),
                                          origin = "two_step")),
                       rep(NA_real_, map$p), ctl, "hessian")
      if (est2$convergence$code == 0L) est <- est2
    }
  }
  list(coef = est$coefficients, code = est$convergence$code)
}

#' @rdname switch_bootstrap
#' @export
print.switch_bootstrap <- function(x, digits = 4L, ...) {
  cat(sprintf("Bootstrap of a %s fit: %s, %d replicates (%d successful%s), %s\n",
              if (x$method == "fiml") "FIML" else "two-step", x$type, x$R,
              x$successful,
              if (x$failures$n) sprintf(", %d failed", x$failures$n) else "",
              if (x$clustered) sprintf("resampling %d clusters", x$n_clusters)
              else "resampling observations"))
  tab <- cbind(Estimate = x$estimate, `Boot. SE` = x$se, Bias = x$bias,
               x$ci_percentile)
  print(signif(tab, digits))
  cat(sprintf("Percentile intervals at level %g; seed %s; %.1f s.\n", x$level,
              format(x$seed), x$time))
  invisible(x)
}

#' @rdname switch_bootstrap
#' @export
vcov.switch_bootstrap <- function(object, ...) object$vcov

#' @rdname switch_bootstrap
#' @export
confint.switch_bootstrap <- function(object, parm, level = NULL,
                                     type = c("percentile", "normal"), ...) {
  type <- match.arg(type)
  if (!is.null(level) && !isTRUE(all.equal(level, object$level))) {
    se_abort(sprintf("intervals were computed at level %g; rerun switch_bootstrap(level = )",
                     object$level), "argument")
  }
  ci <- if (type == "percentile") object$ci_percentile else object$ci_normal
  if (missing(parm)) ci else ci[parm, , drop = FALSE]
}
