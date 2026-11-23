## Post-estimation for the observation mechanisms of Generation 2 (Heckman
## and treatment): designs for new data, Heckman predictions, identification
## checks, simulation and the pieces used by the bootstrap.
## OBSERVATION_MECHANISMS.md s.2.6, s.3.5 and s.6.
## A treatment fit uses the G1 code through se_esr_view().

## Design matrices for new data. Returns Z, X in the shape of the model's
## data object, D (treatment), ok and n.
se_newdata_design_obs <- function(object, newdata) {
  if (!is.data.frame(newdata)) se_abort("'newdata' must be a data frame", "data")
  mk <- function(tt, xlev, contr, what) {
    mf <- tryCatch(stats::model.frame(tt, newdata, na.action = stats::na.pass,
                                      xlev = xlev),
                   error = function(e) se_abort(sprintf(
                     "cannot evaluate the %s variables in 'newdata': %s", what,
                     conditionMessage(e)), "data"))
    list(mf = mf, ok = stats::complete.cases(mf), contr = contr, tt = tt)
  }
  parts <- list(
    selection = mk(object$terms$selection, object$xlevels$selection,
                   object$contrasts$selection, "selection"),
    outcome = mk(object$terms$outcomes$outcome, object$xlevels$outcome,
                 object$contrasts$outcome, "outcome"))
  if (!is.null(object$terms$shift)) {
    parts$shift <- mk(object$terms$shift, object$xlevels$shift,
                      object$contrasts$shift, "shift")
  }
  ok <- Reduce(`&`, lapply(parts, `[[`, "ok"))
  mm <- function(p) {
    if (!any(ok)) return(NULL)
    m <- stats::model.matrix(p$tt, p$mf[ok, , drop = FALSE],
                             contrasts.arg = p$contr)
    dimnames(m) <- list(NULL, colnames(m))
    m
  }
  Z <- mm(parts$selection)
  X <- mm(parts$outcome)
  out <- list(Z = Z, ok = ok, n = nrow(newdata))
  if (is.null(parts$shift)) {
    out$X <- list(outcome = X)
  } else {
    D <- mm(parts$shift)
    out$D <- D
    out$X <- if (is.null(X)) list(NULL, NULL) else stats::setNames(
      list(X, cbind(X, D[, !colnames(D) %in% colnames(X), drop = FALSE])),
      object$regimes)
  }
  out
}

## psi = (gamma, beta, theta) of a Heckman fit and its covariance.
se_psi_heckman <- function(object) {
  map <- object$map
  th <- object$coefficients
  ig <- map$index$gamma; ib <- map$index$beta$outcome
  is <- map$index$sigma$outcome; ir <- map$index$rho$outcome
  psi <- unname(c(th[ig], th[ib], th[[is]] * th[[ir]]))
  V <- if (object$method == "two_step") unname(object$two_step$vcov_psi) else {
    J <- matrix(0, length(psi), map$p)
    J[cbind(seq_along(ig), ig)] <- 1
    J[cbind(length(ig) + seq_along(ib), ib)] <- 1
    J[length(psi), is] <- th[[ir]]
    J[length(psi), ir] <- th[[is]]
    J %*% object$vcov %*% t(J)
  }
  list(psi = psi, V = V, gamma = seq_along(ig),
       beta = length(ig) + seq_along(ib), theta = length(psi))
}

## Predictions of a Heckman fit (OBSERVATION_MECHANISMS.md s.2.6).
se_predict_heckman <- function(object, newdata, type, se) {
  if (is.null(newdata)) {
    sd <- object$data
    if (is.null(sd)) {
      se_abort("no 'newdata' and the fit holds no data; refit with keep_data = TRUE",
               "argument")
    }
    Z <- sd$Z; X <- sd$X$outcome; n <- sd$n
    ok <- stats::complete.cases(X)
    Z <- Z[ok, , drop = FALSE]; X <- X[ok, , drop = FALSE]
    S <- sd$S[ok]
  } else {
    des <- se_newdata_design_obs(object, newdata)
    Z <- des$Z; X <- des$X$outcome; ok <- des$ok; n <- des$n
    S <- if (type == "observed") se_newdata_regime(object, newdata)[ok]
    if (type == "observed" && anyNA(S)) {
      se_abort("the selection indicator in 'newdata' has missing or invalid values",
               "data")
    }
  }
  if (!any(ok)) se_abort("no complete rows in 'newdata'", "data")
  ps <- se_psi_heckman(object)
  w <- drop(Z %*% ps$psi[ps$gamma])
  xb <- drop(X %*% ps$psi[ps$beta])
  th <- ps$psi[[ps$theta]]
  m1 <- se_m1(w); m0 <- se_m0(w)
  cond <- cbind(EY_S1 = xb + th * m1, EY_S0 = xb + th * m0)
  val <- switch(type,
    probability = stats::pnorm(w),
    selection_index = w,
    linear = xb, unconditional = xb,
    conditional = cond,
    observed = ifelse(S == 1L, cond[, "EY_S1"], NA_real_))
  sev <- NULL
  if (se) {
    V <- ps$V
    if (anyNA(V)) se_abort("the covariance matrix contains NA", "argument")
    P <- length(ps$psi)
    sefun <- function(G) sqrt(pmax(rowSums((G %*% V) * G), 0))
    gc <- function(m, d) {
      G <- matrix(0, length(w), P)
      G[, ps$gamma] <- (-th * d) * Z
      G[, ps$beta] <- X
      G[, ps$theta] <- m
      G
    }
    G0 <- matrix(0, length(w), P)
    sev <- switch(type,
      probability = { G0[, ps$gamma] <- stats::dnorm(w) * Z; sefun(G0) },
      selection_index = { G0[, ps$gamma] <- Z; sefun(G0) },
      linear = , unconditional = { G0[, ps$beta] <- X; sefun(G0) },
      conditional = cbind(EY_S1 = sefun(gc(m1, se_d1(w))),
                          EY_S0 = sefun(gc(m0, se_d0(w)))),
      observed = ifelse(S == 1L, sefun(gc(m1, se_d1(w))), NA_real_))
  }
  expand <- function(v) {
    if (all(ok)) return(v)
    if (is.matrix(v)) {
      out <- matrix(NA_real_, n, ncol(v), dimnames = list(NULL, colnames(v)))
      out[ok, ] <- v
    } else {
      out <- rep(NA_real_, n)
      out[ok] <- v
    }
    out
  }
  val <- expand(val)
  if (se) list(fit = val, se.fit = expand(sev)) else val
}

se_residuals_heckman <- function(object, type) {
  sd <- object$data
  r <- sd$y - se_predict_heckman(object, NULL, "observed", FALSE)
  if (type == "response") return(r)
  th <- object$coefficients
  map <- object$map
  w <- drop(sd$Z %*% th[map$index$gamma])
  v <- th[[map$index$sigma$outcome]]^2 *
    (1 - th[[map$index$rho$outcome]]^2 * se_d1(w))
  r / ifelse(v > 0, sqrt(v), NA_real_)
}

## Refusals shared by the post-estimation functions.
se_refuse_heckman <- function(what) {
  se_abort(sprintf(paste0(
    "%s are not defined for a Heckman sample-selection fit: the model has ",
    "one potential outcome. Use switch_predict() for the expected latent ",
    "outcome of the observed and unobserved groups (type = \"conditional\")."),
    what), "unsupported")
}

## ---------------------------------------------------------------------------
## Identification checks (IDENTIFICATION.md s.4 and s.8;
## OBSERVATION_MECHANISMS.md s.6)
## ---------------------------------------------------------------------------
se_validate_obs <- function(spec, sd, fit = NULL) {
  rows <- list()
  add <- function(code, check, status, value = "", message = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      code = code, check = check, status = status, value = as.character(value),
      message = message, stringsAsFactors = FALSE)
  }
  heck <- sd$model == "heckman"
  n <- sd$n
  one <- sd$S == 1L
  if (heck) {
    rows_o <- one
    Xo <- sd$X$outcome[one, , drop = FALSE]
  } else {
    rows_o <- rep(TRUE, n)
    Xo <- cbind(sd$X[[1L]], sd$S * sd$D)
    colnames(Xo) <- c(colnames(sd$X[[1L]]), paste0("shift:", colnames(sd$D)))
  }
  rank_row <- function(X, what) {
    q <- qr(X, tol = 1e-7)
    if (q$rank < ncol(X)) {
      add("I1", what, "error", sprintf("rank %d of %d", q$rank, ncol(X)),
          paste("aliased:", paste(colnames(X)[q$pivot[(q$rank + 1L):ncol(X)]],
                                  collapse = ", ")))
      FALSE
    } else {
      add("I1", what, "ok", sprintf("rank %d of %d", q$rank, ncol(X)))
      TRUE
    }
  }
  rank_ok <- rank_row(sd$Z, "rank of the selection design")
  rank_ok <- rank_row(Xo, if (heck)
    "rank of the outcome design among the observed units"
    else "rank of the outcome design with the shift terms") && rank_ok

  for (r in 1:2) {
    nj <- sum(sd$S == r - 1L)
    kj <- if (heck) (if (r == 2L) ncol(Xo) else 0L) else ncol(sd$D)
    st <- if (nj <= kj + 2L) "error" else if (nj / n < 0.02) "warning" else "ok"
    add("I2", sprintf("size of group '%s'", sd$regimes[r]), st,
        sprintf("n = %d (%.1f%%)", nj, 100 * nj / n),
        switch(st, error = "too few observations",
               warning = "group share below 2%", ""))
  }

  pr <- NULL
  if (!is.null(fit$two_step)) {
    pr <- list(gamma = fit$two_step$probit$gamma, Vg = fit$two_step$Vg,
               w = fit$two_step$w, separation = fit$two_step$probit$separation,
               converged = fit$two_step$probit$converged)
  } else if (rank_ok && length(unique(sd$S)) == 2L) {
    pr <- tryCatch({
      p <- est_probit(sd$Z, sd$S, sd$weights)
      p$Vg <- solve(p$info)
      p
    }, error = function(e) NULL)
  }
  if (is.null(pr)) {
    add("I3", "separation in the selection equation", "skipped", "",
        "probit not estimable")
  } else {
    st <- if (isTRUE(pr$separation) || !isTRUE(pr$converged)) "warning" else "ok"
    add("I3", "separation in the selection equation", st,
        sprintf("fitted probabilities in [%.2g, %.2g]",
                min(stats::pnorm(pr$w)), max(stats::pnorm(pr$w))),
        if (st == "warning") "fitted probabilities numerically 0 or 1, or the probit did not converge" else "")
  }

  ex <- sd$exclusions$outcome
  if (!length(ex)) {
    add("I4", "variables excluded from the outcome equation", "warning", "none",
        paste0(
          "Identification of rho", if (!heck) " and of the shift" else "",
          " depends entirely on the nonlinear functional form of the normal ",
          "distribution: no variable in the selection equation is excluded ",
          "from the outcome equation."))
    add("I5", "strength of the exclusions", "skipped", "",
        "no excluded variables")
  } else {
    add("I4", "variables excluded from the outcome equation", "ok",
        paste(ex, collapse = ", "))
    if (is.null(pr)) {
      add("I5", "strength of the exclusions", "skipped", "",
          "probit not estimable")
    } else {
      E <- match(ex, colnames(sd$Z))
      g <- pr$gamma[E]
      V <- pr$Vg[E, E, drop = FALSE]
      chi2 <- tryCatch(drop(t(g) %*% solve(V, g)), error = function(e) NA_real_)
      df <- length(E)
      p <- stats::pchisq(chi2, df, lower.tail = FALSE)
      ratio <- chi2 / df
      st <- if (!is.finite(chi2) || p > 0.05) "warning"
            else if (ratio < 10) "note" else "ok"
      add("I5", "strength of the exclusions", st,
          sprintf("chi2(%d) = %.2f, p = %.3g, chi2/df = %.1f", df, chi2, p,
                  ratio),
          switch(st,
                 warning = "excluded variables not jointly significant in the selection equation: weak or irrelevant exclusion restriction",
                 note = "significant but weak by the heuristic chi2/df < 10",
                 ""))
    }
  }

  if (!is.null(pr)) {
    ## R2 of the correction term on the outcome regressors within a group,
    ## as in the switching model. For the treatment model the generalised
    ## residual h changes sign with S, so its R2 on (x, S d) over all units
    ## is high by construction and says nothing about identification: the
    ## larger of the two within-group values is reported instead.
    r2_in <- function(rows, m) {
      Xg <- if (heck) Xo else sd$X[[1L]][rows, , drop = FALSE]
      f <- stats::lm.fit(Xg, m)
      1 - sum(f$residuals^2) / sum((m - mean(m))^2)
    }
    w <- pr$w[rows_o]
    m <- if (heck) se_m1(w) else ifelse(one, se_m1(w), se_m0(w))
    r2 <- if (heck) r2_in(one, m)
          else max(r2_in(one, se_m1(pr$w[one])), r2_in(!one, se_m0(pr$w[!one])))
    kap <- kappa(cbind(Xo, m), exact = FALSE)
    st <- if (r2 > 0.80) "warning" else "ok"
    add("I6", "collinearity of the correction term", st,
        sprintf("%sR2 = %.3f, condition number %.3g",
                if (heck) "" else "largest within-group ", r2, kap),
        if (st == "warning") paste(
          "selection-correction term highly collinear with the outcome",
          "regressors (R2 > 0.80): rho is weakly identified and its",
          "estimate may be biased") else "")
    add("I7", "range of the selection index", "note",
        sprintf("sd(z'gamma) = %.2f; %.1f%% with |z'gamma| > 3",
                stats::sd(pr$w), 100 * mean(abs(pr$w) > 3)),
        "a narrow index range weakens identification by functional form")
  }

  if (is.null(fit)) {
    add("I8", "boundary and conditioning", "skipped", "", "model not fitted")
    add("I9", "multistart agreement", "skipped", "", "model not fitted")
  } else {
    fl <- fit$diagnostics$flags
    bad <- c(if (length(fl$rho_boundary)) "rho at the boundary",
             if (length(fl$sigma_boundary)) "degenerate sigma",
             if (isTRUE(fl$ill_conditioned)) "ill-conditioned Hessian",
             if (isTRUE(fl$hessian_not_nd)) "Hessian not negative definite")
    add("I8", "boundary and conditioning", if (length(bad)) "warning" else "ok",
        if (length(bad)) paste(bad, collapse = "; ") else
          if (fit$method == "fiml") sprintf("condition number %.3g",
                                            fit$diagnostics$hessian_condition)
          else "two-step")
    if (fit$method == "fiml") {
      st <- if (isTRUE(fit$diagnostics$multistart_flat)) "warning"
            else if (isTRUE(fit$diagnostics$local_maxima > 0)) "note" else "ok"
      add("I9", "multistart agreement", st,
          sprintf("%d starts, %d converged, %d local maxima", nrow(fit$starts),
                  sum(fit$starts$code == 0L), fit$diagnostics$local_maxima),
          switch(st, warning = "different parameters reach the same maximum: flat likelihood",
                 note = "lower local maxima exist; the best was retained", ""))
    } else {
      add("I9", "multistart agreement", "skipped", "", "two-step fit")
    }
  }
  add("I10", "falsification test of exclusions", "skipped", "",
      "defined for the switching model only")
  add("I11", "parameters not identified", "note", "none",
      "the model has one outcome disturbance; every parameter enters the likelihood")

  tab <- do.call(rbind, rows)
  i5 <- tab$status[tab$code == "I5"]
  rho_id <- if (!length(ex)) "normality (functional form) only"
            else if (identical(i5, "warning"))
              "weak exclusion restriction and normality"
            else "exclusion restriction (given normality)"
  cls <- data.frame(
    parameters = c("selection coefficients", "outcome coefficients and sigma",
                   if (heck) "rho" else "shift coefficients and rho"),
    identified_by = c("probit with Var(u) = 1 (structural)",
                      if (heck) "observed units given rank and rho"
                      else "all units given rank and rho", rho_id),
    stringsAsFactors = FALSE)
  structure(list(table = tab, classification = cls, fitted = !is.null(fit),
                 n = n, regimes = sd$regimes), class = "switch_validation")
}

## ---------------------------------------------------------------------------
## Simulation and bootstrap pieces
## ---------------------------------------------------------------------------
## Redraw the selection indicator and the outcome from the fitted model.
se_simulate_data_obs <- function(object, sd) {
  th <- object$coefficients
  map <- object$map
  w <- drop(sd$Z %*% th[map$index$gamma])
  sig <- th[[map$index$sigma$outcome]]
  rho <- th[[map$index$rho$outcome]]
  u <- stats::rnorm(sd$n)
  S <- as.integer(w + u > 0)
  eps <- sig * (rho * u + sqrt(1 - rho^2) * stats::rnorm(sd$n))
  out <- sd
  out$S <- S
  if (sd$model == "heckman") {
    if (anyNA(sd$X$outcome)) {
      se_abort(paste0("parametric bootstrap impossible: outcome regressors ",
                      "are missing for some unobserved units"), "data")
    }
    y <- drop(sd$X$outcome %*% th[map$index$beta$outcome]) + eps
    y[S == 0L] <- NA_real_
  } else {
    y <- drop(sd$X[[1L]] %*% th[map$index$beta$outcome]) +
      S * drop(sd$D %*% th[map$index$delta]) + eps
  }
  out$y <- y
  out$cluster <- NULL
  out$n_clusters <- NULL
  se_check_sample_obs(out)
}

se_check_sample_obs <- function(sd) {
  sd$n_regime <- stats::setNames(c(sum(sd$S == 0L), sum(sd$S == 1L)),
                                 sd$regimes)
  if (any(sd$n_regime == 0L)) se_abort("a group is empty", "data")
  se_check_rank(sd$Z, "selection equation")
  if (sd$model == "heckman") {
    Xr <- sd$X$outcome[sd$S == 1L, , drop = FALSE]
    if (anyNA(Xr) || anyNA(sd$y[sd$S == 1L])) {
      se_abort("missing outcome data among the observed units", "data")
    }
  } else {
    Xr <- cbind(sd$X[[1L]], sd$S * sd$D)
  }
  if (nrow(Xr) <= ncol(Xr)) se_abort("too few observations", "data")
  se_check_rank(Xr, "outcome equation")
  sd
}

## switch_simulate() for heckman and treatment.
se_simulate_obs <- function(model, data, parameters, nsim, seed,
                            potential_outcomes) {
  if (inherits(model, "switch_fit")) {
    spec <- model$spec
    des <- se_newdata_design_obs(model, data)
    parameters <- parameters %||% model$coefficients
    rvals <- model$regime_values
  } else {
    spec <- model
    if (is.null(parameters)) {
      se_abort("'parameters' is required when 'model' is a switch_spec",
               "argument")
    }
    tt <- function(f) stats::delete.response(stats::terms(f))
    pseudo <- list(
      terms = list(selection = tt(spec$selection$formula),
                   outcomes = list(outcome = tt(spec$outcomes$outcome$formula)),
                   shift = if (!is.null(spec$shift)) stats::terms(spec$shift)),
      xlevels = list(), contrasts = list(), regimes = spec$regimes)
    des <- se_newdata_design_obs(pseudo, data)
    rvals <- NULL
  }
  if (!any(des$ok)) se_abort("no complete rows in 'data'", "data")
  if (!is.numeric(nsim) || length(nsim) != 1L || nsim < 1) {
    se_abort("'nsim' must be a positive whole number", "argument")
  }
  sel_lhs <- spec$selection$formula[[2L]]
  out_lhs <- spec$outcomes$outcome$formula[[2L]]
  if (!is.name(sel_lhs) || !is.name(out_lhs)) {
    se_abort("simulation needs plain variable names as responses", "argument")
  }
  sel_var <- as.character(sel_lhs)
  yv <- as.character(out_lhs)
  heck <- spec$model == "heckman"
  pd <- list(model = spec$model, Z = des$Z, X = des$X, D = des$D,
             regimes = spec$regimes,
             d_in = if (!heck) match(colnames(des$D), colnames(des$X[[1L]])))
  map <- se_parmap_obs(pd)
  th <- se_par_natural(map, se_par_working(map, parameters))
  sig <- th[[map$index$sigma$outcome]]
  rho <- th[[map$index$rho$outcome]]
  if (abs(rho) >= 1) se_abort("rho must lie in (-1, 1)", "domain")
  w <- drop(des$Z %*% th[map$index$gamma])
  xb <- drop(des$X[[1L]] %*% th[map$index$beta$outcome])
  dd <- if (heck) 0 else drop(des$D %*% th[map$index$delta])
  ok <- des$ok
  fill <- function(v) { out <- rep(NA, length(ok)); out[ok] <- v; out }
  one <- function() {
    m <- length(w)
    u <- stats::rnorm(m)
    eps <- sig * (rho * u + sqrt(1 - rho^2) * stats::rnorm(m))
    S <- as.integer(w + u > 0)
    out <- data
    sv <- fill(S)
    out[[sel_var]] <- if (!is.null(rvals) && !identical(rvals, c("0", "1"))) {
      if (identical(rvals, c("FALSE", "TRUE"))) as.logical(sv)
      else factor(rvals[sv + 1L], levels = rvals)
    } else sv
    if (heck) {
      out[[yv]] <- fill(ifelse(S == 1L, xb + eps, NA_real_))
      if (potential_outcomes) out[[".latent"]] <- fill(xb + eps)
    } else {
      out[[yv]] <- fill(xb + S * dd + eps)
      if (potential_outcomes) {
        out[[paste0(".potential_", spec$regimes[1L])]] <- fill(xb + eps)
        out[[paste0(".potential_", spec$regimes[2L])]] <- fill(xb + dd + eps)
      }
    }
    out
  }
  sims <- se_with_seed(seed, lapply(seq_len(nsim), function(k) one()))
  if (nsim == 1L) sims[[1L]] else sims
}

## simulate() method for heckman and treatment fits.
se_simulate_fit_obs <- function(object, nsim, seed) {
  sd <- object$data
  rho <- object$coefficients[[object$map$index$rho$outcome]]
  if (abs(rho) >= 1) {
    se_abort("cannot simulate: the estimated rho lies outside (-1, 1)",
             "domain")
  }
  draws <- se_with_seed(seed, lapply(seq_len(nsim), function(k) {
    d <- se_simulate_data_obs_raw(object, sd)
    stats::setNames(data.frame(d$S, d$y), paste0(c("S_", "y_"), k))
  }))
  out <- do.call(cbind, draws)
  attr(out, "seed") <- seed
  out
}

## As se_simulate_data_obs() without the sample checks.
se_simulate_data_obs_raw <- function(object, sd) {
  th <- object$coefficients
  map <- object$map
  w <- drop(sd$Z %*% th[map$index$gamma])
  sig <- th[[map$index$sigma$outcome]]
  rho <- th[[map$index$rho$outcome]]
  u <- stats::rnorm(sd$n)
  S <- as.integer(w + u > 0)
  eps <- sig * (rho * u + sqrt(1 - rho^2) * stats::rnorm(sd$n))
  y <- if (sd$model == "heckman") {
    ifelse(S == 1L, drop(sd$X$outcome %*% th[map$index$beta$outcome]) + eps,
           NA_real_)
  } else {
    drop(sd$X[[1L]] %*% th[map$index$beta$outcome]) +
      S * drop(sd$D %*% th[map$index$delta]) + eps
  }
  list(S = S, y = y)
}
