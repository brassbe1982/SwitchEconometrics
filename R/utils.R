## Internal utilities: classed conditions, random-number handling, helpers.
## Conventions: 02_Computational_Architecture/API_SPECIFICATION.md, section 1.

`%||%` <- function(a, b) if (is.null(a)) b else a

## Build a condition object of class
## c("switch_<type>_<class>", "switch_<type>", <type>, "condition").
se_condition <- function(type, message, class = NULL, call = NULL,
                         data = list()) {
  cls <- c(if (!is.null(class)) paste0("switch_", type, "_", class),
           paste0("switch_", type), type, "condition")
  structure(c(list(message = message, call = call), data), class = cls)
}

## Signal a classed error, e.g. se_abort("...", "data") gives class
## "switch_error_data".
se_abort <- function(message, class = NULL, call = NULL, ...) {
  stop(se_condition("error", message, class, call, list(...)))
}

se_warn <- function(message, class = NULL, call = NULL, ...) {
  warning(se_condition("warning", message, class, call, list(...)))
}

se_inform <- function(message, class = NULL, ...) {
  message(se_condition("message", paste0(message, "\n"), class, NULL,
                       list(...)))
}

## Evaluate `expr` with a given seed and restore the global random-number
## state afterwards. With seed = NULL the expression is evaluated unchanged.
se_with_seed <- function(seed, expr) {
  if (is.null(seed)) return(expr)
  genv <- globalenv()
  had <- exists(".Random.seed", envir = genv, inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = genv, inherits = FALSE)
  on.exit({
    if (had) {
      assign(".Random.seed", old, envir = genv)
    } else if (exists(".Random.seed", envir = genv, inherits = FALSE)) {
      rm(".Random.seed", envir = genv)
    }
  })
  set.seed(seed)
  expr
}

## One-line text of a formula.
se_deparse <- function(f) paste(deparse(f, width.cutoff = 500L), collapse = " ")

## Check that x is a single non-missing character string.
se_check_string <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    se_abort(sprintf("'%s' must be a single character string", name),
             "argument")
  }
  invisible(x)
}

se_version <- function() as.character(getNamespaceVersion("SwitchEconometrics"))
