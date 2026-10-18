# Part 1: predict the number of incidents (Task 1, Part A)

Run the `.Rmd` files in order from the project root. Each has gaps marked `TODO (you)`. Knit or run chunk by chunk.

1. `01_data_prep.Rmd`: build the beach-month panel with counts by severity (`panel.rds`)
2. `02_eda.Rmd`: look at the counts
3. `03_features.Rmd`: choose predictors (`panel_f.rds`)
4. `04_baseline_models.Rmd`: Poisson and negative binomial GLMs
5. `05_validation.Rmd`: out-of-sample comparison, pick the model
6. `06_forecast.Rmd`: next year's expected counts

Packages: dplyr, tidyr, ggplot2, lubridate, MASS, knitr, rmarkdown (all installed; `tidyverse` itself is not, so the files load the parts individually).

## Glossary
- **Offset**: a term with coefficient fixed at 1; `offset(log(visitors))` makes the model about incidents per visitor.
- **Rate ratio**: `exp(coef)`, the multiplicative effect on the expected count.
- **Overdispersion**: variance greater than the mean; handled by negative binomial.
- **Log score / negative log-likelihood**: probability-based out-of-sample error; lower is better.
- **Rolling origin**: repeatedly train on the past and test on the next year.
