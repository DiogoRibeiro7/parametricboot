# Bootstrap engine -------------------------------------------------------------
#
# A parametric bootstrap replicate has two steps: (1) draw a new response from
# the fitted model and (2) refit the model to that response. All random numbers
# are drawn in step 1, in the calling process, so results are reproducible and
# identical whether the refits in step 2 run sequentially or in parallel.

pb_model_type <- function(model) {
  if (inherits(model, "coxph")) {
    pb_require("survival", "bootstrap 'coxph' models")
    pb_check_coxph(model)
    "coxph"
  } else if (inherits(model, "merMod")) {
    pb_require("lme4", "bootstrap 'lmer'/'glmer' models")
    "merMod"
  } else if (identical(class(model), c("negbin", "glm", "lm"))) {
    pb_require("MASS", "bootstrap negative-binomial regression models")
    pb_check_negbin(model)
    "negbin"
  } else if (identical(class(model), c("glm", "lm"))) {
    family <- stats::family(model)$family
    if (is.character(family) && length(family) == 1L &&
        grepl("^quasi", family, ignore.case = TRUE)) {
      pb_abort_validation(
        "Quasi-likelihood family '", family,
        "' is unsupported: no parametric response law or log-likelihood ",
        "is defined. Use an explicitly specified sampling model."
      )
    }
    "lm"
  } else if (identical(class(model), "lm")) {
    "lm"
  } else if (inherits(model, "lm")) {
    pb_abort_validation(
      "Unsupported lm/glm subclass '", class(model)[1L], "'. ",
      "Only standard stats::lm() and stats::glm() fits are currently ",
      "validated. Subclasses require an independently verified simulation ",
      "and refitting method before bootstrap inference."
    )
  } else {
    pb_abort(
      "`model` must be fitted with `lm()`, `glm()`, `lme4::lmer()`, ",
      "`lme4::glmer()` or `survival::coxph()`, not an object of class '",
      class(model)[1], "'."
    )
  }
}

# MASS::simulate.negbin() draws from NB(mu, theta) but does not incorporate
# prior/case weights. Repeated refitting estimates theta anew; weights beyond
# one would make the simulated sampling model inconsistent with the fitted fit.
pb_check_negbin <- function(model) {
  theta <- model$theta
  if (!is.numeric(theta) || length(theta) != 1L ||
      !is.finite(theta) || theta <= 0) {
    pb_abort_validation("MASS::glm.nb() must have a finite positive theta.")
  }
  family <- stats::family(model)$family
  if (!is.character(family) || length(family) != 1L ||
      !startsWith(family, "Negative Binomial(")) {
    pb_abort_validation("MASS::glm.nb() requires a negative-binomial sampling family.")
  }
  weights <- model$prior.weights
  if (!is.null(weights) &&
      (!is.numeric(weights) || anyNA(weights) ||
       any(!is.finite(weights)) || any(weights != 1))) {
    pb_abort_validation(paste0(
      "Weighted MASS::glm.nb() models are unsupported: ",
      "simulate.negbin() does not model non-unit prior weights."
    ))
  }
  mu <- stats::fitted(model)
  if (!is.numeric(mu) || !length(mu) ||
      any(!is.finite(mu)) || any(mu <= 0)) {
    pb_abort_validation("MASS::glm.nb() must have strictly positive finite fitted means.")
  }
  invisible(model)
}

pb_run <- function(model, n, dots, seed, keep_fits, workers, call,
                   statistic = NULL, statistic_se = NULL,
                   newdata = NULL, predict_args = list()) {
  if (!is.null(statistic) && !is.function(statistic)) {
    pb_abort_validation("`statistic` must be NULL or a function of the fitted model.")
  }
  if (!is.null(statistic_se) && (is.null(statistic) || !is.function(statistic_se))) {
    pb_abort_validation("`statistic_se` requires `statistic` and must be a function of the fitted model.")
  }
  type <- pb_model_type(model)
  n <- pb_check_count(n, "n")
  workers <- pb_check_count(workers, "workers")
  pb_check_seed(seed)
  observed <- if (is.null(statistic)) pb_coef(model) else pb_eval_statistic(statistic, model)
  observed_se <- if (is.null(statistic_se)) NULL else
    pb_eval_statistic_se(statistic_se, model, names(observed))
  if (!is.logical(keep_fits) || length(keep_fits) != 1L || is.na(keep_fits)) {
    pb_abort("`keep_fits` must be `TRUE` or `FALSE`.")
  }

  if (!is.null(newdata) &&
      (!is.data.frame(newdata) || nrow(newdata) < 1L)) {
    pb_abort_validation("`newdata` must be a non-empty data frame or NULL.")
  }
  if (!is.list(predict_args) ||
      (length(predict_args) &&
       (is.null(names(predict_args)) || anyNA(names(predict_args)) ||
        any(!nzchar(names(predict_args))) ||
        anyDuplicated(names(predict_args)) ||
        any(names(predict_args) %in% c("object", "newdata"))))) {
    pb_abort_validation("`predict_args` must be a named list of unique predict() arguments, excluding object and newdata.")
  }
  if (is.null(newdata) && length(predict_args)) {
    pb_abort_validation("`predict_args` requires `newdata`.")
  }

  aux <- if (type == "merMod") NULL else pb_refit_data(model)
  responses <- pb_with_seed(seed, pb_sim_response(model, type, n))

  out <- pb_lapply(
    responses, pb_refit_one,
    model = model, type = type, aux = aux, dots = dots, keep_fit = keep_fits,
    workers = workers, statistic = statistic, statistic_se = statistic_se,
    expected_names = names(observed),
    newdata = newdata, predict_args = predict_args
  )

  failed <- vapply(out, function(o) !is.null(o$error), logical(1))
  warned <- vapply(out, function(o) o$warned, logical(1))
  if (all(failed)) {
    pb_abort("All ", n, " bootstrap refits failed. First error: ", out[[1]]$error)
  }

  terms <- names(observed)
  estimates <- matrix(NA_real_, n, length(terms), dimnames = list(NULL, terms))
  std_errors <- estimates
  for (i in which(!failed)) {
    common <- intersect(terms, names(out[[i]]$coef))
    estimates[i, common] <- out[[i]]$coef[common]
    std_errors[i, common] <- out[[i]]$se[common]
  }

  pb_warn_replicates(failed, warned, out)

  # Prediction failures are kept separate from model refit failures so that
  # a failed predict() cannot silently discard valid coefficient estimates.
  if (!is.null(newdata)) {
    prediction_failed <- vapply(out, function(o) {
      !is.null(o$error) || !is.null(o$prediction_error)
    }, logical(1))
    if (all(prediction_failed)) {
      first <- which(vapply(out, function(o) !is.null(o$prediction_error),
                            logical(1)))
      reason <- if (length(first)) out[[first[1L]]]$prediction_error else
        out[[1L]]$error
      pb_abort("All ", n, " bootstrap predictions failed. First error: ", reason)
    }
    predictions <- matrix(NA_real_, nrow = nrow(newdata), ncol = n)
    for (i in which(!prediction_failed)) {
      predictions[, i] <- out[[i]]$prediction
    }
    prediction_only_failed <- prediction_failed & !failed
    if (any(prediction_only_failed)) {
      first <- which(prediction_only_failed)[1L]
      warning(sum(prediction_only_failed), " of ", n,
              " bootstrap predictions failed, but their fitted estimates were retained. First error: ",
              out[[first]]$prediction_error, call. = FALSE)
    }
    prediction_warned <- vapply(out, function(o) isTRUE(o$prediction_warned),
                                logical(1))
    if (any(prediction_warned)) {
      warning(sum(prediction_warned), " of ", n,
              " bootstrap predictions produced warnings.", call. = FALSE)
    }
  }

  boot <- list(
      original = model,
      statistic_estimate = if (is.null(statistic)) NULL else observed,
      statistic_function = statistic,
      replicates = if (keep_fits) lapply(out, function(o) o$fit),
      estimates = estimates,
      std_errors = std_errors,
      n = n,
      failed = failed,
      warned = warned,
      seed = seed,
      call = call
  )
  # Do not modify the legacy result layout when no callback was supplied.
  if (!is.null(statistic_se)) boot$statistic_se_estimate <- observed_se
  if (!is.null(newdata)) {
    boot$predictions <- predictions
    boot$prediction_data <- newdata
    boot$prediction_args <- predict_args
    boot$prediction_failed <- prediction_failed
  }
  structure(boot, class = "pb_boot")
}

# Run `fun` over `x`, on a local cluster if `workers > 1`. The workers are fresh
# R sessions, so they must be able to load the installed package.
pb_lapply <- function(x, fun, ..., workers = 1L) {
  if (workers <= 1L) {
    return(lapply(x, fun, ...))
  }
  cl <- parallel::makeCluster(workers)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  loaded <- unlist(parallel::clusterCall(cl, requireNamespace, "parametricboot", quietly = TRUE))
  if (!all(loaded)) {
    pb_abort("Parallel workers could not load 'parametricboot'. Is the package installed?")
  }
  parallel::parLapply(cl, x, fun, ...)
}

# Evaluate `fun()`, capturing an error and recording (but muffling) warnings,
# so that a single bad replicate never aborts the whole bootstrap. Messages,
# such as the "boundary (singular) fit" note of 'lme4', are muffled too: they
# are informative for one fit but only noise when repeated for every replicate.
pb_safely <- function(fun) {
  warned <- FALSE
  value <- tryCatch(
    withCallingHandlers(
      fun(),
      warning = function(w) {
        warned <<- TRUE
        invokeRestart("muffleWarning")
      },
      message = function(m) {
        invokeRestart("muffleMessage")
      }
    ),
    error = function(e) e
  )
  if (inherits(value, "error")) {
    return(list(value = NULL, warned = warned, error = conditionMessage(value)))
  }
  list(value = value, warned = warned, error = NULL)
}

# One warning for the replicates that failed and one for those that warned.
# `out` is the list of per-replicate results, each with an `error` element.
pb_warn_replicates <- function(failed, warned, out) {
  n <- length(failed)
  if (any(failed)) {
    errors <- unlist(lapply(out[failed], function(o) o$error))
    warning(
      sum(failed), " of ", n, " bootstrap refits failed and were dropped. First error: ",
      errors[1],
      call. = FALSE
    )
  }
  if (any(warned)) {
    warning(
      sum(warned), " of ", n, " bootstrap refits produced warnings ",
      "(for example convergence problems).",
      call. = FALSE
    )
  }
  invisible(NULL)
}

# Refit to one simulated response and extract what the summaries need.
pb_refit_one <- function(response, model, type, aux, dots, keep_fit,
                         statistic = NULL, statistic_se = NULL,
                         expected_names = NULL, newdata = NULL,
                         predict_args = list()) {
  out <- pb_safely(function() {
    fit <- pb_refit(model, type, response, aux, dots)
    coef <- if (is.null(statistic)) pb_coef(fit) else pb_eval_statistic(statistic, fit, expected_names)
    se <- if (is.null(statistic)) {
      pb_se(fit)
    } else if (is.null(statistic_se)) {
      stats::setNames(rep(NA_real_, length(coef)), names(coef))
    } else {
      pb_eval_statistic_se(statistic_se, fit, expected_names)
    }
    prediction <- if (is.null(newdata)) NULL else {
      pb_safely(function() pb_predict_one(fit, newdata, predict_args))
    }
    list(coef = coef, se = se, fit = if (keep_fit) fit,
         prediction = prediction)
  })
  list(
    coef = out$value$coef,
    se = out$value$se,
    fit = out$value$fit,
    warned = out$warned,
    error = out$error,
    prediction = out$value$prediction$value,
    prediction_error = out$value$prediction$error,
    prediction_warned = isTRUE(out$value$prediction$warned)
  )
}

# Step 1: simulate responses ---------------------------------------------------

pb_sim_response <- function(model, type, nsim) {
  if (type == "coxph") {
    return(pb_sim_coxph(model, nsim))
  }
  sims <- stats::simulate(model, nsim = nsim)
  lapply(seq_len(nsim), function(i) sims[[i]])
}

pb_check_coxph <- function(model) {
  y <- model[["y"]]
  if (is.null(y)) {
    pb_abort("The 'coxph' model must be fitted with `y = TRUE` (the default).")
  }
  if (!identical(attr(y, "type"), "right")) {
    pb_abort("Only right-censored `Surv(time, status)` responses are supported for 'coxph' models.")
  }
  specials <- attr(model$terms, "specials")
  if (inherits(model, "coxph.penal") || length(specials$tt) > 0L) {
    pb_abort("'coxph' models with `tt()`, `frailty()` or penalised terms are not supported.")
  }
  labels <- attr(model$terms, "term.labels")
  if (any(grepl("strata(", labels, fixed = TRUE) & grepl(":", labels, fixed = TRUE))) {
    pb_abort(
      "'coxph' models with strata-by-covariate interactions are not supported, ",
      "because they have no single baseline hazard per stratum."
    )
  }
  if (!is.null(stats::getCall(model)$cluster) || length(specials$cluster) > 0L) {
    pb_abort(
      "'coxph' models with `cluster()` are not supported: the observations are ",
      "resampled independently, which ignores the clustering."
    )
  }
  if (!is.null(model[["weights"]])) {
    pb_abort("Weighted 'coxph' models are not supported.")
  }
  invisible(model)
}

# Model-based resampling for the proportional hazards model (Davison & Hinkley
# 1997, Algorithm 7.3). Failure times are drawn from the fitted survivor
# function, built from the Breslow baseline hazard. Censoring times are kept for
# censored subjects and drawn from the Kaplan-Meier estimate of the censoring
# distribution, conditional on exceeding the observed time, for the others.
# In a stratified model each stratum has its own baseline hazard, censoring
# distribution and end of follow-up.
pb_sim_coxph <- function(model, nsim) {
  y <- model[["y"]]
  time <- as.numeric(y[, 1])
  status <- as.numeric(y[, 2])
  risk <- exp(model$linear.predictors)
  base <- pb_coxph_basehaz(model)

  strata <- pb_coxph_strata(model)
  if (is.null(strata)) {
    groups <- list(seq_along(time))
    hazards <- list(base)
  } else {
    groups <- split(seq_along(time), strata)
    if (!all(names(groups) %in% levels(base$strata))) {
      pb_abort("Could not match the strata of the 'coxph' model to its baseline hazards.")
    }
    hazards <- lapply(names(groups), function(s) base[base$strata == s, , drop = FALSE])
  }
  samplers <- lapply(seq_along(groups), function(g) {
    rows <- groups[[g]]
    pb_coxph_sampler(time[rows], status[rows], risk[rows], hazards[[g]])
  })

  lapply(seq_len(nsim), function(i) {
    out <- cbind(time = time, status = status)
    for (g in seq_along(groups)) {
      out[groups[[g]], ] <- samplers[[g]]()
    }
    out
  })
}

# Work around an R-devel stats::delete.response() regression affecting
# survival::basehaz() for Cox fits with no actual special terms. Do not
# change terms with strata or other specials: their semantics are essential.
pb_coxph_basehaz <- function(model) {
  tryCatch(
    survival::basehaz(model, centered = TRUE),
    error = function(e) {
      special <- attr(model$terms, "specials")
      # R-devel can represent the specials attribute as a pairlist.
      # Only strip it when every recorded special is empty.
      entries <- if (is.pairlist(special)) as.list(special) else special
      empty_specials <- is.null(entries) ||
        (is.list(entries) && all(lengths(entries) == 0L))
      if (!identical(conditionMessage(e), "subscript out of bounds") ||
          !empty_specials) {
        stop(e)
      }
      # An unstratified model has no meaningful specials to delete.
      clean <- model
      attr(clean$terms, "specials") <- NULL
      survival::basehaz(clean, centered = TRUE)
    }
  )
}

# The stratum of each observation used in the fit, recovered from the model
# frame exactly as `coxph()` builds it, or `NULL` for an unstratified model.
pb_coxph_strata <- function(model) {
  vars <- survival::untangle.specials(model$terms, "strata")$vars
  if (length(vars) == 0L) {
    return(NULL)
  }
  frame <- stats::model.frame(model)
  strata <- if (length(vars) == 1L) {
    frame[[vars]]
  } else {
    survival::strata(frame[, vars], shortlabel = TRUE)
  }
  droplevels(as.factor(strata))
}

# A function that draws one bootstrap sample of (time, status) for a group of
# subjects sharing the baseline hazard `base`.
pb_coxph_sampler <- function(time, status, risk, base) {
  n_obs <- length(time)
  t_max <- max(time)
  events <- status == 1
  cens <- survival::survfit(survival::Surv(time, 1 - status) ~ 1)
  g_at_y <- c(1, cens$surv)[findInterval(time, cens$time) + 1L]

  function() {
    target <- stats::rexp(n_obs) / risk
    k <- findInterval(target, base$hazard, left.open = TRUE) + 1L
    fail <- base$time[k]
    fail[is.na(fail)] <- Inf

    censor <- time
    g <- stats::runif(sum(events)) * g_at_y[events]
    k <- findInterval(-g, -cens$surv, left.open = TRUE) + 1L
    drawn <- cens$time[k]
    drawn[is.na(drawn)] <- Inf
    censor[events] <- drawn

    cbind(
      time = pmin(fail, censor, t_max),
      status = as.numeric(fail <= censor & is.finite(fail))
    )
  }
}

# Step 2: refit ----------------------------------------------------------------

# Data used to refit call-based models, and the rows of it that the original
# fit actually used (after `subset` and `na.action`).
pb_refit_data <- function(model) {
  data <- model[["data"]]
  if (!is.data.frame(data)) {
    expr <- stats::getCall(model)$data
    data <- if (!is.null(expr)) eval(expr, environment(stats::formula(model)))
  }
  if (!is.data.frame(data)) {
    pb_abort("`model` must be fitted with a `data` argument so that it can be refitted.")
  }
  data <- as.data.frame(data)
  rows <- match(rownames(stats::model.frame(model)), rownames(data))
  if (anyNA(rows)) {
    pb_abort(
      "Could not match the rows used by `model` to its `data`. ",
      "Was `data` modified after fitting?"
    )
  }
  list(data = data, rows = rows)
}

# Expand a response over the rows used in the fit to all rows of the data.
pb_fill <- function(response, rows, n) {
  if (is.matrix(response)) {
    out <- response[rep(NA_integer_, n), , drop = FALSE]
    out[rows, ] <- response
    rownames(out) <- NULL
  } else {
    out <- response[rep(NA_integer_, n)]
    out[rows] <- response
    names(out) <- NULL
  }
  out
}

pb_refit <- function(model, type, response, aux, dots) {
  if (type == "merMod") {
    return(do.call(lme4::refit, c(list(model, newresp = response), dots)))
  }

  data <- aux$data
  call <- stats::getCall(model)
  if (type == "coxph") {
    data[[".pb_time"]] <- pb_fill(response[, "time"], aux$rows, nrow(data))
    data[[".pb_status"]] <- pb_fill(response[, "status"], aux$rows, nrow(data))
    new_formula <- survival::Surv(.pb_time, .pb_status) ~ .
    call[[1]] <- quote(survival::coxph)
  } else {
    data[[".pb_y"]] <- pb_fill(response, aux$rows, nrow(data))
    new_formula <- .pb_y ~ .
    if (type == "negbin") {
      # Saved calls may use an unqualified glm.nb() even when MASS is not
      # attached in the calling session. Always dispatch to its namespace.
      call[[1L]] <- quote(MASS::glm.nb)
    }
  }

  # Refit by re-evaluating the original call with the simulated response in
  # place. Working from the original data (not the model frame) keeps terms
  # such as `log(x)`, `poly(x, 2)` or `offset()` valid.
  call$formula <- stats::update(stats::formula(model), new_formula)
  call$data <- quote(.pb_data)
  for (arg in names(dots)) {
    call[[arg]] <- dots[[arg]]
  }
  env <- new.env(parent = environment(stats::formula(model)))
  assign(".pb_data", data, envir = env)
  eval(call, env)
}
