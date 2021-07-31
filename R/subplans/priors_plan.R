priors_plan = drake_plan(
  
  # minimum and maximum altitudes (m) at which drones are flown
  priors_altitude = c(min = 5, max = 130),
  
  # minimum and maximum lengths (m) for which the model is used
  priors_lengths = c(min = 0.1, max = 26),
  
  # prior distributions for measurement error bias parameters
      # Note, bias is listed but excluded from model: to include in model see "model_joint.R" line 47.
  priors_bias = rbind(
    Barometer = c(mean = 0, sd = 3),
    Laser = c(mean = 0, sd = 1),
    Pixels = c(mean = 0, sd = 5)
  ), 
  
  # prior distributions for measurement error scale parameters
  priors_sigma = rbind(
    Barometer = gamma.param(mu = 2, sd = 1),
    Laser = gamma.param(mu = 2, sd = 1),
    Pixels = gamma.param(mu = 5, sd = 4)
  )
  
)
