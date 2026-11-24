## Layers 1 and 5 for multinomial regime selection (Generation 2, WP2.2).
## Derivation: 01_Econometric_Architecture/MULTINOMIAL_ESR.md s.1-4 and s.11.
## J regimes, any J >= 2; nothing in this file limits J.
##
## Regimes are the levels of the selection variable, in level order. One
## alternative is the base (gamma = 0). Outcome regressors are needed for
## every unit, whatever its regime, so that counterfactuals are computable.

se_multi_models <- c("multinomial_esr")
se_is_multi <- function(x) isTRUE(x %in% se_multi_models)

## Specification (called by switch_model()).
se_spec_multi <- function(selection, outcomes, model, selection_family,
                          outcome_family, dependence, family, identification,
                          base, correction, dependence_structure, cl) {
  if (inherits(selection, "formula")) {
    if (length(selection) != 3L) {
      se_abort("'selection' must be a two-sided formula, e.g. regime ~ z1 + z2",
               "argument")
    }
  } else if (is.list(selection)) {
    se_abort(paste0("alternative-specific selection formulas are not available ",
                    "in this version; give one formula (the same regressors ",
                    "for every alternative)"), "unsupported")
  } else {
    se_abort("'selection' must be a two-sided formula", "argument")
  }
  if (inherits(outcomes, "formula") || !is.list(outcomes) ||
      length(outcomes) < 2L) {
    se_abort("'outcomes' must be a list of formulas, one per regime",
             "argument")
  }
  ok <- vapply(outcomes, function(f) inherits(f, "formula") && length(f) == 3L,
               logical(1))
  if (!all(ok)) {
    se_abort("every element of 'outcomes' must be a two-sided formula",
             "argument")
  }
  nm <- names(outcomes)
  named <- !is.null(nm)
  if (named && (anyNA(nm) || !all(nzchar(nm)))) {
    se_abort("name either all outcome equations or none", "argument")
  }
  if (named && anyDuplicated(nm)) {
    se_abort("outcome equation names must be unique", "argument")
  }
  if (named && any(grepl("[][]|:", nm) | nm == "selection")) {
    se_abort(paste0("regime labels cannot contain ':', '[' or ']' and cannot ",
                    "be 'selection'"), "argument")
  }
  all_f <- c(list(selection), outcomes)
  if (any(vapply(all_f, function(f) "." %in% all.vars(f), logical(1)))) {
    se_abort("'.' in formulas is not supported; list the variables explicitly",
             "argument")
  }
  sel_resp <- all.vars(selection[[2L]])
  rhs_sel <- all.vars(selection[[3L]])
  rhs_out <- lapply(outcomes, function(f) all.vars(f[[3L]]))
  for (k in seq_along(outcomes)) {
    if (length(intersect(sel_resp, rhs_out[[k]]))) {
      se_abort(sprintf(paste0("the regime indicator '%s' cannot be a regressor ",
                              "in an outcome equation"), sel_resp[1L]),
               "argument")
    }
  }
  correction <- correction %||% "lee"
  if (!is.character(correction) || length(correction) != 1L ||
      !correction %in% c("lee", "dmf", "bfg1", "bfg2")) {
    se_abort("'correction' must be \"lee\", \"dmf\", \"bfg1\" or \"bfg2\"",
             "argument")
  }
  dependence_structure <- dependence_structure %||% "lee"
  if (!is.character(dependence_structure) ||
      length(dependence_structure) != 1L ||
      !dependence_structure %in% c("lee", "normal_scores")) {
    se_abort("'dependence_structure' must be \"lee\" or \"normal_scores\"",
             "argument")
  }
  if (!is.null(base) && (!is.character(base) || length(base) != 1L ||
                         is.na(base))) {
    se_abort("'base' must be a regime label", "argument")
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
    for (k in seq_along(outcomes)) {
      bad <- intersect(identification, rhs_out[[k]])
      if (length(bad)) {
        se_abort(sprintf("declared exclusion '%s' appears in an outcome equation",
                         bad[1L]), "argument")
      }
    }
    ident <- list(mode = "declared", declared = identification)
  } else {
    se_abort("'identification' must be \"auto\" or a character vector of variable names",
             "argument")
  }
  ident$exclusions <- lapply(rhs_out, function(v) setdiff(rhs_sel, v))
  structure(list(
    model = model,
    regimes = if (named) nm else NULL,          # set from the data if NULL
    regime_names_given = named,
    selection = list(formula = selection, family = selection_family,
                     base = base),
    outcomes = lapply(outcomes, function(f)
      list(formula = f, family = outcome_family)),
    observation = "switching",
    dependence = list(family = dependence, structure = dependence_structure),
    correction = correction,
    family = family %||% "continuous",
    panel = NULL, spatial = NULL,
    identification = ident,
    call = cl), class = "switch_spec")
}

se_format_spec_multi <- function(x) {
  labs <- x$regimes %||% paste0("equation ", seq_along(x$outcomes))
  lab <- c("Model", "Selection", "Dependence", "Base", labs)
  w <- max(nchar(lab)) + 2L
  pad <- function(s) formatC(paste0(s, ":"), width = -w)
  c("Switching model specification (SwitchEconometrics)",
    sprintf("  %s%s (%d regimes)", pad("Model"), x$model, length(x$outcomes)),
    sprintf("  %s%s   [%s]", pad("Selection"),
            se_deparse(x$selection$formula), x$selection$family),
    sprintf("  %s%s", pad("Base"), x$selection$base %||%
              "first level of the selection variable"),
    vapply(seq_along(labs), function(k) sprintf(
      "  %s%s   [%s]", pad(labs[k]), se_deparse(x$outcomes[[k]]$formula),
      x$outcomes[[k]]$family), character(1)),
    sprintf("  %s%s", pad("Dependence"), switch(x$dependence$structure,
      lee = "Lee (1983): one correlation per regime with its own selection index",
      normal_scores = "normal scores: J correlations per regime")))
}

## ---------------------------------------------------------------------------
## Data
## ---------------------------------------------------------------------------
se_build_data_multi <- function(spec, data, weights = NULL, cluster = NULL,
                                subset = NULL, missing = c("drop", "fail"),
                                check_rank = TRUE) {
  missing <- match.arg(missing)
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

  ## regime variable
  fsel <- spec$selection$formula
  sel_name <- se_deparse(fsel[[2L]])
  mf_sel <- se_eval_frame(fsel, data, "selection")
  s_raw <- stats::model.response(mf_sel)
  if (is.null(s_raw) || (is.matrix(s_raw) && ncol(s_raw) > 1L)) {
    se_abort("the selection response must be a single variable", "data")
  }
  s_fac <- if (is.factor(s_raw)) droplevels(s_raw[in_sub]) else
    factor(s_raw[in_sub])
  levs <- levels(s_fac)
  J <- length(levs)
  nout <- length(spec$outcomes)
  if (J != nout) {
    se_abort(sprintf(paste0(
      "the regime variable '%s' has %d levels (%s) but %d outcome equations ",
      "were given"), sel_name, J, paste(utils_head(levs, 10), collapse = ", "),
      nout), "data")
  }
  if (spec$regime_names_given) {
    nm <- names(spec$outcomes)
    if (!setequal(nm, levs)) {
      se_abort(sprintf(paste0(
        "the names of 'outcomes' (%s) must be the levels of '%s' (%s)"),
        paste(nm, collapse = ", "), sel_name, paste(levs, collapse = ", ")),
        "data")
    }
    ord <- match(levs, nm)
  } else {
    se_inform(sprintf(paste0(
      "Outcome equations matched to the levels of '%s' by position: %s."),
      sel_name, paste(levs, collapse = ", ")), "regime_mapping")
    ord <- seq_len(J)
  }
  if (any(grepl("[][]|:", levs) | levs == "selection")) {
    se_abort(paste0("regime labels cannot contain ':', '[' or ']' and cannot ",
                    "be 'selection'; rename the levels"), "data")
  }
  fout <- stats::setNames(lapply(spec$outcomes[ord], function(o) o$formula),
                          levs)
  base <- spec$selection$base %||% levs[1L]
  if (!base %in% levs) {
    se_abort(sprintf("'base' (%s) is not a level of '%s' (%s)", base, sel_name,
                     paste(levs, collapse = ", ")), "argument")
  }
  S_all <- match(as.character(s_raw), levs)

  mf_x <- lapply(levs, function(l) se_eval_frame(
    stats::delete.response(stats::terms(fout[[l]])), data,
    sprintf("'%s' outcome", l)))
  lhs <- lapply(levs, function(l) {
    v <- tryCatch(eval(fout[[l]][[2L]], data, environment(fout[[l]])),
                  error = function(e) se_abort(sprintf(
                    "cannot evaluate the response of outcome '%s': %s", l,
                    conditionMessage(e)), "data"))
    if (length(v) != n0) {
      se_abort(sprintf("the response of outcome '%s' has length %d, not %d",
                       l, length(v), n0), "data")
    }
    if (!is.numeric(v)) {
      se_abort(sprintf(paste0(
        "the response of outcome '%s' must be numeric (continuous); ",
        "discrete outcomes are planned for Generation 4 (versions %s)"), l,
        se_generations[["4"]]), "unsupported", generation = 4L)
    }
    as.numeric(v)
  })
  y_all <- rep(NA_real_, n0)
  for (j in seq_len(J)) {
    r <- !is.na(S_all) & S_all == j
    y_all[r] <- lhs[[j]][r]
  }
  cc_sel <- stats::complete.cases(mf_sel)
  cc_x <- Reduce(`&`, lapply(mf_x, stats::complete.cases))
  cc_y <- !is.na(y_all)
  cc_w <- if (is.null(w_all)) TRUE else !is.na(w_all)
  cc_c <- if (is.null(cl_all)) TRUE else !is.na(cl_all)
  keep <- in_sub & cc_sel & cc_x & cc_y & cc_w & cc_c

  na_count <- function(col) {
    m <- is.na(col)
    if (is.matrix(m)) m <- rowSums(m) > 0
    sum(m & in_sub)
  }
  cnt <- c(vapply(mf_sel, na_count, numeric(1)),
           unlist(lapply(mf_x, function(mf) vapply(mf, na_count, numeric(1)))))
  cnt <- tapply(cnt, factor(names(cnt), levels = unique(names(cnt))), max)
  cnt <- stats::setNames(as.numeric(cnt), names(cnt))
  own <- sum(in_sub & cc_sel & is.na(y_all))
  if (own > 0) {
    cnt[paste0(paste(unique(vapply(fout, function(f) se_deparse(f[[2L]]),
                                   character(1))), collapse = "/"),
               " (in its regime)")] <- own
  }
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
  X <- list(); terms_out <- list(); xlev <- list(); contr <- list()
  frames <- list(selection = mf_sel_k)
  for (l in levs) {
    f <- stats::delete.response(stats::terms(fout[[l]]))
    mf <- se_eval_frame(f, data, sprintf("'%s' outcome", l), subset = keep)
    frames[[l]] <- mf
    tt <- attr(mf, "terms")
    m <- stats::model.matrix(tt, mf)
    contr[[l]] <- attr(m, "contrasts")
    dimnames(m) <- list(NULL, colnames(m))
    X[[l]] <- m
    terms_out[[l]] <- tt
    xlev[[l]] <- stats::.getXlevels(tt, mf)
  }
  y <- y_all[keep]
  se_check_finite(Z, "selection equation")
  for (l in levs) se_check_finite(X[[l]], sprintf("outcome equation '%s'", l))
  se_check_finite(y, "outcome")
  n_regime <- stats::setNames(tabulate(S, J), levs)
  if (any(n_regime == 0L)) {
    se_abort(sprintf("regime '%s' has no observations in the estimation sample",
                     levs[n_regime == 0L][1L]), "data")
  }
  if (check_rank) {
    se_check_rank(Z, "selection equation")
    for (j in seq_len(J)) {
      Xr <- X[[j]][S == j, , drop = FALSE]
      if (nrow(Xr) <= ncol(Xr) + 1L) {
        se_abort(sprintf(
          "regime '%s' has %d observations for %d outcome coefficients",
          levs[j], nrow(Xr), ncol(Xr)), "data")
      }
      se_check_rank(Xr, sprintf("outcome equation '%s' within its regime",
                                levs[j]))
    }
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
  excl <- stats::setNames(lapply(levs, function(l)
    setdiff(colnames(Z), c(colnames(X[[l]]), "(Intercept)"))), levs)
  structure(list(
    model = spec$model, observation = "switching",
    selection_family = spec$selection$family,
    outcome_family = spec$outcomes[[1L]]$family,
    dependence = spec$dependence$family,
    structure = spec$dependence$structure, correction = spec$correction,
    S = S, y = y, Z = Z, X = X, regimes = levs, J = J,
    base = match(base, levs), alternatives = setdiff(levs, base),
    regime_values = levs, regime_type = "factor",
    selection_name = sel_name, n = length(S), n_regime = n_regime,
    weights = w, cluster = clus,
    n_clusters = if (is.null(clus)) NULL else max(clus),
    index = which(keep),
    terms = list(selection = stats::delete.response(tt_sel),
                 outcomes = terms_out),
    xlevels = c(list(selection = stats::.getXlevels(tt_sel, mf_sel_k)), xlev),
    contrasts = c(list(selection = contr_z), contr),
    exclusions = excl, frames = frames, na_report = na_report),
    class = "switch_data")
}

## ---------------------------------------------------------------------------
## Parameter map
## ---------------------------------------------------------------------------
## Order: selection coefficients of the non-base alternatives (level order),
## then for each regime: outcome coefficients, and
##   kind "lee":      sigma, rho
##   kind "moments":  the coefficients of the correction terms (two-step
##                    corrections of Dubin-McFadden and BFG), no sigma, rho
## Names: selection[<alt>]:<term>, <regime>:<term>, <regime>:sigma,
## <regime>:rho, <regime>:theta[<alt>].
se_parmap_multi <- function(sd, kind = NULL) {
  kind <- kind %||% if (identical(sd$correction_fit, TRUE)) "moments"
                    else if (identical(sd$structure, "normal_scores")) "ns"
                    else "lee"
  kz <- ncol(sd$Z)
  rows <- lapply(sd$alternatives, function(a) data.frame(
    name = sprintf("selection[%s]:%s", a, colnames(sd$Z)), block = "gamma",
    equation = sprintf("selection[%s]", a), term = colnames(sd$Z),
    transform = "identity", stringsAsFactors = FALSE))
  for (lab in sd$regimes) {
    X <- sd$X[[lab]]
    rows[[length(rows) + 1L]] <- data.frame(
      name = paste0(lab, ":", colnames(X)), block = "beta", equation = lab,
      term = colnames(X), transform = "identity", stringsAsFactors = FALSE)
    if (kind == "lee") {
      rows[[length(rows) + 1L]] <- data.frame(
        name = paste0(lab, c(":sigma", ":rho")), block = c("sigma", "rho"),
        equation = lab, term = c("sigma", "rho"),
        transform = c("log", "atanh"), stringsAsFactors = FALSE)
    } else if (kind == "ns") {
      rows[[length(rows) + 1L]] <- data.frame(
        name = c(paste0(lab, ":sigma"), sprintf("%s:rho[%s]", lab, sd$regimes)),
        block = c("sigma", rep("rho", length(sd$regimes))),
        equation = lab, term = c("sigma", sprintf("rho[%s]", sd$regimes)),
        transform = c("log", rep("identity", length(sd$regimes))),
        stringsAsFactors = FALSE)
    } else {
      tt <- se_correction_labels(sd, lab)
      rows[[length(rows) + 1L]] <- data.frame(
        name = sprintf("%s:theta[%s]", lab, tt), block = "theta",
        equation = lab, term = sprintf("theta[%s]", tt),
        transform = "identity", stringsAsFactors = FALSE)
    }
  }
  map <- new_se_parmap(do.call(rbind, rows))
  e <- map$elements
  map$index$gamma_alt <- stats::setNames(lapply(sd$alternatives, function(a)
    which(e$equation == sprintf("selection[%s]", a))), sd$alternatives)
  map$index$theta <- stats::setNames(lapply(sd$regimes, function(l)
    which(e$block == "theta" & e$equation == l)), sd$regimes)
  map$model <- sd$model
  map$kind <- kind
  map$J <- sd$J
  map$kz <- kz
  if (kind == "ns") {
    map$groups <- unname(map$index$rho)
    ir <- unlist(map$index$rho)
    map$elements$working_name[ir] <- sub(":rho\\[", ":ball[",
                                         map$elements$name[ir])
    map$nodes <- sd$quadrature_nodes %||% 14L
    map$nodes_coarse <- 7L
    map$costly_hessian <- TRUE
  }
  map
}

## Equations of a multinomial fit in printing order.
se_equations_multi <- function(object) {
  e <- object$map$elements
  c(unique(e$equation[e$block == "gamma"]), object$regimes)
}
