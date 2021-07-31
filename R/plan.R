lapply(list.files("./R/subplans", full.names = TRUE, recursive = TRUE), source)

the_plan = bind_plans(
  data_plan,
  priors_plan,
  nimble_plan,
  validation_plan,
  report_plan
)