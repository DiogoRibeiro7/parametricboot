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
  } else if (inherits(model, "lm")) {
    "lm"
  } else {
    pb_abort(
      "`model` must be fitted with `lm()`, `glm()`, `lme4::lmer()`, ",
      "`lme4::glmer()` or `survival::coxph()`, not an object of class '",
      class(model)[1], "'."
    )
  }
}

pb_run <- function(model, n, dots, seed, keep_fits, workers, call) {
  type <- pb_model_type(model)
  n <- pb_check_count(n, "n")
  workers <- pb_check_count(workers, "workers")
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L || is.na(seed))) {
    pb_abort("`seed` must be `NULL` or a single number.")
  }
  if (!is.logical(keep_fits) || length(keep_fits) != 1L || is.na(keep_fits)) {
    pb_abort("`keep_fits` must be `TRUE` or `FALSE`.")
  }

  aux <- if (type == "merMod") NULL else pb_refit_data(model)
  responses <- pb_with_seed(seed, pb_sim_response(model, type, n))

  if (workers > 1L) {
    cl <- parallel::makeCluster(workers)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    loaded <- unlist(parallel::clusterCall(cl, requireNamespace, "parametricboot", quietly = TRUE))
    if (!all(loaded)) {
      pb_abort("Parallel workers could not load 'parametricboot'. Is the package installed?")
    }
    out <- parallel::parLapply(
      cl, responses, pb_refit_one,
      model = model, type = type, aux = aux, dots = dots, keep_fit = keep_fits
    )
  } else {
    out <- lapply(
      responses, pb_refit_one,
      model = model, type = type, aux = aux, dots = dots, keep_fit = keep_fits
    )
  }

  failed <- vapply(out, function(o) !is.null(o$error), logical(1))
  warned <- vapply(out, function(o) o$warned, logical(1))
  if (all(failed)) {
    pb_abort("All ", n, " bootstrap refits failed. First error: ", out[[1]]$error)
  }

  terms <- names(pb_coef(model))
  estimates <- matrix(NA_real_, n, length(terms), dimnames = list(NULL, terms))
  std_errors <- estimates
  for (i in which(!failed)) {
    common <- intersect(terms, names(out[[i]]$coef))
    estimates[i, common] <- out[[i]]$coef[common]
    std_errors[i, common] <- out[[i]]$se[common]
  }

  if (any(failed)) {
    warning(
      sum(failed), " of ", n, " bootstrap refits failed and were dropped. First error: ",
      out[[which(failed)[1]]]$error,
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

  structure(
    list(
      original = model,
      replicates = if (keep_fits) lapply(out, function(o) o$fit),
      estimates = estimates,
      std_errors = std_errors,
      n = n,
      failed = failed,
      warned = warned,
      seed = seed,
      call = call
    ),
    class = "pb_boot"
  )
}

# Refit to one simulated response, capturing errors and warnings so that a
# single bad replicate never aborts the whole bootstrap.
pb_refit_one <- function(response, model, type, aux, dots, keep_fit) {
  warned <- FALSE
  fit <- tryCatch(
    withCallingHandlers(
      pb_refit(model, type, response, aux, dots),
      warning = function(w) {
        warned <<- TRUE
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(list(coef = NULL, se = NULL, fit = NULL, warned = warned, error = conditionMessage(fit)))
  }
  list(
    coef = pb_coef(fit),
    se = pb_se(fit),
    fit = if (keep_fit) fit,
    warned = warned,
    error = NULL
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
  if (inherits(model, "coxph.penal") || length(specials$strata) > 0L || length(specials$tt) > 0L) {
    pb_abort(
      "'coxph' models with `strata()`, `tt()`, `frailty()` or penalised terms ",
      "are not supported."
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
pb_sim_coxph <- function(model, nsim) {
  y <- model[["y"]]
  time <- as.numeric(y[, 1])
  status <- as.numeric(y[, 2])
  n_obs <- length(time)
  t_max <- max(time)

  base <- survival::basehaz(model, centered = TRUE)
  risk <- exp(model$linear.predictors)

  cens <- survival::survfit(survival::Surv(time, 1 - status) ~ 1)
  g_at_y <- c(1, cens$surv)[findInterval(time, cens$time) + 1L]
  events <- status == 1

  lapply(seq_len(nsim), function(i) {
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
  })
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
