# Contributing to parametricboot

Thank you for taking the time to contribute. Bug reports, feature requests and
pull requests are all welcome.

## Reporting a bug

Open an [issue](https://github.com/DiogoRibeiro7/parametricboot/issues) with a
minimal reproducible example: the smallest piece of code, using a built-in or
simulated data set, that shows the problem. The
[reprex](https://reprex.tidyverse.org) package makes this easy. Please include
the output of `sessionInfo()`.

## Proposing a change

For anything larger than a typo, open an issue first so that the design can be
discussed before you invest time in it. Statistical changes (a new interval
type, support for a new model class) should come with a reference for the
method.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Install the development dependencies:
   ```r
   install.packages("devtools")
   devtools::install_dev_deps()
   ```
3. Make your change. New behaviour needs tests, and bug fixes need a test that
   fails without the fix.
4. Before you push, run:
   ```r
   devtools::document()  # regenerate NAMESPACE and man/
   devtools::test()
   devtools::check()     # must finish with 0 errors, 0 warnings, 0 notes
   ```
   To run the `pb_parallel()` tests locally, install the package first with
   `devtools::install()`: the parallel workers are fresh R sessions.
5. Add a bullet to the top of `NEWS.md` describing the change from a user's
   point of view.
6. If you edited `README.Rmd`, re-knit it with `devtools::build_readme()`.

## Code style

* Follow the [tidyverse style guide](https://style.tidyverse.org). The
  repository ships a `.lintr` file; run `lintr::lint_package()` to check.
* Documentation is written with [roxygen2](https://roxygen2.r-lib.org) and
  Markdown. Never edit `NAMESPACE` or files under `man/` by hand.
* Exported functions are prefixed with `pb_`, validate their arguments, and
  fail with a message that says what was expected.
* Keep hard dependencies minimal. Model packages such as 'lme4' and 'survival'
  belong in `Suggests` and are checked for at run time.

## Code of conduct

This project is released with a
[Contributor Code of Conduct](../CODE_OF_CONDUCT.md). By participating you
agree to abide by its terms.
