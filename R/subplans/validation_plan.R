validation_plan = drake_plan(
  
  # indices for validation training
  validation_subset = target(
    sample.int(n = nrow(APE_filtered), size = 0.5 * nrow(APE_filtered), 
               replace = FALSE),
    seed = 2020
  ),
  
  # indices for validation testing
  validation_subset_test = (1:nrow(APE_filtered))[-validation_subset],
  
  # package training data, with testing and training partitions
  nim_pkg_val = target(
    flatten_data(
      images = rbind(APE_images[validation_subset, ], 
                     APE_images[validation_subset_test, ]),
      pixels = rbind(
        APE_pixels[validation_subset, ],
        APE_pixels[validation_subset_test, ] %>% 
          dplyr::mutate(
            replicate = 1:n(),
            Measurement = paste(Measurement, ' (', replicate, ')', sep ='')
          ) %>% 
          dplyr::select(-replicate)
      ),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths, 
      priors_bias = priors_bias, priors_sigma = priors_sigma, 
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),
  
  # Package training data, with testing and training partitions. 
  # However, this validation assumes that all testing observations are repeated 
  # measures of the same object
  nim_pkg_repeatedval = target(
    flatten_data(
      images = rbind(APE_images[validation_subset, ], 
                     APE_images[validation_subset_test, ]),
      pixels = rbind(
        APE_pixels[validation_subset, ],
        APE_pixels[validation_subset_test, ] %>% 
          dplyr::mutate(
            Measurement = paste(Measurement, ' (1)', sep ='')
          )
      ),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths, 
      priors_bias = priors_bias, priors_sigma = priors_sigma, 
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),
  
  # fit model to training data
  fit_val = target(
    fit(nim_pkg_val, niter, mcmc_sample_dir, nthin),
    format = 'file'
  ),
  
  # fit model to training data
  fit_repeatedval = target(
    fit(nim_pkg_repeatedval, niter, mcmc_sample_dir, nthin),
    format = 'file'
  ),
  
  # extract and package estimated length samples
  val_length_samples = target(
    extract_length_samples(nim_pkg = nim_pkg_val, 
                           sample_file = fit_val,
                           estimated_only = TRUE, 
                           mcmc_sample_dir = mcmc_sample_dir),
    format = 'file'
  ),
  
  # extract and package estimated length samples
  repeatedval_length_samples = target(
    extract_length_samples(nim_pkg = nim_pkg_repeatedval, 
                           sample_file = fit_repeatedval,
                           estimated_only = TRUE, 
                           mcmc_sample_dir = mcmc_sample_dir),
    format = 'file'
  )
  
    
)