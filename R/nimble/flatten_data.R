flatten_data = function(images, pixels, train_objs, priors_altitude,
                        priors_lengths, priors_bias, priors_sigma,
                        mcmc_sample_dir) {

  #
  # initialize nimble package and transfer prior specification
  #

  # initialize storage for nimble inputs
  nim_pkg = list(data = list(), consts = list(), inits = list())

  # Initial measurement error parameters
  nim_pkg$inits$bias = c(Barometer = 0, Laser = 0, Pixels = 0)
  nim_pkg$inits$sigma = c(Barometer = 1, Laser = 1, Pixels = 1)

  # Prior distribution specifications
  nim_pkg$consts$priors_altitude = priors_altitude
  nim_pkg$consts$priors_lengths = priors_lengths
  nim_pkg$consts$priors_bias = priors_bias
  nim_pkg$consts$priors_sigma = priors_sigma


  #
  # merge datasets
  #

  # ensure complete set of images and pixel measurements is unique, and id'd
  images = unique(images) %>% dplyr::mutate(ImageId = 1:n())
  pixels = unique(pixels)

  # enumerate all objects for which measurements were taken
  objs = unique(pixels[, c('Subject', 'Measurement')]) %>%
    dplyr::mutate(
      name = paste(gsub('\\s+', '_', Subject),
                   gsub('\\s+', '_', Measurement),
                   sep = '-'),
      ObjectId = 1:n()
    )

  # determine and merge id's of training objects
  train_ids = objs %>%
    dplyr::semi_join(train_objs) %>%
    dplyr::select(ObjectId) %>%
    unlist()
  objs = objs %>%
    dplyr::mutate(Type = ifelse(ObjectId %in% train_ids, 'Train', 'Estimate'))

  # export object id mapping
  nim_pkg$maps$L = objs %>%
    dplyr::mutate(
      Estimated = (Type == 'Estimate'),
      NodeName = paste('L[', ObjectId, ']', sep = '')
    ) %>%
    dplyr::select(Subject, Measurement, Estimated, NodeName)


  #
  # format data for model code
  #

  # barometer and laser altimeter readings
  nim_pkg$data$a_baro = images$AltitudeBarometer
  nim_pkg$data$a_laser = images$AltitudeLaser
  nim_pkg$inits$a = rowMeans(images[, c('AltitudeBarometer', 'AltitudeLaser')],
                             na.rm = TRUE)

  # pixel measurements
  nim_pkg$data$pixels_obs = pixels$PixelCount

  # information about each image
  nim_pkg$consts$image_info = as.matrix(
    images[, c('FocalLength', 'ImageWidth', 'SensorWidth')]
  )

  # associate each length measurement with object (lengths) and images
  nim_pkg$consts$pixel_id_map = as.matrix(
    pixels %>%
      dplyr::left_join(objs, by = c('Subject', 'Measurement')) %>%
      dplyr::left_join(images, by = 'Image') %>%
      dplyr::select(ObjectId, ImageId)
  )

  # initialize object lengths
  nim_pkg$inits$L =  pixels %>%
    # get image information for measurements
    dplyr::left_join(cbind(images, a = nim_pkg$inits$a),
                     by =  'Image') %>%
    # get object id's and test/train type
    dplyr::left_join(objs, by = c('Subject', 'Measurement')) %>%
    # source of training object lengths
    dplyr::left_join(train_objs,
                     by = c('Subject', 'Measurement')) %>%
    # estimated length
    dplyr::mutate(L = a * SensorWidth / FocalLength / ImageWidth *
                    PixelCount) %>%
    # overwrite estimates with true lengths if available (i.e., training objs)
    dplyr::mutate(L = ifelse(is.finite(Length), Length, L)) %>%
    # summarize, arrange, output
    dplyr::group_by(ObjectId) %>%
    dplyr::summarise(L_est = mean(L)) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(ObjectId) %>%
    dplyr::select(L_est) %>%
    unlist()

  #
  # Extract totals
  #

  # indices of lengths to be estimated
  nim_pkg$consts$L_unknown_inds = c(which(objs$Type == 'Estimate'), 0)

  nim_pkg$consts$N_images = nrow(images)
  nim_pkg$consts$N_unknown_lengths = length(nim_pkg$consts$L_unknown_inds) - 1
  nim_pkg$consts$N_pixel_counts = nrow(pixels)


  #
  # Initialize expected pixel counts
  #

  nim_pkg$inits$pixels_expected = sapply(
    1:nim_pkg$consts$N_pixel_counts, function(i) {
      nim_pkg$inits$L[ nim_pkg$consts$pixel_id_map[i, 1] ] *
      nim_pkg$consts$image_info[ nim_pkg$consts$pixel_id_map[i, 2], 1 ] *
      nim_pkg$consts$image_info[ nim_pkg$consts$pixel_id_map[i, 2], 2 ] /
      nim_pkg$consts$image_info[ nim_pkg$consts$pixel_id_map[i, 2], 3 ] /
      nim_pkg$inits$a[ nim_pkg$consts$pixel_id_map[i, 2] ]
  })


  #
  # save package
  #

  dir.create(mcmc_sample_dir, showWarnings = FALSE, recursive = TRUE)
  f = file.path(mcmc_sample_dir, paste(id_chr(), '.rds', sep = ''))
  saveRDS(nim_pkg, file = f)

  f
}