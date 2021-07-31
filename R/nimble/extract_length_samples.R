extract_length_samples = function(nim_pkg, sample_file, nburn, estimated_only,
                                  mcmc_sample_dir) {
 
  # load nimble package
  nim_pkg = readRDS(nim_pkg)
  
  # load posterior samples
  samples = readRDS(sample_file) 
  
  # determine which objects samples must be extracted for
  if(estimated_only) {
    obj_filter = TRUE
  } else {
    obj_filter = c(TRUE, FALSE)
  }
  
  L.subset = nim_pkg$maps$L %>% dplyr::filter(Estimated %in% obj_filter)
  
  # package lengths by subject
  res = lapply(unique(L.subset$Subject), function(subject) {
    # determine all lengths for subject
    L_ids = L.subset %>% dplyr::filter(Subject == subject)
    # extract all lengths for subject
    df = data.frame(apply(L_ids, 1, function(r) { samples[, r['NodeName']] }))
    # label and return measurements
    colnames(df) = L_ids %>% dplyr::select(Measurement) %>% unlist()
    df
  })
  
  # label subjects
  names(res) = unique(L.subset$Subject)
  
  # save lengths
  f = file.path(mcmc_sample_dir, paste(id_chr(), '.rds', sep = ''))
  saveRDS(res, file = f)
  
  f
}