# parametricboot: Parametric Bootstrap for Fitted Regression Models

Automates the parametric bootstrap for models fitted with
[`stats::lm()`](https://rdrr.io/r/stats/lm.html),
[`stats::glm()`](https://rdrr.io/r/stats/glm.html),
[`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html),
[`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html) and
[`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html).

## Workflow

1.  Fit a model as usual.

2.  Draw bootstrap replicates with
    [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md),
    or
    [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md)
    when a single refit is slow.

3.  Summarise them:
    [`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md),
    [`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md),
    [`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md)
    and
    [`pb_tidy()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_tidy.md)
    for tables;
    [`pb_plot_estimates()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_estimates.md)
    and
    [`pb_plot_diagnostics()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_diagnostics.md)
    for plots. If some refits misbehaved, see
    [`pb_drop_warned()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_drop_warned.md).

4.  Propagate the uncertainty to predictions with
    [`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
    and
    [`pb_plot_predictions()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_predictions.md).

5.  Test nested models with the bootstrap likelihood-ratio test
    [`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md),
    and compare models that are not nested with
    [`pb_compare_models()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_compare_models.md).

## See also

Useful links:

- <https://diogoribeiro7.github.io/parametricboot/>

- <https://github.com/DiogoRibeiro7/parametricboot>

- Report bugs at
  <https://github.com/DiogoRibeiro7/parametricboot/issues>

## Author

**Maintainer**: Diogo Ribeiro <diogo.debastos.ribeiro@gmail.com>
([ORCID](https://orcid.org/0009-0001-2022-7072)) (ESMAD, Instituto
Politecnico do Porto) \[copyright holder\]
