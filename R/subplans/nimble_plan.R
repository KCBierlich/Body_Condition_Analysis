nimble_plan = drake_plan(

  # directory in which to store mcmc samples and files
  mcmc_sample_dir = !!file.path('output', 'mcmc'),

  # number of mcmc iterations to draw, and samples to thin
  niter = 1e6,
  nthin = 10,

  # number of posterior samples to discard during inference
  nburn = niter / nthin / 2,

  # package training data with whale observations
  nim_pkg_mns = target(
    flatten_data(
      images = rbind(APE_images, Mns_images),
      pixels = rbind(APE_pixels, Mns_pixels),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths,
      priors_bias = priors_bias, priors_sigma = priors_sigma,
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),

  # fit model to training data with whale observations
  fit_mns = target(
    fit(nim_pkg_mns, niter, mcmc_sample_dir, nthin),
    format = 'file'
  ),

  # extract and package estimated length samples
  length_samples_mns = target(
    extract_length_samples(nim_pkg = nim_pkg_mns, sample_file = fit_mns,
                           estimated_only = TRUE,
                           mcmc_sample_dir = mcmc_sample_dir),
    format = 'file'
  )

)
