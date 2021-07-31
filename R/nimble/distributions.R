# density for log(X) where X ~ Gamma(shape, rate)
dlogGamma = nimbleFunction(
  run = function(x = double(0), shape = double(0), rate = double(0), 
                 log = logical(0, default = 0)) {
    
    returnType(double(0))
    
    res <- dgamma(x = exp(x), shape = shape, rate = rate, log = TRUE) + x
    
    if(log) { return(res) } else { return(exp(res)) }
  }
)

# random generation for log(X) where X ~ Gamma(shape, rate)
rlogGamma = nimbleFunction(
  run = function(n = integer(0), shape = double(0), rate = double(0)) {
    returnType(double(0))
    x <- log(rgamma(n = 1, shape = shape, rate = rate))
    return(x)
  }
)

registerDistributions(list(
  dlogGamma = list(
    BUGSdist = 'dlogGamma(shape, rate)',
    types = c('value = double(0)', 'shape = double(0)', 'rate = double(0)')
  )
))