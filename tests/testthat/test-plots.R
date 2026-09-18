test_that("pb_plot_estimates() builds a faceted histogram", {
  res <- boot_binomial(n = 20)
  plot <- pb_plot_estimates(res)
  expect_s3_class(plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(plot))
  expect_equal(levels(plot$data$term), c("(Intercept)", "mpg"))

  one <- pb_plot_estimates(res, parameter = "mpg")
  expect_equal(unique(as.character(one$data$term)), "mpg")
  expect_error(pb_plot_estimates(res, parameter = "wt"), "Unknown parameter")
})

test_that("pb_plot_diagnostics() computes running means per term", {
  res <- boot_binomial(n = 20)
  plot <- pb_plot_diagnostics(res, parameter = "mpg")
  expect_s3_class(plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(plot))

  mpg <- res$estimates[, "mpg"]
  expect_equal(plot$data$running_mean, unname(cumsum(mpg) / seq_along(mpg)))
})

test_that("pb_plot_predictions() draws ribbons or point ranges", {
  res <- boot_binomial(n = 20)
  new_cars <- data.frame(mpg = c(15, 20, 25), label = c("a", "b", "c"))

  ribbon <- pb_plot_predictions(res, new_cars, x = "mpg", type = "response")
  expect_s3_class(ribbon, "ggplot")
  expect_no_error(ggplot2::ggplot_build(ribbon))
  expect_true(all(ribbon$data$lower <= ribbon$data$upper))
  expect_s3_class(ribbon$layers[[1]]$geom, "GeomRibbon")

  ranges <- list(
    pb_plot_predictions(res, new_cars),
    pb_plot_predictions(res, new_cars, x = "label")
  )
  for (plot in ranges) {
    expect_no_error(ggplot2::ggplot_build(plot))
    expect_s3_class(plot$layers[[1]]$geom, "GeomPointrange")
  }

  expect_error(pb_plot_predictions(res, new_cars, x = "nope"), "column of `newdata`")
  expect_error(pb_plot_predictions(res, 1:3), "data frame")
})
