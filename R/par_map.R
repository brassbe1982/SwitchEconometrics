## Layer 5: parameter maps.
## A parameter map describes the parameter vector of a model: natural and
## working names, the block, equation and term of every element, its
## transformation, and which elements are fixed (restricted models such as
## rho = 0 for the likelihood-ratio test reuse the same likelihood engine).
## Architecture: 02_Computational_Architecture/SOFTWARE_ARCHITECTURE.md s.3.

new_se_parmap <- function(elements) {
  stopifnot(is.data.frame(elements),
            all(c("name", "block", "equation", "term", "transform") %in%
                  names(elements)))
  if (anyDuplicated(elements$name)) {
    se_abort("duplicated parameter names in the parameter map", "internal")
  }
  p <- nrow(elements)
  tr <- lapply(elements$transform, se_transform)
  elements$working_name <- vapply(seq_len(p), function(i) {
    if (elements$transform[i] == "identity") return(elements$name[i])
    sprintf("%s:%s", elements$equation[i],
            sprintf(tr[[i]]$label, elements$term[i]))
  }, character(1))
  idx <- function(b) {
    eq <- unique(elements$equation[elements$block == b])
    stats::setNames(lapply(eq, function(e)
      which(elements$block == b & elements$equation == e)), eq)
  }
  index <- list(gamma = which(elements$block == "gamma"),
                beta = idx("beta"), sigma = idx("sigma"), rho = idx("rho"))
  structure(list(elements = elements, p = p, index = index,
                 fixed = rep(FALSE, p),
                 fixed_value = rep(NA_real_, p)),
            class = "se_parmap")
}

## Parameter map of the binary Gaussian ESR, from a switch_data object.
## Order: selection coefficients, then for each regime in canonical order
## (S = 0 first, then S = 1): outcome coefficients, sigma, rho.
se_parmap_esr <- function(sd) {
  rows <- list(data.frame(
    name = paste0("selection:", colnames(sd$Z)), block = "gamma",
    equation = "selection", term = colnames(sd$Z), transform = "identity",
    stringsAsFactors = FALSE))
  for (r in seq_along(sd$regimes)) {
    lab <- sd$regimes[r]
    X <- sd$X[[r]]
    rows[[length(rows) + 1L]] <- data.frame(
      name = c(paste0(lab, ":", colnames(X)), paste0(lab, ":sigma"),
               paste0(lab, ":rho")),
      block = c(rep("beta", ncol(X)), "sigma", "rho"),
      equation = lab, term = c(colnames(X), "sigma", "rho"),
      transform = c(rep("identity", ncol(X)), "log", "atanh"),
      stringsAsFactors = FALSE)
  }
  new_se_parmap(do.call(rbind, rows))
}

## Working -> natural scale (full vectors of length p).
se_par_natural <- function(map, theta_w) {
  if (length(theta_w) != map$p) {
    se_abort(sprintf("expected %d working parameters, got %d", map$p,
                     length(theta_w)), "internal")
  }
  out <- unname(theta_w)
  for (t in unique(map$elements$transform)) {
    i <- which(map$elements$transform == t)
    out[i] <- se_transform(t)$to_natural(out[i])
  }
  stats::setNames(out, map$elements$name)
}

## Natural -> working scale. theta_n is either unnamed of length p or named
## with exactly the natural parameter names (any order).
se_par_working <- function(map, theta_n) {
  theta_n <- unlist(theta_n)
  nm <- map$elements$name
  if (!is.null(names(theta_n)) && all(nzchar(names(theta_n)))) {
    miss <- setdiff(nm, names(theta_n))
    extra <- setdiff(names(theta_n), nm)
    if (length(miss) || length(extra)) {
      se_abort(paste0(
        "parameter names do not match the model",
        if (length(miss)) paste0("; missing: ", paste(miss, collapse = ", ")),
        if (length(extra)) paste0("; unknown: ", paste(extra, collapse = ", "))),
        "argument")
    }
    theta_n <- theta_n[nm]
  } else if (length(theta_n) != map$p) {
    se_abort(sprintf("expected %d parameters, got %d", map$p, length(theta_n)),
             "argument")
  }
  out <- unname(as.numeric(theta_n))
  for (t in unique(map$elements$transform)) {
    i <- which(map$elements$transform == t)
    out[i] <- se_transform(t)$to_working(out[i])
  }
  stats::setNames(out, map$elements$working_name)
}

## Diagonal of the Jacobian d natural / d working (all G1 transformations
## act element by element).
se_par_jacobian <- function(map, theta_w) {
  out <- numeric(map$p)
  for (t in unique(map$elements$transform)) {
    i <- which(map$elements$transform == t)
    out[i] <- se_transform(t)$d1(theta_w[i])
  }
  stats::setNames(out, map$elements$name)
}

## Delta method: covariance of natural parameters from the working covariance.
se_par_vcov_natural <- function(map, theta_w, V_w) {
  j <- se_par_jacobian(map, theta_w)
  V <- j * V_w * rep(j, each = length(j))
  dimnames(V) <- list(map$elements$name, map$elements$name)
  V
}

## Fix parameters at natural-scale values, e.g.
## se_par_fix(map, c("regime_0:rho" = 0, "regime_1:rho" = 0)).
se_par_fix <- function(map, values) {
  if (is.null(names(values)) || !all(names(values) %in% map$elements$name)) {
    se_abort("values to fix must be named with natural parameter names",
             "argument")
  }
  i <- match(names(values), map$elements$name)
  for (k in seq_along(i)) {
    map$fixed_value[i[k]] <-
      se_transform(map$elements$transform[i[k]])$to_working(values[[k]])
  }
  map$fixed[i] <- TRUE
  map
}

## Indices of free parameters; expand a free working vector to the full
## vector (fixed values inserted); reduce a full vector to its free part.
se_par_free <- function(map) which(!map$fixed)

se_par_expand <- function(map, theta_free) {
  free <- se_par_free(map)
  if (length(theta_free) != length(free)) {
    se_abort(sprintf("expected %d free parameters, got %d", length(free),
                     length(theta_free)), "internal")
  }
  out <- map$fixed_value
  out[free] <- theta_free
  stats::setNames(out, map$elements$working_name)
}

se_par_reduce <- function(map, theta_w) theta_w[se_par_free(map)]

#' @export
print.se_parmap <- function(x, ...) {
  e <- x$elements
  cat(sprintf("Parameter map: %d parameters (%d fixed)\n", x$p, sum(x$fixed)))
  tab <- data.frame(natural = e$name, working = e$working_name,
                    block = e$block, transform = e$transform,
                    fixed = ifelse(x$fixed, "yes", ""),
                    stringsAsFactors = FALSE)
  print(tab, row.names = FALSE)
  invisible(x)
}
