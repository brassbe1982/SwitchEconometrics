## Layer 2: the Gaussian margin.
## Natural parameters: location (mu, identity) and scale (sigma > 0, working
## value tau = log sigma). With e = (x - mu) / sigma:
##   d log f / d mu = e / sigma,            d log f / d tau = e^2 - 1,
##   d log Phi(e) / d mu = -lambda(e) / sigma,
##   d log Phi(e) / d tau = -e lambda(e),
##   d log{1 - Phi(e)} / d mu = lambda(-e) / sigma,
##   d log{1 - Phi(e)} / d tau = e lambda(-e),
## with lambda the inverse Mills ratio (lik_utils.R).

se_margin_gaussian <- function() {
  wn <- c("location", "log(scale)")
  new_se_margin(
    name = "gaussian", type = "continuous",
    parameters = data.frame(
      name = c("location", "scale"), transform = c("identity", "log"),
      default = c(0, 1),
      description = c("mean", "standard deviation"),
      stringsAsFactors = FALSE),
    d = function(x, par) stats::dnorm(x, par$location, par$scale),
    p = function(q, par, lower.tail = TRUE)
      stats::pnorm(q, par$location, par$scale, lower.tail = lower.tail),
    q = function(p, par) stats::qnorm(p, par$location, par$scale),
    r = function(n, par) stats::rnorm(n, par$location, par$scale),
    logd = function(x, par)
      stats::dnorm(x, par$location, par$scale, log = TRUE),
    logp = function(q, par, lower.tail = TRUE)
      stats::pnorm(q, par$location, par$scale, lower.tail = lower.tail,
                   log.p = TRUE),
    grad_logd = function(x, par) {
      s <- par$scale
      e <- (x - par$location) / s
      g <- cbind(e / s, e^2 - 1)
      colnames(g) <- wn
      g
    },
    grad_logp = function(q, par, lower.tail = TRUE) {
      s <- par$scale
      e <- (q - par$location) / s
      g <- if (lower.tail) {
        l <- se_mills(e)
        cbind(-l / s, -e * l)
      } else {
        l <- se_mills(-e)
        cbind(l / s, e * l)
      }
      colnames(g) <- wn
      g
    },
    support = c(-Inf, Inf), generation = 1L)
}
