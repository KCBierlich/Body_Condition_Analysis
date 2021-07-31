model = nimbleCode({
  
  #
  # Priors for true lengths, possibly many-to-many relationships w/images
  #
  
  # priors for lengths to be estimated
  for(i in 1:N_unknown_lengths) {
    L[L_unknown_inds[i]] ~ dunif(min = priors_lengths[1], 
                                 max = priors_lengths[2])
  }
  
  #
  # Priors and likelihoods for altitudes, 1:1 relationships with each image
  #
  
  for(i in 1:N_images) {
    # prior for unobserved, true altitude
    a[i] ~ dunif(min = priors_altitude[1], max = priors_altitude[2])
    # likelihood for barometer and laser measurements
    a_baro[i] ~ dnorm(mean = a[i] + bias[1], var = sigma[1])
    a_laser[i] ~ dnorm(mean = a[i] + bias[2], var = sigma[2])
  }
  
  #
  # Likelihoods for all measured pixel-lengths (i.e., training and whale) 
  #
  
  for(i in 1:N_pixel_counts) {
    # pixel-length of objects, without measurement error
    pixels_expected[i] <- 
      L[ pixel_id_map[i, 1] ] *              # true object length (m)
      image_info[ pixel_id_map[i, 2], 1 ] *  # image focal length (mm)
      image_info[ pixel_id_map[i, 2], 2 ] /  # image width (pixels)
      image_info[ pixel_id_map[i, 2], 3 ] /  # image sensor width (mm)
      a[ pixel_id_map[i, 2] ]                # image altitude (m)
    # likelihood for pixel measurements
    pixels_obs[i] ~ dnorm(mean = pixels_expected[i] + bias[3], var = sigma[3])
  }
  
  #
  # Measurement error priors
  #
  
  # location and scale for altitude and pixel errors
  for(i in 1:3) {
    # bias[i] ~ dnorm(mean = priors_bias[i, 1], sd = priors_bias[i, 2])   # to include a bias term in model.
    sigma[i] ~ dinvgamma(shape = priors_sigma[i, 1], rate = priors_sigma[i, 2])
  }
  
})
