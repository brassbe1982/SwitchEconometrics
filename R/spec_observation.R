## Layers 1 and 5 for the observation mechanisms of Generation 2:
## Heckman sample selection (Tobit-2) and endogenous treatment with a shift.
## Derivation: 01_Econometric_Architecture/OBSERVATION_MECHANISMS.md;
## verified numerically by verify_math_g2.R (W01-W08) and
## verify_math_g2b.R (X01-X02).
##
## Heckman:   y* = x'beta + eps, observed only when S = 1.
## Treatment: y  = x'beta + S d'delta + eps for every unit; d are the effect
##            modifiers (`shift`). It is the binary ESR under a linear
##            restriction theta_ESR = A theta_T, so its data object has the
##            shape of an ESR data object (X_0 = X, X_1 = (X, columns of d
##            that are not in X)) and the G1 engine is called unchanged.

se_obs_models <- c("heckman", "treatment")
se_is_obs <- function(x) isTRUE(x %in% se_obs_models)

## Regime labels of the two models (S = 0 first).
se_obs_regimes <- function(model) {
  if (model == "heckman") c("not_observed", "observed")
  else c("untreated", "treated")
}

## Specification object for heckman and treatment (called by switch_model()).
se_spec_observation <- function(selection, outcomes, model, shift,
                                selection_family, outcome_family, dependence,
                                family, identification, cl) {
  if (!inherits(selection, "formula") || length(selection) != 3L) {
    se_abort("'selection' must be a two-sided formula, e.g. regime ~ z1 + z2",
             "argument")
  }
  if (is.list(outcomes) && !inherits(outcomes, "formula")) {
    if (length(outcomes) != 1L) {
      se_abort(sprintf(
        "model \"%s\" has one outcome equation; give one formula", model),
        "argument")
    }
    outcomes <- outcomes[[1L]]
  }
  if (!inherits(outcomes, "formula") || length(outcomes) != 3L) {
    se_abort("the outcome equation must be a two-sided formula", "argument")
  }
  if (model == "heckman") {
    if (!is.null(shift)) {
      se_abort("'shift' applies to model = \"treatment\" only", "argument")
    }
  } else {
    shift <- shift %||% (~ 1)
    if (!inherits(shift, "formula") || length(shift) != 2L) {
      se_abort("'shift' must be a one-sided formula, e.g. ~ 1 or ~ x1",
               "argument")
    }
    environment(shift) <- environment(outcomes)
    if (attr(stats::terms(shift), "intercept") != 1L) {
      se_abort("'shift' must contain the constant (the effect modifiers d include 1)",
               "argument")
    }
  }
  all_f <- c(list(selection, outcomes), if (!is.null(shift)) list(shift))
  if (any(vapply(all_f, function(f) "." %in% all.vars(f), logical(1)))) {
    se_abort("'.' in formulas is not supported; list the variables explicitly",
             "argument")
  }
  sel_resp <- all.vars(selection[[2L]])
  rhs_sel <- all.vars(selection[[3L]])
  rhs_out <- unique(c(all.vars(outcomes[[3L]]),
                      if (!is.null(shift)) all.vars(shift)))
  bad <- intersect(sel_resp, rhs_out)
  if (length(bad)) {
    se_abort(sprintf(paste0(
      "the regime indicator '%s' cannot be a regressor of the outcome ",
      "equation%s"), bad[1L],
      if (model == "treatment") "; its effect is specified by 'shift'" else ""),
      "argument")
  }
  if (identical(identification, "auto")) {
    ident <- list(mode = "auto", declared = NULL)
  } else if (is.character(identification) && length(identification) &&
             !anyNA(identification)) {
    miss <- setdiff(identification, rhs_sel)
    if (length(miss)) {
      se_abort(sprintf(
        "declared exclusion(s) %s do not appear in the selection equation",
        paste(miss, collapse = ", ")), "argument")
    }
    bad <- intersect(identification, rhs_out)
    if (length(bad)) {
      se_abort(sprintf("declared exclusion '%s' appears in the outcome equation",
                       bad[1L]), "argument")
    }
    ident <- list(mode = "declared", declared = identification)
  } else {
    se_abort("'identification' must be \"auto\" or a character vector of variable names",
             "argument")
  }
  ident$exclusions <- list(outcome = setdiff(rhs_sel, rhs_out))
  structure(list(
    model = model,
    regimes = se_obs_regimes(model),
    regime_names_given = FALSE,
    selection = list(formula = selection, family = selection_family),
    outcomes = list(outcome = list(formula = outcomes, family = outcome_family)),
    shift = shift,
    observation = if (model == "heckman") "selection" else "treatment",
    dependence = list(family = dependence, structure = "selection_pairs"),
    family = family %||% "continuous",
    panel = NULL, spatial = NULL,
    identification = ident,
    call = cl), class = "switch_spec")
}

se_format_spec_obs <- function(x) {
  lab <- c("Model", "Observation", "Selection", "Outcome", "Shift",
           "Dependence", "Excluded")
  w <- max(nchar(lab)) + 2L
  pad <- function(s) formatC(paste0(s, ":"), width = -w)
  ex <- x$identification$exclusions$outcome
  c("Switching model specification (SwitchEconometrics)",
    sprintf("  %s%s", pad("Model"), if (x$model == "heckman")
      "heckman (sample selection, Tobit-2)"
      else "treatment (endogenous treatment with a shift)"),
    sprintf("  %s%s", pad("Observation"), if (x$model == "heckman")
      "outcome observed when the selection indicator is 1"
      else "outcome observed for every unit"),
    sprintf("  %s%s   [%s]", pad("Selection"),
            se_deparse(x$selection$formula), x$selection$family),
    sprintf("  %s%s   [%s]", pad("Outcome"),
            se_deparse(x$outcomes$outcome$formula), x$outcomes$outcome$family),
    if (!is.null(x$shift)) sprintf("  %s%s", pad("Shift"), se_deparse(x$shift)),
    sprintf("  %s%s (selection disturbance with the outcome disturbance)",
            pad("Dependence"), x$dependence$family),
    sprintf("  %s%s", pad("Excluded"),
            if (length(ex)) paste(ex, collapse = ", ") else "none"))
}

## ---------------------------------------------------------------------------
## Data
## ---------------------------------------------------------------------------
se_build_data_obs <- function(spec, data, weights = NULL, cluster = NULL,
                              subset = NULL, missing = c("drop", "fail"),
                              check_rank = TRUE) {
  missing <- match.arg(missing)
  if (spec$model == "treatment") {
    se_build_data_treatment(spec, data, weights, cluster, subset, missing,
                            check_rank)
  } else {
    se_build_data_heckman(spec, data, weights, cluster, subset, missing,
                          check_rank)
  }
}

## Treatment: built with the G1 data builder on an internal two-regime
## specification (missing values, weights, clusters and the report of removed
## rows are handled there), then given the shift design.
se_build_data_treatment <- function(spec, data, weights, cluster, subset,
                                    missing, check_rank) {
  f <- spec$outcomes$outcome$formula
  sh <- spec$shift
  f_aug <- f
  sv <- attr(stats::terms(sh), "term.labels")
  if (length(sv)) {
    f_aug <- stats::update(f, stats::as.formula(
      paste(". ~ . +", paste(sv, collapse = " + "))))
    environment(f_aug) <- environment(f)
  }
  labs <- se_obs_regimes("treatment")
  esr_spec <- structure(list(
    model = "esr", regimes = labs, regime_names_given = FALSE,
    selection = spec$selection,
    outcomes = stats::setNames(list(
      list(formula = f, family = spec$outcomes$outcome$family),
      list(formula = f_aug, family = spec$outcomes$outcome$family)), labs),
    observation = "switching", dependence = spec$dependence,
    family = spec$family, identification = spec$identification),
    class = "switch_spec")
  sd <- se_build_data(esr_spec, data, weights = weights, cluster = cluster,
                      subset = subset, missing = missing, check_rank = FALSE)
  keep <- rep(FALSE, nrow(data))
  keep[sd$index] <- TRUE
  X <- sd$X[[1L]]
  mfd <- se_eval_frame(sh, data, "shift", subset = keep)
  ttd <- attr(mfd, "terms")
  D <- stats::model.matrix(ttd, mfd)
  contr_d <- attr(D, "contrasts")
  dimnames(D) <- list(NULL, colnames(D))
  se_check_finite(D, "shift")
  d_in <- match(colnames(D), colnames(X))
  X1 <- cbind(X, D[, is.na(d_in), drop = FALSE])
  if (check_rank) {
    se_check_rank(sd$Z, "selection equation")
    Wp <- cbind(X, sd$S * D)
    colnames(Wp) <- c(colnames(X), paste0("shift:", colnames(D)))
    if (nrow(Wp) <= ncol(Wp) + 1L) {
      se_abort(sprintf("%d observations for %d outcome coefficients",
                       nrow(Wp), ncol(Wp)), "data")
    }
    se_check_rank(Wp, "outcome equation with the shift terms")
  }
  sd$model <- "treatment"
  sd$observation <- "treatment"
  sd$X <- stats::setNames(list(X, X1), labs)
  sd$D <- D
  sd$d_in <- d_in
  sd$terms <- list(selection = sd$terms$selection,
                   outcomes = list(outcome = sd$terms$outcomes[[1L]]),
                   shift = stats::delete.response(ttd))
  sd$xlevels <- list(selection = sd$xlevels$selection,
                     outcome = sd$xlevels[[labs[1L]]],
                     shift = stats::.getXlevels(ttd, mfd))
  sd$contrasts <- list(selection = sd$contrasts$selection,
                       outcome = sd$contrasts[[labs[1L]]], shift = contr_d)
  sd$exclusions <- list(outcome = setdiff(
    colnames(sd$Z), c(colnames(X), colnames(D), "(Intercept)")))
  sd$frames <- list(selection = sd$frames$selection,
                    outcome = sd$frames[[labs[1L]]], shift = mfd)
  sd
}

## Heckman: rows with S = 0 need the selection variables only; the outcome
## and its regressors may be missing there.
se_build_data_heckman <- function(spec, data, weights, cluster, subset,
                                  missing, check_rank) {
  if (!is.data.frame(data)) se_abort("'data' must be a data frame", "data")
  n0 <- nrow(data)
  if (n0 == 0L) se_abort("'data' has no rows", "data")
  w_all <- se_resolve_aux(weights, data, "weights")
  cl_all <- se_resolve_aux(cluster, data, "cluster")
  sub_all <- se_resolve_aux(subset, data, "subset")
  if (!is.null(sub_all) && !is.logical(sub_all)) {
    se_abort("'subset' must be a logical vector", "argument")
  }
  in_sub <- if (is.null(sub_all)) rep(TRUE, n0) else !is.na(sub_all) & sub_all
  if (!any(in_sub)) se_abort("'subset' selects no rows", "data")

  fsel <- spec$selection$formula
  sel_name <- se_deparse(fsel[[2L]])
  mf_sel <- se_eval_frame(fsel, data, "selection")
  s_raw <- stats::model.response(mf_sel)
  coding <- se_code_regime(s_raw[in_sub], sel_name)
  S_all <- switch(coding$type,
    logical = as.integer(s_raw),
    factor = match(as.character(s_raw), coding$values) - 1L,
    numeric = ifelse(s_raw %in% c(0, 1), as.integer(s_raw), NA_integer_))
  fo <- spec$outcomes$outcome$formula
  ttx <- stats::delete.response(stats::terms(fo))
  mf_x <- se_eval_frame(ttx, data, "outcome")
  y_all <- tryCatch(eval(fo[[2L]], data, environment(fo)),
                    error = function(e) se_abort(sprintf(
                      "cannot evaluate the response of the outcome equation: %s",
                      conditionMessage(e)), "data"))
  if (length(y_all) != n0) {
    se_abort(sprintf("the outcome response has length %d, not %d",
                     length(y_all), n0), "data")
  }
  if (!is.numeric(y_all)) {
    se_abort(sprintf(paste0(
      "the outcome response must be numeric (continuous); discrete outcomes ",
      "are planned for Generation 4 (versions %s)"), se_generations[["4"]]),
      "unsupported", generation = 4L)
  }
  y_all <- as.numeric(y_all)
  cc_sel <- stats::complete.cases(mf_sel)
  cc_x <- stats::complete.cases(mf_x)
  obs <- !is.na(S_all) & S_all == 1L
  cc_out <- !obs | (cc_x & !is.na(y_all))
  cc_w <- if (is.null(w_all)) TRUE else !is.na(w_all)
  cc_c <- if (is.null(cl_all)) TRUE else !is.na(cl_all)
  keep <- in_sub & cc_sel & cc_out & cc_w & cc_c

  na_count <- function(col, rows) {
    m <- is.na(col)
    if (is.matrix(m)) m <- rowSums(m) > 0
    sum(m & rows)
  }
  cnt <- c(vapply(mf_sel, na_count, numeric(1), rows = in_sub),
           vapply(mf_x, na_count, numeric(1), rows = in_sub & obs))
  cnt <- tapply(cnt, factor(names(cnt), levels = unique(names(cnt))), max)
  cnt <- stats::setNames(as.numeric(cnt), names(cnt))
  own <- sum(in_sub & cc_sel & obs & is.na(y_all))
  if (own > 0) cnt[paste0(se_deparse(fo[[2L]]), " (observed units)")] <- own
  if (!is.null(w_all)) cnt["(weights)"] <- sum(in_sub & is.na(w_all))
  if (!is.null(cl_all)) cnt["(cluster)"] <- sum(in_sub & is.na(cl_all))
  cnt <- cnt[cnt > 0]
  dropped <- which(in_sub & !keep)
  na_report <- list(
    n_input = n0, n_subset = sum(in_sub), n_dropped = length(dropped),
    n_used = sum(keep),
    by_variable = data.frame(variable = names(cnt),
                             n_missing = as.integer(cnt),
                             stringsAsFactors = FALSE, row.names = NULL),
    rows = dropped)
  if (length(dropped)) {
    msg <- sprintf(paste0(
      "%d of %d observations removed because of missing values (%s); ",
      "see the na_report component."), length(dropped), sum(in_sub),
      paste(names(cnt), cnt, sep = ": ", collapse = ", "))
    if (missing == "fail") {
      se_abort(paste0(msg, " Use missing = \"drop\" to remove them."),
               "missing", na_report = na_report)
    }
    se_inform(msg, "missing")
  }

  mf_sel_k <- se_eval_frame(fsel, data, "selection", subset = keep)
  tt_sel <- attr(mf_sel_k, "terms")
  Z <- stats::model.matrix(tt_sel, mf_sel_k)
  contr_z <- attr(Z, "contrasts")
  dimnames(Z) <- list(NULL, colnames(Z))
  S <- S_all[keep]
  mfx <- se_eval_frame(ttx, data, "outcome", subset = keep)
  ttxk <- attr(mfx, "terms")
  ## rows with missing regressors (possible only when S = 0) give NA rows
  okx <- stats::complete.cases(mfx)
  Xok <- stats::model.matrix(ttxk, mfx[okx, , drop = FALSE])
  contr_x <- attr(Xok, "contrasts")
  X <- matrix(NA_real_, length(S), ncol(Xok),
              dimnames = list(NULL, colnames(Xok)))
  X[okx, ] <- Xok
  y <- y_all[keep]
  y[S == 0L] <- NA_real_
  se_check_finite(Z, "selection equation")
  se_check_finite(X[S == 1L, , drop = FALSE], "outcome equation")
  se_check_finite(y[S == 1L], "outcome")
  n_regime <- stats::setNames(c(sum(S == 0L), sum(S == 1L)), spec$regimes)
  if (n_regime[[2L]] == 0L) {
    se_abort("no unit has an observed outcome (selection indicator 1)", "data")
  }
  if (n_regime[[1L]] == 0L) {
    se_abort("every unit has an observed outcome: there is no selection to model",
             "data")
  }
  if (check_rank) {
    se_check_rank(Z, "selection equation")
    Xr <- X[S == 1L, , drop = FALSE]
    if (nrow(Xr) <= ncol(Xr)) {
      se_abort(sprintf("%d observed outcomes for %d outcome coefficients",
                       nrow(Xr), ncol(Xr)), "data")
    }
    se_check_rank(Xr, "outcome equation among the observed units")
  }
  w <- NULL
  if (!is.null(w_all)) {
    w <- w_all[keep]
    if (!is.numeric(w) || any(!is.finite(w)) || any(w <= 0)) {
      se_abort("weights must be finite and strictly positive", "data")
    }
    w <- as.numeric(w)
  }
  clus <- if (is.null(cl_all)) NULL else as.integer(factor(cl_all[keep]))
  structure(list(
    model = "heckman", observation = "selection",
    selection_family = spec$selection$family,
    outcome_family = spec$outcomes$outcome$family,
    dependence = spec$dependence$family,
    S = S, y = y, Z = Z, X = list(outcome = X), regimes = spec$regimes,
    regime_values = coding$values, regime_type = coding$type,
    selection_name = sel_name, n = length(S), n_regime = n_regime,
    weights = w, cluster = clus,
    n_clusters = if (is.null(clus)) NULL else max(clus),
    index = which(keep),
    terms = list(selection = stats::delete.response(tt_sel),
                 outcomes = list(outcome = ttxk)),
    xlevels = list(selection = stats::.getXlevels(tt_sel, mf_sel_k),
                   outcome = stats::.getXlevels(ttxk, mfx)),
    contrasts = list(selection = contr_z, outcome = contr_x),
    exclusions = list(outcome = setdiff(colnames(Z),
                                        c(colnames(X), "(Intercept)"))),
    frames = list(selection = mf_sel_k, outcome = mfx),
    na_report = na_report), class = "switch_data")
}

## ---------------------------------------------------------------------------
## Parameter maps
## ---------------------------------------------------------------------------
## Order: selection coefficients, outcome coefficients, shift coefficients
## (treatment), sigma, rho. Names: selection:<term>, outcome:<term>,
## shift:<term>, outcome:sigma, outcome:rho.
se_parmap_obs <- function(sd) {
  X <- sd$X[[1L]]
  rows <- list(
    data.frame(name = paste0("selection:", colnames(sd$Z)), block = "gamma",
               equation = "selection", term = colnames(sd$Z),
               transform = "identity", stringsAsFactors = FALSE),
    data.frame(name = paste0("outcome:", colnames(X)), block = "beta",
               equation = "outcome", term = colnames(X),
               transform = "identity", stringsAsFactors = FALSE))
  if (sd$model == "treatment") {
    rows[[3L]] <- data.frame(
      name = paste0("shift:", colnames(sd$D)), block = "delta",
      equation = "shift", term = colnames(sd$D), transform = "identity",
      stringsAsFactors = FALSE)
  }
  rows[[length(rows) + 1L]] <- data.frame(
    name = c("outcome:sigma", "outcome:rho"), block = c("sigma", "rho"),
    equation = "outcome", term = c("sigma", "rho"),
    transform = c("log", "atanh"), stringsAsFactors = FALSE)
  map <- new_se_parmap(do.call(rbind, rows))
  map$index$delta <- which(map$elements$block == "delta")
  map$model <- sd$model
  map$d_in <- sd$d_in
  if (sd$model == "treatment") {
    esr <- se_parmap_esr(sd)
    labs <- sd$regimes
    kx <- ncol(X)
    A <- matrix(0, esr$p, map$p, dimnames = list(esr$elements$working_name,
                                                map$elements$working_name))
    ib <- map$index$beta$outcome
    A[cbind(esr$index$gamma, map$index$gamma)] <- 1
    A[cbind(esr$index$beta[[labs[1L]]], ib)] <- 1
    b1 <- esr$index$beta[[labs[2L]]]
    A[cbind(b1[seq_len(kx)], ib)] <- 1
    inx <- !is.na(sd$d_in)
    if (any(inx)) A[cbind(b1[sd$d_in[inx]], map$index$delta[inx])] <- 1
    if (any(!inx)) {
      A[cbind(b1[kx + seq_len(sum(!inx))], map$index$delta[!inx])] <- 1
    }
    for (l in labs) {
      A[esr$index$sigma[[l]], map$index$sigma$outcome] <- 1
      A[esr$index$rho[[l]], map$index$rho$outcome] <- 1
    }
    map$esr <- esr
    map$A <- A
  }
  map
}

## The ESR parameter vector implied by a treatment vector (working or
## natural scale: sigma and rho are copied, the rest is linear).
se_treat_to_esr <- function(map, theta) {
  out <- drop(map$A %*% theta)
  names(out) <- NULL
  out
}

## A treatment fit seen as a fit of the restricted ESR, so that the G1
## effects, predictions and scenarios apply (OBSERVATION_MECHANISMS.md s.3.5).
## Covariances are A V A' (singular by construction).
se_esr_view <- function(object) {
  if (!identical(object$model, "treatment")) return(object)
  map <- object$map
  esr <- map$esr
  A <- map$A
  v <- object
  v$model <- "esr"
  v$map <- esr
  v$coefficients <- stats::setNames(se_treat_to_esr(map, object$coefficients),
                                    esr$elements$name)
  V <- object$vcov
  na <- is.na(diag(V))
  V0 <- V
  V0[is.na(V0)] <- 0
  Ve <- A %*% V0 %*% t(A)
  if (any(na)) {
    bad <- rowSums(abs(A[, na, drop = FALSE])) > 0
    Ve[bad, ] <- NA_real_
    Ve[, bad] <- NA_real_
  }
  dimnames(Ve) <- list(esr$elements$name, esr$elements$name)
  v$vcov <- Ve
  if (!is.null(object$coef_working)) {
    v$coef_working <- stats::setNames(
      se_treat_to_esr(map, object$coef_working), esr$elements$working_name)
    v$vcov_working <- A %*% object$vcov_working %*% t(A)
  }
  if (!is.null(object$data)) v$data$model <- "esr"
  ts <- object$two_step
  if (!is.null(ts) && !is.null(ts$vcov_psi)) {
    ## psi_T = (gamma, beta, delta, theta) -> psi_ESR = (gamma, beta_0,
    ## theta_0, beta_1, theta_1)
    labs <- object$regimes
    kz <- length(map$index$gamma); kx <- length(map$index$beta$outcome)
    kd <- length(map$index$delta)
    k1 <- length(esr$index$beta[[labs[2L]]])
    P <- kz + kx + 1L + k1 + 1L
    B <- matrix(0, P, kz + kx + kd + 1L)
    B[cbind(seq_len(kz), seq_len(kz))] <- 1
    B[cbind(kz + seq_len(kx), kz + seq_len(kx))] <- 1
    B[kz + kx + 1L, kz + kx + kd + 1L] <- 1
    o1 <- kz + kx + 1L
    B[cbind(o1 + seq_len(kx), kz + seq_len(kx))] <- 1
    d_in <- map$d_in
    inx <- !is.na(d_in)
    if (any(inx)) B[cbind(o1 + d_in[inx], kz + kx + which(inx))] <- 1
    if (any(!inx)) {
      B[cbind(o1 + kx + seq_len(sum(!inx)), kz + kx + which(!inx))] <- 1
    }
    B[P, kz + kx + kd + 1L] <- 1
    ts$psi <- drop(B %*% ts$psi)
    ts$vcov_psi <- B %*% ts$vcov_psi %*% t(B)
    ts$index_psi <- stats::setNames(
      list(seq_len(kz), kz + seq_len(kx + 1L), o1 + seq_len(k1 + 1L)),
      c("gamma", labs))
    v$two_step <- ts
  }
  v
}

## Equations of a fit in printing order, and their titles.
se_equations <- function(object) {
  if (se_is_multi(object$model)) return(se_equations_multi(object))
  if (se_is_obs(object$model)) {
    c("selection", "outcome", if (object$model == "treatment") "shift")
  } else c("selection", object$regimes)
}

se_equation_title <- function(object, eq) {
  if (eq == "selection") return("Selection equation (probit)")
  if (se_is_multi(object$model) && startsWith(eq, "selection[")) {
    return(sprintf("Selection, alternative '%s' against '%s' (multinomial logit)",
                   sub("^selection\\[(.*)\\]$", "\\1", eq), object$base))
  }
  if (se_is_obs(object$model)) {
    if (eq == "shift") {
      return(sprintf("Shift when the regime is '%s' (treatment effect d'delta)",
                     object$regimes[2L]))
    }
    return(if (object$model == "heckman")
      "Outcome equation (observed when the selection indicator is 1)"
      else "Outcome equation (all units)")
  }
  sprintf("Outcome equation, regime '%s'", eq)
}

se_model_title <- function(model) {
  switch(model,
    heckman = "Sample selection model (Heckman, Tobit-2)",
    treatment = "Endogenous treatment model with a shift",
    tobit5 = "Tobit-5 model (endogenous switching regression)",
    multinomial_esr = "Multinomial endogenous switching regression",
    "Endogenous switching regression")
}
