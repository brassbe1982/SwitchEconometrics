## Layer 1: attaching data to a specification.
## Builds the internal switch_data object (SOFTWARE_ARCHITECTURE.md s.3):
## regime vector, outcome, design matrices, weights, clusters, terms for
## prediction, and the report of removed rows. Rows are never removed
## without a message and a record (specification section 14.1).

## Resolve weights / cluster / subset given as NULL, a one-sided formula, a
## column name or a vector of length nrow(data).
se_resolve_aux <- function(arg, data, name) {
  if (is.null(arg)) return(NULL)
  n <- nrow(data)
  if (inherits(arg, "formula")) {
    if (length(arg) != 2L) {
      se_abort(sprintf("'%s' formula must be one-sided, e.g. ~ w", name),
               "argument")
    }
    v <- tryCatch(eval(arg[[2L]], data, environment(arg)),
                  error = function(e) se_abort(sprintf(
                    "cannot evaluate '%s': %s", name, conditionMessage(e)),
                    "data"))
  } else if (is.character(arg) && length(arg) == 1L && n != 1L) {
    if (!arg %in% names(data)) {
      se_abort(sprintf("column '%s' given as '%s' is not in 'data'", arg, name),
               "data")
    }
    v <- data[[arg]]
  } else {
    v <- arg
  }
  if (length(v) != n) {
    se_abort(sprintf("'%s' must have length nrow(data) = %d (it has %d)",
                     name, n, length(v)), "argument")
  }
  v
}

## Model frame on all rows with missing values kept.
se_eval_frame <- function(f, data, what, subset = NULL) {
  args <- list(formula = f, data = data, na.action = stats::na.pass,
               drop.unused.levels = !is.null(subset))
  if (!is.null(subset)) args$subset <- subset
  tryCatch(do.call(stats::model.frame, args),
           error = function(e) se_abort(sprintf(
             "cannot evaluate the %s formula: %s", what, conditionMessage(e)),
             "data"))
}

## Code the regime indicator as integer 0/1 (NA kept).
se_code_regime <- function(s, name) {
  if (is.null(s)) se_abort("the selection formula has no response", "data")
  if (is.matrix(s) && ncol(s) > 1L) {
    se_abort("the selection response must be a single variable", "data")
  }
  if (is.logical(s)) {
    return(list(S = as.integer(s), values = c("FALSE", "TRUE"),
                type = "logical"))
  }
  if (is.factor(s)) {
    s <- droplevels(s)
    if (nlevels(s) != 2L) {
      se_abort(sprintf(
        "the regime indicator '%s' must have exactly 2 levels (it has %d)",
        name, nlevels(s)), "data")
    }
    return(list(S = as.integer(s) - 1L, values = levels(s), type = "factor"))
  }
  if (is.numeric(s)) {
    u <- unique(s[!is.na(s)])
    if (!all(u %in% c(0, 1))) {
      se_abort(sprintf(paste0(
        "the regime indicator '%s' must be coded 0/1, logical or a ",
        "two-level factor; found value(s) %s"), name,
        paste(utils_head(sort(u[!u %in% c(0, 1)]), 5), collapse = ", ")),
        "data")
    }
    return(list(S = as.integer(s), values = c("0", "1"), type = "numeric"))
  }
  se_abort(sprintf(paste0(
    "the regime indicator '%s' must be logical, 0/1 numeric or a two-level ",
    "factor (convert character values with factor())"), name), "data")
}

utils_head <- function(x, n) x[seq_len(min(n, length(x)))]

## Match outcome equations to regimes. Returns the outcome indices for
## (S = 0, S = 1).
se_match_regimes <- function(labels, coding, named, sel_name) {
  r0 <- unique(c(coding$values[1L], "0", "regime_0", "FALSE"))
  r1 <- unique(c(coding$values[2L], "1", "regime_1", "TRUE"))
  m0 <- which(labels %in% r0 & !labels %in% r1)
  m1 <- which(labels %in% r1 & !labels %in% r0)
  if (length(m0) == 1L && length(m1) == 1L && m0 != m1) return(c(m0, m1))
  if (length(m0) == 1L && !length(m1)) return(c(m0, 3L - m0))
  if (length(m1) == 1L && !length(m0)) return(c(3L - m1, m1))
  if (named) {
    se_inform(sprintf(paste0(
      "Outcome equations matched to regimes by position: '%s' for %s = %s, ",
      "'%s' for %s = %s."), labels[1L], sel_name, coding$values[1L],
      labels[2L], sel_name, coding$values[2L]), "regime_mapping")
  }
  c(1L, 2L)
}

se_check_rank <- function(X, what) {
  q <- qr(X, tol = 1e-7)
  if (q$rank < ncol(X)) {
    alias <- colnames(X)[q$pivot[(q$rank + 1L):ncol(X)]]
    se_abort(sprintf(
      "the design of the %s is rank deficient; aliased column(s): %s",
      what, paste(alias, collapse = ", ")), "rank", aliased = alias)
  }
  invisible(TRUE)
}

se_check_finite <- function(X, what) {
  bad <- !is.finite(X)
  if (any(bad)) {
    cols <- if (is.matrix(X)) unique(colnames(X)[col(X)[bad]]) else what
    se_abort(sprintf("non-finite values (Inf or NaN) in the %s: %s", what,
                     paste(cols, collapse = ", ")), "data")
  }
}

## Build the switch_data object for a specification.
se_build_data <- function(spec, data, weights = NULL, cluster = NULL,
                          subset = NULL, missing = c("drop", "fail"),
                          check_rank = TRUE) {
  missing <- match.arg(missing)
  if (!inherits(spec, "switch_spec")) {
    se_abort("'spec' must be a switch_spec object", "argument")
  }
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

  ## --- regime indicator and outcome-to-regime matching
  fsel <- spec$selection$formula
  sel_name <- se_deparse(fsel[[2L]])
  mf_sel <- se_eval_frame(fsel, data, "selection")
  s_raw <- stats::model.response(mf_sel)
  coding <- se_code_regime(s_raw[in_sub], sel_name)
  ## code all rows with the coding found on the subset (other values -> NA;
  ## such rows lie outside the subset and are never used)
  S_all <- switch(coding$type,
    logical = as.integer(s_raw),
    factor = match(as.character(s_raw), coding$values) - 1L,
    numeric = ifelse(s_raw %in% c(0, 1), as.integer(s_raw), NA_integer_))
  ord <- if (identical(spec$model, "tobit5")) 1:2
         else se_match_regimes(names(spec$outcomes), coding,
                               spec$regime_names_given, sel_name)
  labels <- names(spec$outcomes)[ord]
  fout <- lapply(spec$outcomes[ord], function(o) o$formula)
  names(fout) <- labels

  ## --- missing values (evaluated on all rows)
  mf_x <- lapply(labels, function(l) se_eval_frame(
    stats::delete.response(stats::terms(fout[[l]])), data,
    sprintf("'%s' outcome", l)))
  lhs <- lapply(labels, function(l) {
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
  y_all <- ifelse(S_all == 1L, lhs[[2L]], lhs[[1L]])
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

  ## --- design matrices on the estimation sample
  mf_sel_k <- se_eval_frame(fsel, data, "selection", subset = keep)
  tt_sel <- attr(mf_sel_k, "terms")
  Z <- stats::model.matrix(tt_sel, mf_sel_k)
  S <- S_all[keep]
  X <- list(); terms_out <- list(); xlev <- list(); contr <- list()
  frames <- list(selection = mf_sel_k)
  for (l in labels) {
    f <- stats::delete.response(stats::terms(fout[[l]]))
    mf <- se_eval_frame(f, data, sprintf("'%s' outcome", l), subset = keep)
    frames[[l]] <- mf
    tt <- attr(mf, "terms")
    X[[l]] <- stats::model.matrix(tt, mf)
    terms_out[[l]] <- tt
    xlev[[l]] <- stats::.getXlevels(tt, mf)
    contr[[l]] <- attr(X[[l]], "contrasts")
  }
  y <- y_all[keep]
  dimnames(Z) <- list(NULL, colnames(Z))
  X <- lapply(X, function(m) { dimnames(m) <- list(NULL, colnames(m)); m })

  se_check_finite(Z, "selection equation")
  for (l in labels) se_check_finite(X[[l]], sprintf("outcome equation '%s'", l))
  se_check_finite(y, "outcome")

  n_regime <- stats::setNames(c(sum(S == 0L), sum(S == 1L)), labels)
  if (any(n_regime == 0L)) {
    se_abort(sprintf("regime '%s' has no observations in the estimation sample",
                     labels[n_regime == 0L][1L]), "data")
  }
  if (check_rank) {
    se_check_rank(Z, "selection equation")
    for (r in 1:2) {
      Xr <- X[[r]][S == r - 1L, , drop = FALSE]
      if (nrow(Xr) <= ncol(Xr)) {
        se_abort(sprintf(paste0(
          "regime '%s' has %d observations for %d outcome coefficients"),
          labels[r], nrow(Xr), ncol(Xr)), "data")
      }
      se_check_rank(Xr, sprintf("outcome equation '%s' within its regime",
                                labels[r]))
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

  excl <- lapply(labels, function(l)
    setdiff(colnames(Z), c(colnames(X[[l]]), "(Intercept)")))
  names(excl) <- labels

  structure(list(
    model = spec$model, observation = spec$observation,
    selection_family = spec$selection$family,
    outcome_family = spec$outcomes[[1L]]$family,
    dependence = spec$dependence$family,
    S = S, y = y, Z = Z, X = X, regimes = labels,
    regime_values = coding$values, regime_type = coding$type,
    selection_name = sel_name,
    n = length(S), n_regime = n_regime,
    weights = w, cluster = clus,
    n_clusters = if (is.null(clus)) NULL else max(clus),
    index = which(keep),
    terms = list(selection = stats::delete.response(tt_sel),
                 outcomes = terms_out),
    xlevels = c(list(selection = stats::.getXlevels(tt_sel, mf_sel_k)), xlev),
    contrasts = c(list(selection = attr(Z, "contrasts")), contr),
    exclusions = excl, frames = frames,
    na_report = na_report), class = "switch_data")
}

#' @export
print.switch_data <- function(x, ...) {
  cat(sprintf("Switching data: %d observations (%s), %d selection columns,",
              x$n, paste(x$regimes, x$n_regime, sep = " = ", collapse = ", "),
              ncol(x$Z)),
      sprintf("outcome columns %s\n",
              paste(vapply(x$X, ncol, integer(1)), collapse = "/")))
  if (x$na_report$n_dropped) {
    cat(sprintf("  %d rows removed for missing values\n",
                x$na_report$n_dropped))
  }
  invisible(x)
}
