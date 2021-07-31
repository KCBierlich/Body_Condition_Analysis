gamma.param = function(mu, sd) {
  # Compute shape and rate parameters for gamma distribution when the 
  # distribution is specified via its mean and standard deviation
  v = sd^2
  params = c(shape = mu^2/v, rate = mu/v)
  if(any(params < 0)){
    stop('No gamma distribution may have this combination of mu and sd.')
  }
  else{
    params
  }
}