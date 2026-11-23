## Layer 4: full-information maximum likelihood with multistart
## (LIKELIHOOD_DERIVATION.md s.10; PARAMETERIZATION.md s.4-5;
## NUMERICAL_METHODS.md s.3).

## Matrix of starting values on the free working scale (one row per start)
## with their origins. start_w: full working vector of the first start.
## se_scale: standard errors (working scale, full length) used to scale the
## perturbations of the coefficient blocks; NA entries fall back to
## 0.1 * (|value| + 1).
se_fiml_starts <- function(map, start_list, se_scale, control) {
  free <- se_par_free(map)
  base <- start_list[[1L]]$theta
  rows <- lapply(start_list, function(s) unname(s$theta[free]))
  origin <- vapply(start_list, function(s) s$origin, character(1))
  n_more <- control$starts - length(rows)
  if (n_more > 0L) {
    coef_blk <- map$elements$block %in% c("gamma", "beta", "delta")
    sc <- ifelse(coef_blk, se_scale, 1)
    bad <- !is.finite(sc) | sc <= 0
    sc[bad] <- 0.1 * (abs(base[bad]) + 1)
    sc <- sc * control$perturb_sd
    rho_i <- unlist(map$index$rho)
    grid <- if (control$starts >= 10L && length(rho_i) == 2L) {
      as.matrix(expand.grid(a1 = c(-1, 0, 1), a2 = c(-1, 0, 1)))
    } else matrix(numeric(0), 0, 2)
    extra <- se_with_seed(control$seed, lapply(seq_len(n_more), function(k) {
      th <- base
      if (k <= nrow(grid)) {
        th[rho_i] <- grid[k, ]
        list(theta = th, origin = sprintf("grid(%g,%g)", grid[k, 1], grid[k, 2]))
      } else {
        th <- base + stats::rnorm(length(base)) * sc
        list(theta = th, origin = "perturbed")
      }
    }))
    rows <- c(rows, lapply(extra, function(s) unname(s$theta[free])))
    origin <- c(origin, vapply(extra, function(s) s$origin, character(1)))
  }
  list(theta = do.call(rbind, rows), origin = origin)
}

## FIML. start_list: list of list(theta = full working vector, origin = ...).
est_fiml <- function(sd, map, start_list, se_scale, control,
                     vcov_type = "hessian") {
  t0 <- proc.time()[["elapsed"]]
  obj <- se_objective(sd, map)
  st <- se_fiml_starts(map, start_list, se_scale, control)
  runs <- lapply(seq_len(nrow(st$theta)), function(k)
    se_optimize(obj, st$theta[k, ], control))
  ll <- vapply(runs, function(r) r$check$loglik, numeric(1))
  code <- vapply(runs, function(r) r$check$code, integer(1))
  ok <- code == 0L & is.finite(ll)
  pick <- if (any(ok)) which(ok)[which.max(ll[ok])]
          else if (any(is.finite(ll))) which.max(ifelse(is.finite(ll), ll, -Inf))
          else 1L
  best <- runs[[pick]]
  tf <- best$estimate
  th_w <- se_par_expand(map, tf)
  th_n <- se_par_natural(map, th_w)

  ## agreement among starts (natural scale, free parameters)
  free <- obj$free
  nat_free <- function(r) se_par_natural(map, se_par_expand(map, r$estimate))[free]
  dpar <- vapply(runs, function(r)
    if (all(is.finite(r$estimate))) max(abs(nat_free(r) - th_n[free])) else NA_real_,
    numeric(1))
  starts <- data.frame(
    start = seq_along(runs), origin = st$origin, loglik = ll, code = code,
    iterations = vapply(runs, function(r) as.integer(r$iterations %||% NA),
                        integer(1)),
    optimizer = vapply(runs, function(r) r$method %||% "none", character(1)),
    max_abs_diff = dpar, best = seq_along(runs) == pick,
    stringsAsFactors = FALSE)
  same_ll <- ok & abs(ll - ll[pick]) < 1e-6
  flat <- any(same_ll & dpar > 1e-3, na.rm = TRUE)
  local_max <- sum(ok & ll < ll[pick] - 1e-6)

  ## covariance at the optimum
  val <- obj$eval_at(tf, 2L)
  H <- val$hessian[free, free, drop = FALSE]
  Vf <- inf_vcov_fiml(vcov_type, H, val$score_i[, free, drop = FALSE],
                      sd$weights, sd$cluster)
  Vw <- matrix(0, map$p, map$p,
               dimnames = list(map$elements$working_name,
                               map$elements$working_name))
  Vw[free, free] <- Vf
  Vn <- se_par_vcov_natural(map, th_w, Vw)

  list(method = "fiml", coefficients = th_n, coef_working = th_w,
       vcov = Vn, vcov_working = Vw, vcov_type = vcov_type,
       loglik = ll[pick],
       convergence = list(
         code = best$check$code,
         message = c("converged", "gradient not below tolerance",
                     "Hessian not negative definite", "non-finite log-likelihood",
                     "all optimisers failed")[best$check$code + 1L],
         iterations = as.integer(best$iterations %||% NA),
         gradient_max = best$check$gradient_max,
         gradient_norm = best$check$gradient_norm,
         optimizer = best$method %||% "none", path = best$path,
         time = proc.time()[["elapsed"]] - t0),
       hessian_eigen = best$check$eigen,
       hessian_condition = best$check$condition,
       starts = starts, multistart_flat = flat, local_maxima = local_max,
       score_i = val$score_i, hessian = val$hessian)
}
