fit = function(nim_pkg_val, niter, mcmc_sample_dir, nthin) {

  # load nimble package
  nim_pkg = readRDS(nim_pkg_val)
  
  # initialize nimble model
  droneLengths = nimbleModel(code = model, name = 'droneLengths', 
                             constants = nim_pkg$consts, data = nim_pkg$data,
                             inits = nim_pkg$inits)
  
  # check to make sure model is well defined
  if(!is.finite(droneLengths$calculate())) {
    ll = sapply(droneLengths$getNodeNames(), function(tgt) {
      droneLengths$calculate(tgt)
    })
    print(which(!is.finite(ll)))
  }
  
  # compile model
  cdroneLengths = compileNimble(droneLengths, resetFunctions = TRUE)
  
  
  #
  # build sampler
  #
  
  # default configuration
  conf = configureMCMC(cdroneLengths, print = FALSE)
  
  # add thinning
  conf$setThin(nthin)
  
  # store samples for parameters on observation scale
  conf$addMonitors('sigma')
  
  # jointly sample all lengths associated with each image
  conf$removeSamplers(c('a', 'L'))
  sampler_defined = rep(FALSE, nrow(nim_pkg$consts$pixel_id_map))
  for(i in 1:length(sampler_defined)) {
    if(!(nim_pkg$consts$pixel_id_map[i, 'ObjectId'] %in% 
         nim_pkg$consts$L_unknown_inds)) {
      tgt = paste('a[', nim_pkg$consts$pixel_id_map[i, 'ImageId'], ']', 
                  sep = '')
      conf$addSampler(target = tgt, type = 'RW')
    } else {
      if(!sampler_defined[i]) {
        # extract image
        tgt_img = nim_pkg$consts$pixel_id_map[i, 'ImageId']
        # all objects associated with image
        objs = unique(nim_pkg$consts$pixel_id_map[
          nim_pkg$consts$pixel_id_map[, 'ImageId'] == tgt_img, 
          'ObjectId'
          ])
        # block sampler targets and specification 
        tgt = c(
          paste('a[', tgt_img, ']', sep = ''),
          paste('L[', objs, ']', sep = '')
        )
        conf$addSampler(target = tgt, type = 'AF_slice') 
        # update list of samplers to define
        sampler_defined[ 
          nim_pkg$consts$pixel_id_map[, 'ImageId'] == tgt_img 
        ] = TRUE
      }
    }
    
  }
  
  print(conf)

  # construct sampler
  droneLengthsMCMC = buildMCMC(conf)
  
  # compile sampler
  cdroneLengthsMCMC = compileNimble(droneLengthsMCMC, resetFunctions = TRUE)
  
  
  #
  # run sampler
  #
  
  # draw samples
  mcmc.out = runMCMC(cdroneLengthsMCMC, niter = niter)
  
  # save output
  f = file.path(mcmc_sample_dir, paste(id_chr(), '.rds', sep = ''))
  saveRDS(mcmc.out, file = f)
  
  f
}