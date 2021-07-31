report_plan = drake_plan(
  
  posterior_report_mns = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'templates', 
                           'posterior_diagnostics.Rmd')),
      output_file = 'posterior_diagnostics_mns.html',
      output_dir = 'reports',
      quiet = FALSE,
      params = list(samples = fit_mns,
                    nim_pkg = nim_pkg_mns,
                    nburn = nburn)
    )
  ),
  
  posterior_report_validation = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'templates', 
                           'posterior_diagnostics.Rmd')),
      output_file = 'posterior_diagnostics_validation.html',
      output_dir = 'reports',
      quiet = FALSE,
      params = list(samples = fit_val,
                    nim_pkg = nim_pkg_val,
                    nburn = nburn)
    )
  ),
  
  validation_statistics = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'templates',
                           'validation_statistics.Rmd')),
      output_file = 'validation_statistics.html',
      output_dir = 'reports',
      quiet = FALSE,
      params = list(samples = fit_val,
                    nim_pkg = nim_pkg_val,
                    nburn = nburn,
                    L_train = 1.48)
    )
  ),
  
  posterior_report_validation_repeated = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'templates', 
                           'posterior_diagnostics.Rmd')),
      output_file = 'posterior_diagnostics_validation_repeated.html',
      output_dir = 'reports',
      quiet = FALSE,
      params = list(samples = fit_repeatedval,
                    nim_pkg = nim_pkg_repeatedval,
                    nburn = nburn)
    )
  ),
  
  validation_statistics_repeated = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'templates',
                           'validation_statistics.Rmd')),
      output_file = 'validation_statistics_repeated.html',
      output_dir = 'reports',
      quiet = FALSE,
      params = list(samples = fit_repeatedval,
                    nim_pkg = nim_pkg_repeatedval,
                    nburn = nburn,
                    L_train = 1.48)
    )
  )
  
)

