## Layer 7 for multinomial regime selection: J x J conditional expectations,
## pairwise effects, predictions and simulation (TREATMENT_EFFECTS.md
## s.7-11; MULTINOMIAL_ESR.md s.3.5 and s.4.4). Any number of regimes.
##
## All quantities depend on the parameters through
##   psi = (gamma, and per regime: beta_j, dependence coefficients),
## where the dependence coefficients are theta_j = sigma_j rho_j (Lee) or
## the coefficients of the correction terms (Dubin-McFadden, BFG). Standard
## errors use the delta method with a numerical Jacobian of the effects
## with respect to psi (central differences; gate decision 9).

## Layout of psi for a fit.
se_multi_layout <- function(object) {
  map <- object$map
  labs <- object$regimes
  J <- length(labs)
  ng <- length(map$index$gamma)
  type <- if (identical(map$kind, "moments")) object$two_step$correction
          else if (identical(map$kind, "ns")) "bfg2" else "lee"
  kx <- vapply(labs, function(l) length(map$index$beta[[l]]), integer(1))
  nt <- if (type == "lee") rep(1L, J)
        else if (identical(map$kind, "ns")) rep(J, J)
        else vapply(labs, function(l) length(map$index$theta[[l]]), integer(1))
  off <- ng + c(0L, cumsum(kx + nt)[-J])
  list(J = J, labs = labs, kz = map$kz, ng = ng, type = type, kx = kx, nt = nt,
       beta = lapply(seq_len(J), function(j) off[j] + seq_len(kx[j])),
       dep = lapply(seq_len(J), function(j) off[j] + kx[j] + seq_len(nt[j])),
       P = ng + sum(kx + nt),
       base = object$base_index %||% object$data$base)
}

## psi and its covariance.
se_multi_psi <- function(object) {
  lay <- se_multi_layout(object)
  map <- object$map
  if (object$method == "two_step" && !identical(map$kind, "ns")) {
    return(list(psi = unname(object$two_step$psi),
                V = unname(object$two_step$vcov_psi), layout = lay))
  }
  th <- object$coefficients
  Jm <- matrix(0, lay$P, map$p)
  psi <- numeric(lay$P)
  ig <- map$index$gamma
  psi[seq_len(lay$ng)] <- th[ig]
  Jm[cbind(seq_len(lay$ng), ig)] <- 1
  for (j in seq_len(lay$J)) {
    l <- lay$labs[j]
    ib <- map$index$beta[[l]]
    psi[lay$beta[[j]]] <- th[ib]
    Jm[cbind(lay$beta[[j]], ib)] <- 1
    is <- map$index$sigma[[l]]; ir <- map$index$rho[[l]]
    ## theta_j = sigma_j rho_j (Lee) or a_jk = sigma_j r_jk (normal scores)
    psi[lay$dep[[j]]] <- th[[is]] * th[ir]
    Jm[lay$dep[[j]], is] <- th[ir]
    Jm[cbind(lay$dep[[j]], ir)] <- th[[is]]
  }
  list(psi = psi, V = Jm %*% object$vcov %*% t(Jm), layout = lay)
}

## Probabilities, linear predictors and the array of conditional
## disturbance means cm[i, j, k] = E[eps_j | S = k] for the rows of (Z, X).
se_multi_means <- function(psi, lay, Z, X) {
  J <- lay$J; n <- nrow(Z)
  G <- matrix(psi[seq_len(lay$ng)], J - 1L, lay$kz, byrow = TRUE)
  P <- exp(se_mnl_logP(Z, G, lay$base))
  xb <- vapply(seq_len(J), function(j) drop(X[[j]] %*% psi[lay$beta[[j]]]),
               numeric(n))
  if (!is.matrix(xb)) xb <- matrix(xb, n, J)
  cm <- array(0, c(n, J, J))
  if (lay$type == "lee") {
    w <- stats::qnorm(P)
    m1 <- se_m1(w); m0 <- se_m0(w)
    for (j in seq_len(J)) {
      th <- psi[[lay$dep[[j]]]]
      for (k in seq_len(J)) cm[, j, k] <- th * (if (k == j) m1[, j] else m0[, j])
    }
  } else {
    A <- matrix(0, J, J)                    # row j: a_j1 .. a_jJ
    for (j in seq_len(J)) {
      a <- psi[lay$dep[[j]]]
      if (lay$type == "dmf") {
        A[j, -j] <- a
        A[j, j] <- -sum(a)
      } else A[j, ] <- a
    }
    for (k in seq_len(J)) {
      B <- se_gumbel_basis(P, k, lay$type)$B
      cm[, , k] <- B %*% t(A)
    }
  }
  list(P = P, xb = xb, cm = cm)
}

## Central-difference Jacobian of a vector function.
se_num_jacobian <- function(f, x) {
  f0 <- f(x)
  Jm <- matrix(0, length(f0), length(x))
  for (i in seq_along(x)) {
    h <- 1e-5 * (1 + abs(x[i]))
    xp <- x; xp[i] <- x[i] + h
    xm <- x; xm[i] <- x[i] - h
    Jm[, i] <- (f(xp) - f(xm)) / (2 * h)
  }
  Jm
}

## The list of regime pairs (index of the regime, index of the comparison).
se_multi_pairs <- function(pairs, labs) {
  J <- length(labs)
  if (identical(pairs, "all")) {
    out <- list()
    for (k in seq_len(J - 1L)) for (j in (k + 1L):J) {
      out[[length(out) + 1L]] <- c(j, k)
    }
    return(out)
  }
  if (is.character(pairs) && length(pairs) == 2L) pairs <- list(pairs)
  if (!is.list(pairs) || !length(pairs)) {
    se_abort("'pairs' must be \"all\" or a list of pairs of regime labels",
             "argument")
  }
  lapply(pairs, function(p) {
    if (!is.character(p) || length(p) != 2L || !all(p %in% labs) ||
        p[1L] == p[2L]) {
      se_abort(sprintf(paste0("each pair must be two different regime labels ",
                              "among %s"), paste(labs, collapse = ", ")),
               "argument")
    }
    match(p, labs)
  })
}

## Effect values for a set of units. Returns a named vector; the names
## encode effect, regime, comparison and conditioning regime.
se_multi_effect_values <- function(psi, lay, Z, X, S, om, set, pairs, effects,
                                   given = NULL) {
  mm <- se_multi_means(psi, lay, Z, X)
  wm <- function(v, s) sum(om[s] * v[s]) / sum(om[s])
  out <- numeric(0)
  for (pr in pairs) {
    j <- pr[1L]; k <- pr[2L]
    sj <- set & S == j; sk <- set & S == k
    att <- if (any(sj)) wm((mm$xb[, j] + mm$cm[, j, j]) -
                             (mm$xb[, k] + mm$cm[, k, j]), sj) else NA_real_
    atu <- if (any(sk)) wm((mm$xb[, j] + mm$cm[, j, k]) -
                             (mm$xb[, k] + mm$cm[, k, k]), sk) else NA_real_
    v <- c(ATE = wm(mm$xb[, j] - mm$xb[, k], set), ATT = att, ATU = atu,
           TH = att - atu)[effects]
    names(v) <- paste(names(v), j, k, NA, sep = "|")
    out <- c(out, v)
    for (l in given) {
      sl <- set & S == l
      te <- if (any(sl)) wm((mm$xb[, j] + mm$cm[, j, l]) -
                              (mm$xb[, k] + mm$cm[, k, l]), sl) else NA_real_
      out <- c(out, stats::setNames(te, paste("TE", j, k, l, sep = "|")))
    }
  }
  out
}

## J x J table of mean E[Y_j | S = k] over the units observed in regime k
## (rows: outcome regime j; columns: observed regime k).
se_multi_mean_table <- function(psi, lay, Z, X, S, om, set) {
  mm <- se_multi_means(psi, lay, Z, X)
  J <- lay$J
  tab <- matrix(NA_real_, J, J, dimnames = list(
    paste0("outcome under ", lay$labs), paste0("units in ", lay$labs)))
  for (k in seq_len(J)) {
    s <- set & S == k
    if (!any(s)) next
    for (j in seq_len(J)) {
      tab[j, k] <- sum(om[s] * (mm$xb[s, j] + mm$cm[s, j, k])) / sum(om[s])
    }
  }
  tab
}

## switch_effects() for multinomial fits.
se_effects_multi <- function(object, effects, se, level, by, subset, data,
                             pairs = "all", given = NULL, individual = FALSE) {
  sd <- object$data
  if (is.null(sd)) {
    se_abort("effects need the estimation data; refit with switch_control(keep_data = TRUE)",
             "argument")
  }
  if (se_responses_differ_multi(object)) {
    se_abort(paste0("effects are not defined when the outcome equations have ",
                    "different response variables"), "unsupported")
  }
  ok_eff <- c("ATT", "ATU", "ATE", "TH")
  effects <- setdiff(effects, "BH")
  if (!length(effects) || !all(effects %in% ok_eff)) {
    se_abort(sprintf("'effects' must be among %s for multinomial models",
                     paste(ok_eff, collapse = ", ")), "argument")
  }
  if (se == "bootstrap") {
    se_abort(paste0("bootstrap standard errors of multinomial effects are not ",
                    "available in this version; use se = \"delta\""),
             "unsupported")
  }
  labs <- sd$regimes
  prs <- se_multi_pairs(pairs, labs)
  gv <- NULL
  if (!is.null(given)) {
    if (!is.character(given) || !all(given %in% labs)) {
      se_abort("'given' must be regime labels", "argument")
    }
    gv <- match(given, labs)
  }
  n <- sd$n
  sel <- se_eff_resolve(subset, object, data, "subset")
  sel <- if (is.null(sel)) rep(TRUE, n) else !is.na(sel) & as.logical(sel)
  grp <- se_eff_resolve(by, object, data, "by")
  if (!is.null(grp)) grp <- droplevels(as.factor(grp))
  sets <- if (is.null(grp)) list(all = sel)
          else stats::setNames(lapply(levels(grp), function(l)
            sel & !is.na(grp) & grp == l), levels(grp))
  ps <- se_multi_psi(object)
  lay <- ps$layout
  om <- sd$weights %||% rep(1, n)
  z <- stats::qnorm(1 - (1 - level) / 2)
  if (se == "delta" && anyNA(ps$V)) {
    se_abort("the covariance matrix contains NA", "argument")
  }
  assume <- if (lay$type == "lee") "L-CI" else ""
  rows <- list(); means <- list()
  for (g in names(sets)) {
    f <- function(p) se_multi_effect_values(p, lay, sd$Z, sd$X, sd$S, om,
                                            sets[[g]], prs, effects, gv)
    est <- f(ps$psi)
    s <- rep(NA_real_, length(est))
    if (se == "delta") {
      Jm <- se_num_jacobian(f, ps$psi)
      s <- sqrt(pmax(rowSums((Jm %*% ps$V) * Jm), 0))
    }
    key <- do.call(rbind, strsplit(names(est), "|", fixed = TRUE))
    cond <- suppressWarnings(as.integer(key[, 4L]))
    rows[[g]] <- data.frame(
      effect = key[, 1L], regime = labs[as.integer(key[, 2L])],
      against = labs[as.integer(key[, 3L])],
      given = ifelse(is.na(cond), ifelse(key[, 1L] == "ATT", labs[as.integer(
        key[, 2L])], ifelse(key[, 1L] == "ATU", labs[as.integer(key[, 3L])],
                            "")), labs[cond]),
      group = g, estimate = unname(est), std_error = s,
      statistic = unname(est) / s,
      p_value = 2 * stats::pnorm(-abs(unname(est) / s)),
      lower = unname(est) - z * s, upper = unname(est) + z * s,
      assumption = ifelse(key[, 1L] == "ATE", "", assume),
      stringsAsFactors = FALSE)
    means[[g]] <- se_multi_mean_table(ps$psi, lay, sd$Z, sd$X, sd$S, om,
                                      sets[[g]])
  }
  tab <- do.call(rbind, rows)
  rownames(tab) <- NULL
  ind <- NULL
  if (individual) {
    mm <- se_multi_means(ps$psi, lay, sd$Z, sd$X)
    ind <- data.frame(index = sd$index, regime = labs[sd$S],
                      stats::setNames(as.data.frame(mm$xb),
                                      paste0("linear_", labs)))
  }
  structure(list(
    table = tab, means = means, individual = ind, se = se, level = level,
    regimes = labs, method = object$method, model = object$model,
    assumption = assume,
    definitions = c(
      ATE = "mean over all units of x_j'b_j - x_k'b_k",
      ATT = "mean over the units of 'regime' of E[Y(regime)|S=regime] - E[Y(against)|S=regime]",
      ATU = "mean over the units of 'against' of E[Y(regime)|S=against] - E[Y(against)|S=against]",
      TH = "ATT - ATU",
      TE = "mean over the units of 'given' of E[Y(regime)|S=given] - E[Y(against)|S=given]")),
    class = c("switch_effects_multi", "switch_effects"))
}

#' @export
print.switch_effects_multi <- function(x, digits = 4L, ...) {
  cat(sprintf("Pairwise effects, %d regimes (%s)\n", length(x$regimes),
              paste(x$regimes, collapse = ", ")))
  for (g in names(x$means)) {
    cat(sprintf("\nMean expected outcome by observed regime%s:\n",
                if (length(x$means) > 1L) sprintf(" [%s]", g) else ""))
    print(signif(x$means[[g]], digits))
  }
  cat("\n")
  tb <- x$table
  num <- vapply(tb, is.double, logical(1))
  tb[num] <- lapply(tb[num], signif, digits = digits)
  if (length(unique(tb$group)) == 1L) tb$group <- NULL
  print(tb, row.names = FALSE)
  cat(sprintf("\nStandard errors: %s; %g%% intervals.\n",
              if (x$se == "delta") "delta method (covariates fixed)"
              else "not computed", 100 * x$level))
  if (identical(x$assumption, "L-CI")) {
    cat("Counterfactual means (ATT, ATU, TH, TE) rely on assumption L-CI: the outcome\n",
        "disturbance of a regime depends on the utilities only through that regime's\n",
        "selection index. Under the multinomial logit they are then the same for the\n",
        "units of every other regime with the same covariates.\n", sep = "")
  }
  invisible(x)
}

se_responses_differ_multi <- function(object) {
  r <- vapply(object$spec$outcomes, function(o) se_deparse(o$formula[[2L]]),
              character(1))
  length(unique(r)) > 1L
}

## ---------------------------------------------------------------------------
## Predictions
## ---------------------------------------------------------------------------
se_newdata_design_multi <- function(object, newdata) {
  if (!is.data.frame(newdata)) se_abort("'newdata' must be a data frame", "data")
  mk <- function(tt, xlev, contr, what) {
    mf <- tryCatch(stats::model.frame(tt, newdata, na.action = stats::na.pass,
                                      xlev = xlev),
                   error = function(e) se_abort(sprintf(
                     "cannot evaluate the %s variables in 'newdata': %s", what,
                     conditionMessage(e)), "data"))
    list(mf = mf, ok = stats::complete.cases(mf), contr = contr, tt = tt)
  }
  labs <- object$regimes
  parts <- c(list(selection = mk(object$terms$selection,
                                 object$xlevels$selection,
                                 object$contrasts$selection, "selection")),
             stats::setNames(lapply(labs, function(l)
               mk(object$terms$outcomes[[l]], object$xlevels[[l]],
                  object$contrasts[[l]], sprintf("'%s' outcome", l))), labs))
  ok <- Reduce(`&`, lapply(parts, `[[`, "ok"))
  mm <- function(p) {
    if (!any(ok)) return(NULL)
    m <- stats::model.matrix(p$tt, p$mf[ok, , drop = FALSE],
                             contrasts.arg = p$contr)
    dimnames(m) <- list(NULL, colnames(m))
    m
  }
  list(Z = mm(parts$selection),
       X = stats::setNames(lapply(labs, function(l) mm(parts[[l]])), labs),
       ok = ok, n = nrow(newdata))
}

se_predict_multi <- function(object, newdata, type, se) {
  labs <- object$regimes
  J <- length(labs)
  if (is.null(newdata)) {
    sd <- object$data
    if (is.null(sd)) {
      se_abort("no 'newdata' and the fit holds no data; refit with keep_data = TRUE",
               "argument")
    }
    Z <- sd$Z; X <- sd$X; ok <- rep(TRUE, sd$n); n <- sd$n; S <- sd$S
  } else {
    des <- se_newdata_design_multi(object, newdata)
    Z <- des$Z; X <- des$X; ok <- des$ok; n <- des$n
    S <- NULL
    if (type == "observed") {
      f <- object$spec$selection$formula
      s <- tryCatch(eval(f[[2L]], newdata, environment(f)), error = function(e)
        se_abort("type = \"observed\" needs the regime variable in 'newdata'",
                 "data"))
      S <- match(as.character(s), labs)[ok]
      if (anyNA(S)) {
        se_abort("the regime variable in 'newdata' has missing or unknown values",
                 "data")
      }
    }
  }
  if (!any(ok)) se_abort("no complete rows in 'newdata'", "data")
  ps <- se_multi_psi(object)
  lay <- ps$layout
  m <- nrow(Z)
  fun <- function(p) {
    mm <- se_multi_means(p, lay, Z, X)
    switch(type,
      probability = mm$P,
      selection_index = Z %*% t(matrix(p[seq_len(lay$ng)], J - 1L, lay$kz,
                                       byrow = TRUE)),
      linear = mm$xb,
      conditional = {
        out <- matrix(0, m, J * J)
        for (j in seq_len(J)) for (k in seq_len(J)) {
          out[, (j - 1L) * J + k] <- mm$xb[, j] + mm$cm[, j, k]
        }
        out
      },
      observed = mm$xb[cbind(seq_len(m), S)] + mm$cm[cbind(seq_len(m), S, S)],
      unconditional = rowSums(vapply(seq_len(J), function(j)
        mm$P[, j] * (mm$xb[, j] + mm$cm[, j, j]), numeric(m))))
  }
  val <- fun(ps$psi)
  cn <- switch(type,
    probability = labs, linear = labs,
    selection_index = setdiff(labs, labs[lay$base]),
    conditional = as.vector(t(outer(labs, labs, function(a, b)
      sprintf("EY[%s]_S[%s]", a, b)))),
    NULL)
  shape <- function(v) if (is.null(cn)) as.vector(v) else
    matrix(v, m, length(cn), dimnames = list(NULL, cn))
  sev <- NULL
  if (se) {
    if (anyNA(ps$V)) se_abort("the covariance matrix contains NA", "argument")
    Jm <- se_num_jacobian(function(p) as.vector(fun(p)), ps$psi)
    sev <- shape(sqrt(pmax(rowSums((Jm %*% ps$V) * Jm), 0)))
  }
  val <- shape(val)
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
  if (se) list(fit = expand(val), se.fit = expand(sev)) else expand(val)
}

## ---------------------------------------------------------------------------
## Simulation from Lee's model under assumption L-CI
## ---------------------------------------------------------------------------
## One draw given the systematic utilities V (n x J, base column 0), the
## linear predictors xb (n x J), sigma and rho (length J). Returns S and the
## potential outcomes of all regimes: eps_j = sigma_j (rho_j u*_j +
## sqrt(1 - rho_j^2) nu_j), u*_j = -qnorm(F_j(eps*_j)), nu independent.
se_sim_draw_lee <- function(V, xb, sigma, rho) {
  n <- nrow(V); J <- ncol(V)
  U <- V - log(-log(matrix(stats::runif(n * J), n, J)))
  S <- integer(n); best <- rep(-Inf, n)
  for (k in seq_len(J)) {
    b <- U[, k] > best
    S[b] <- k; best[b] <- U[b, k]
  }
  Y <- matrix(0, n, J)
  for (j in seq_len(J)) {
    oth <- U[, -j, drop = FALSE]
    mo <- oth[, 1L]
    if (J > 2L) for (k in 2:(J - 1L)) mo <- pmax(mo, oth[, k])
    es <- mo - (U[, j] - V[, j])                     # eps*_j
    Vo <- V[, -j, drop = FALSE]
    mx <- pmax(es, Vo[, 1L]); if (J > 2L) for (k in 2:(J - 1L)) mx <- pmax(mx, Vo[, k])
    lse <- mx + log(exp(es - mx) + rowSums(exp(Vo - mx)))
    us <- -stats::qnorm(es - lse, log.p = TRUE)
    Y[, j] <- xb[, j] + sigma[j] * (rho[j] * us + sqrt(1 - rho[j]^2) *
                                      stats::rnorm(n))
  }
  list(S = S, Y = Y)
}

se_multi_sim_parts <- function(object, sd) {
  th <- object$coefficients
  map <- object$map
  if (identical(map$kind, "moments")) {
    se_abort(paste0("simulation needs a model with a complete distribution: ",
                    "the Dubin-McFadden and BFG corrections are moment models"),
             "unsupported")
  }
  J <- sd$J; labs <- sd$regimes
  V <- matrix(0, nrow(sd$Z), J)
  V[, -sd$base] <- sd$Z %*% t(matrix(th[map$index$gamma], J - 1L, map$kz,
                                     byrow = TRUE))
  xb <- vapply(labs, function(l) drop(sd$X[[l]] %*% th[map$index$beta[[l]]]),
               numeric(nrow(sd$Z)))
  sigma <- vapply(labs, function(l) th[[map$index$sigma[[l]]]], numeric(1))
  if (identical(map$kind, "ns")) {
    R <- t(vapply(labs, function(l) th[map$index$rho[[l]]], numeric(J)))
    if (any(rowSums(R^2) >= 1)) {
      se_abort("cannot simulate: the correlations of a regime have sum of squares >= 1",
               "domain")
    }
    return(list(V = V, xb = xb, sigma = sigma, R = R))
  }
  rho <- vapply(labs, function(l) th[[map$index$rho[[l]]]], numeric(1))
  if (any(abs(rho) >= 1)) {
    se_abort("cannot simulate: a rho lies outside (-1, 1)", "domain")
  }
  list(V = V, xb = xb, sigma = sigma, rho = rho)
}

## Redraw regimes and outcomes from the fitted model (parametric bootstrap).
se_simulate_data_multi <- function(object, sd) {
  pt <- se_multi_sim_parts(object, sd)
  dr <- se_multi_draw(pt)
  out <- sd
  out$S <- dr$S
  out$y <- dr$Y[cbind(seq_len(sd$n), dr$S)]
  out$cluster <- NULL
  out$n_clusters <- NULL
  se_check_sample_multi(out)
}

se_multi_draw <- function(pt) {
  if (!is.null(pt$R)) se_sim_draw_ns(pt$V, pt$xb, pt$sigma, pt$R)
  else se_sim_draw_lee(pt$V, pt$xb, pt$sigma, pt$rho)
}

se_check_sample_multi <- function(sd) {
  sd$n_regime <- stats::setNames(tabulate(sd$S, sd$J), sd$regimes)
  if (any(sd$n_regime == 0L)) se_abort("a regime is empty", "data")
  se_check_rank(sd$Z, "selection equation")
  for (j in seq_len(sd$J)) {
    Xr <- sd$X[[j]][sd$S == j, , drop = FALSE]
    if (nrow(Xr) <= ncol(Xr) + 1L) {
      se_abort("too few observations in a regime", "data")
    }
    se_check_rank(Xr, "outcome equation")
  }
  sd
}

## switch_simulate() for multinomial models (fit or specification).
se_simulate_multi <- function(model, data, parameters, nsim, seed,
                              potential_outcomes) {
  if (inherits(model, "switch_fit")) {
    spec <- model$spec
    des <- se_newdata_design_multi(model, data)
    labs <- model$regimes
    base <- model$base_index
    obj <- model
    if (!is.null(parameters)) {
      obj$coefficients <- se_par_natural(model$map, se_par_working(model$map,
                                                                  parameters))
    }
  } else {
    spec <- model
    labs <- spec$regimes
    if (is.null(labs)) {
      se_abort("simulation from a specification needs named outcome equations",
               "argument")
    }
    if (is.null(parameters)) {
      se_abort("'parameters' is required when 'model' is a switch_spec",
               "argument")
    }
    tt <- function(f) stats::delete.response(stats::terms(f))
    pseudo <- list(
      terms = list(selection = tt(spec$selection$formula),
                   outcomes = lapply(spec$outcomes, function(o) tt(o$formula))),
      xlevels = list(), contrasts = list(), regimes = labs)
    des <- se_newdata_design_multi(pseudo, data)
    base <- match(spec$selection$base %||% labs[1L], labs)
    pd <- list(model = spec$model, Z = des$Z, X = des$X, regimes = labs,
               J = length(labs), base = base,
               alternatives = labs[-base], correction = "lee",
               structure = spec$dependence$structure)
    map <- se_parmap_multi(pd)
    obj <- list(map = map, coefficients = se_par_natural(
      map, se_par_working(map, parameters)))
  }
  if (!any(des$ok)) se_abort("no complete rows in 'data'", "data")
  if (!is.numeric(nsim) || length(nsim) != 1L || nsim < 1) {
    se_abort("'nsim' must be a positive whole number", "argument")
  }
  sel_lhs <- spec$selection$formula[[2L]]
  out_lhs <- lapply(spec$outcomes, function(o) o$formula[[2L]])
  if (!is.name(sel_lhs) || !all(vapply(out_lhs, is.name, logical(1)))) {
    se_abort("simulation needs plain variable names as responses", "argument")
  }
  yv <- unique(vapply(out_lhs, as.character, character(1)))
  if (length(yv) != 1L) {
    se_abort("simulation needs the same response variable in every outcome equation",
             "unsupported")
  }
  sdl <- list(Z = des$Z, X = des$X, J = length(labs), regimes = labs,
              base = base)
  pt <- se_multi_sim_parts(obj, sdl)
  ok <- des$ok
  fill <- function(v) { out <- rep(NA, length(ok)); out[ok] <- v; out }
  one <- function() {
    dr <- se_multi_draw(pt)
    out <- data
    out[[as.character(sel_lhs)]] <- factor(labs[fill(dr$S)], levels = labs)
    out[[yv]] <- fill(dr$Y[cbind(seq_len(nrow(dr$Y)), dr$S)])
    if (potential_outcomes) {
      for (j in seq_along(labs)) {
        out[[paste0(".potential_", labs[j])]] <- fill(dr$Y[, j])
      }
      attr(out, "completion") <- if (is.null(pt$R))
        "L-CI with independent idiosyncratic parts"
        else "independent idiosyncratic parts"
    }
    out
  }
  sims <- se_with_seed(seed, lapply(seq_len(nsim), function(k) one()))
  if (nsim == 1L) sims[[1L]] else sims
}
