## Layer 4: optimisation infrastructure (NUMERICAL_METHODS.md s.3).
## The estimation engine is not tied to one optimiser: Newton-Raphson
## (maxLik::maxNR, analytic gradient and Hessian) is primary; BFGS
## (maxLik::maxBFGS), BHHH (maxLik::maxBHHH) and stats::optim (BFGS) are
## fallbacks, each followed by a Newton-Raphson polish. Convergence is judged
## by our own criteria, not by the optimiser's return code.
##
## Newton-Raphson uses Marquardt's correction of non-concave steps
## (qac = "marquardt") and stops when the log-likelihood changes by less than
## 1e-12. With maxNR's default step halving, a replication of the WP1.4
## Monte Carlo smoke test (cell 2, replication 40) reached the optimum in 8
## iterations and then stalled until the iteration limit (500 iterations,
## 13 347 function evaluations, 91 s); with Marquardt's correction the same
## fit needs 4 iterations (progress note WP1.4).

## Objective on the free working parameters, with a one-point cache so that
## function, gradient and Hessian at the same point cost one evaluation.
## Newton-Raphson asks for the gradient and then the Hessian at each accepted
## point, so its gradient (gr2) evaluates both at once; other optimisers use
## gr (gradient only).
se_objective <- function(sd, map) {
  cache <- new.env(parent = emptyenv())
  free <- se_par_free(map)
  om <- sd$weights %||% rep(1, sd$n)
  alpha_pos <- match(unlist(map$index$rho), free)
  alpha_pos <- alpha_pos[!is.na(alpha_pos)]
  eval_at <- function(tf, deriv) {
    tf <- unname(tf)
    if (!is.null(cache$tf) && identical(cache$tf, tf) && cache$deriv >= deriv) {
      return(cache$val)
    }
    val <- loglik_switch(se_par_expand(map, tf), sd, map, deriv = deriv)
    cache$tf <- tf; cache$deriv <- deriv; cache$val <- val
    val
  }
  list(
    free = free,
    fn = function(tf) {
      v <- eval_at(tf, 0L)$loglik
      if (is.finite(v)) v else NA_real_
    },
    gr = function(tf) unname(eval_at(tf, 1L)$gradient[free]),
    gr2 = function(tf) unname(eval_at(tf, 2L)$gradient[free]),
    hs = function(tf) unname(eval_at(tf, 2L)$hessian[free, free, drop = FALSE]),
    ## TRUE when a correlation is within 1e-6 of +-1 (working |alpha| > 7.25);
    ## for correlations mapped onto a unit ball (map$groups, the
    ## normal-score model): when sqrt(1 - sum r^2) = 1/sqrt(1 + |a|^2) of a
    ## group is below 0.09 (sum r^2 > 0.9919)
    at_boundary = function(tf) {
      if (!is.null(map$groups)) {
        th <- se_par_expand(map, tf)
        return(any(vapply(map$groups, function(g)
          1 / sqrt(1 + sum(th[g]^2)) < 0.09, logical(1))))
      }
      length(alpha_pos) > 0L && any(abs(tanh(tf[alpha_pos])) > 1 - 1e-6)
    },
    fn_i = function(tf) om * eval_at(tf, 0L)$ll_i,
    gr_i = function(tf) {
      unname((om * eval_at(tf, 1L)$score_i)[, free, drop = FALSE])
    },
    eval_at = eval_at,
    ## engines whose Hessian is a difference of scores (costly): no
    ## Newton-Raphson iterations, see se_optimize()
    costly_hessian = isTRUE(map$costly_hessian),
    ## the same log-likelihood and score with a coarser integration rule,
    ## for the first stage of se_optimize_costly()
    coarse = if (isTRUE(map$costly_hessian) && !is.null(map$nodes_coarse)) {
      map_c <- map
      map_c$nodes <- map$nodes_coarse
      cc <- new.env(parent = emptyenv())
      ev <- function(tf, deriv) {
        tf <- unname(tf)
        if (!is.null(cc$tf) && identical(cc$tf, tf) && cc$deriv >= deriv) {
          return(cc$val)
        }
        val <- loglik_switch(se_par_expand(map_c, tf), sd, map_c, deriv = deriv)
        cc$tf <- tf; cc$deriv <- deriv; cc$val <- val
        val
      }
      list(fn = function(tf) {
             v <- ev(tf, 0L)$loglik
             if (is.finite(v)) v else NA_real_
           },
           gr = function(tf) unname(ev(tf, 1L)$gradient[free]))
    })
}

se_run_optimizer <- function(method, obj, start, control) {
  start <- unname(start)
  gt <- control$gradient_tolerance / 10
  out <- switch(method,
    NR = {
      r <- maxLik::maxNR(obj$fn, obj$gr2, obj$hs, start = start,
                         finalHessian = FALSE,
                         control = list(tol = 1e-12, reltol = 0, gradtol = gt,
                                        iterlim = control$maxit,
                                        qac = "marquardt", printLevel = 0))
      list(estimate = r$estimate, maximum = r$maximum, code = r$code,
           message = r$message, iterations = r$iterations)
    },
    BFGS = {
      r <- maxLik::maxBFGS(obj$fn, obj$gr, start = start, finalHessian = FALSE,
                           control = list(iterlim = 4L * control$maxit,
                                          reltol = 1e-12, printLevel = 0))
      list(estimate = r$estimate, maximum = r$maximum, code = r$code,
           message = r$message, iterations = r$iterations)
    },
    BHHH = {
      r <- maxLik::maxBHHH(obj$fn_i, obj$gr_i, start = start,
                           finalHessian = FALSE,
                           control = list(tol = 1e-12, reltol = 0, gradtol = gt,
                                          iterlim = control$maxit,
                                          printLevel = 0))
      list(estimate = r$estimate, maximum = r$maximum, code = r$code,
           message = r$message, iterations = r$iterations)
    },
    optim = {
      f <- function(t) { v <- obj$fn(t); if (is.na(v)) 1e300 else -v }
      r <- stats::optim(start, f, function(t) -obj$gr(t), method = "BFGS",
                        control = list(maxit = 4L * control$maxit,
                                       reltol = 1e-12))
      list(estimate = r$par, maximum = -r$value, code = r$convergence,
           message = r$message %||% "", iterations = r$counts[[1L]])
    })
  out$method <- method
  out
}

## Convergence check at a point (NUMERICAL_METHODS.md s.3).
se_check_optimum <- function(obj, tf, control) {
  ll <- obj$fn(tf)
  if (!is.finite(ll)) {
    return(list(loglik = ll, gradient_max = NA_real_, gradient_norm = NA_real_,
                eigen = NA_real_, negative_definite = FALSE,
                condition = NA_real_, code = 3L))
  }
  g <- obj$gr(tf)
  H <- obj$hs(tf)
  ev <- if (all(is.finite(H))) {
    eigen((H + t(H)) / 2, symmetric = TRUE, only.values = TRUE)$values
  } else NA_real_
  nd <- all(is.finite(ev)) && all(ev < 0)
  gmax <- max(abs(g))
  code <- if (!is.finite(gmax) || gmax >= control$gradient_tolerance) 1L
          else if (!nd) 2L else 0L
  list(loglik = ll, gradient_max = gmax, gradient_norm = sqrt(sum(g^2)),
       eigen = ev, negative_definite = nd,
       condition = if (all(is.finite(ev))) max(abs(ev)) / min(abs(ev)) else NA,
       code = code)
}

## Optimise from one start: primary optimiser, then fallbacks (each from the
## original start, polished by Newton-Raphson) until the convergence check
## passes. Returns the best result with its check and the optimiser path.
##
## Boundary stop: when a run ends with a correlation within 1e-6 of +-1, the
## log-likelihood is increasing towards the boundary and the fallbacks climb
## to the same boundary. They are then skipped for this start (the fit
## still reports non-convergence and the boundary flag; other starts still
## run). Without this, a misspecified example of the sampleSelection
## vignette (WP1.8 benchmark D6b) took 51-82 s, running every fallback from
## every start to the same boundary value (BENCHMARK_G1.md s.4.2).
se_optimize <- function(obj, start, control) {
  if (isTRUE(obj$costly_hessian)) return(se_optimize_costly(obj, start, control))
  methods <- unique(c(control$optimizer, "NR", "BFGS", "BHHH", "optim"))
  path <- character()
  best <- NULL
  for (m in methods) {
    res <- tryCatch(se_run_optimizer(m, obj, start, control),
                    error = function(e) NULL)
    path <- c(path, m)
    if (is.null(res) || !all(is.finite(res$estimate))) next
    if (m != "NR") {
      pol <- tryCatch(se_run_optimizer("NR", obj, res$estimate, control),
                      error = function(e) NULL)
      if (!is.null(pol) && all(is.finite(pol$estimate)) &&
          is.finite(pol$maximum) && pol$maximum >= res$maximum - 1e-8) {
        pol$iterations <- res$iterations + pol$iterations
        pol$method <- paste0(m, "+NR")
        res <- pol
        path <- c(path, "NR")
      }
    }
    res$check <- se_check_optimum(obj, res$estimate, control)
    better <- is.null(best) ||
      (res$check$code < best$check$code) ||
      (res$check$code == best$check$code &&
         isTRUE(res$check$loglik > best$check$loglik))
    if (better) best <- res
    if (res$check$code == 0L) break
    if (isTRUE(obj$at_boundary(res$estimate))) {
      path <- c(path, "boundary-stop")
      break
    }
  }
  if (is.null(best)) {
    best <- list(estimate = start, maximum = NA_real_, method = "none",
                 iterations = 0L, message = "all optimisers failed",
                 check = se_check_optimum(obj, start, control))
    best$check$code <- 4L
  }
  best$path <- path
  best
}

## Optimisation for engines without an analytic Hessian (the normal-score
## model). Newton-Raphson iterations are not used because every Hessian
## costs as many score evaluations as there are parameters.
##   Stage 1: BFGS (stats::optim) on the score, with the coarse integration
##     rule when the objective provides one. Points at the boundary
##     (obj$at_boundary) are rejected by the line search, so the search
##     stays where the integration rule is accurate and affordable; a run
##     that ends against this barrier is reported as not converged, with
##     the boundary flag.
##   Stage 2: at most three Newton steps with one differenced Hessian of
##     the accurate log-likelihood, each kept only if it does not lower it.
se_optimize_costly <- function(obj, start, control) {
  start <- unname(start)
  o1 <- obj$coarse %||% obj
  barrier <- function(t) {
    if (isTRUE(obj$at_boundary(t))) return(1e300)
    v <- o1$fn(t)
    if (is.na(v)) 1e300 else -v
  }
  path <- "BFGS"
  r <- tryCatch(stats::optim(start, barrier, function(t) -o1$gr(t),
                             method = "BFGS",
                             control = list(maxit = 4L * control$maxit,
                                            reltol = 1e-12)),
                error = function(e) NULL)
  if (is.null(r) || !all(is.finite(r$par))) {
    best <- list(estimate = start, maximum = NA_real_, method = "none",
                 iterations = 0L, message = "all optimisers failed",
                 check = se_check_optimum(obj, start, control))
    best$check$code <- 4L
    best$path <- path
    return(best)
  }
  res <- list(estimate = r$par, maximum = obj$fn(r$par), code = r$convergence,
              message = r$message %||% "", iterations = r$counts[[1L]],
              method = "BFGS")
  g <- obj$gr(res$estimate)
  near <- function(t) {
    ## within reach of the barrier: no Newton steps (they would be taken
    ## across it)
    isTRUE(obj$at_boundary(t * 1.15))
  }
  if (is.finite(max(abs(g))) && max(abs(g)) >= control$gradient_tolerance &&
      !near(res$estimate)) {
    H <- tryCatch(obj$hs(res$estimate), error = function(e) NULL)
    if (!is.null(H) && all(is.finite(H))) {
      tf <- res$estimate
      for (it in 1:3) {
        step <- tryCatch(solve(H, g), error = function(e) NULL)
        if (is.null(step) || !all(is.finite(step))) break
        new <- tf - step
        if (isTRUE(obj$at_boundary(new))) break
        vn <- obj$fn(new)
        if (!is.finite(vn) || vn < obj$fn(tf) - 1e-10) break
        tf <- new
        g <- obj$gr(tf)
        if (max(abs(g)) < control$gradient_tolerance) break
      }
      res$estimate <- tf
      res$maximum <- obj$fn(tf)
      res$method <- "BFGS+Newton step"
      path <- c(path, "Newton step")
    }
  }
  if (near(res$estimate)) {
    ## no differenced Hessian at the boundary: it is costly there and the
    ## fit is reported as not converged whatever its value
    gmax <- max(abs(g))
    res$check <- list(loglik = res$maximum, gradient_max = gmax,
                      gradient_norm = sqrt(sum(g^2)), eigen = NA_real_,
                      negative_definite = FALSE, condition = NA, code = 1L)
    path <- c(path, "boundary-stop")
  } else {
    res$check <- se_check_optimum(obj, res$estimate, control)
  }
  res$path <- path
  res
}
