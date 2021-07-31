data_plan = drake_plan(
  
  #
  # training data
  #
  
  ## load error experiment training data. 
    # Note that APE stands for altitude position experiment and is the calibration objects used as training data
  APE = read.csv(file.path('data', 'calibration_object-measurements.csv')),

  
  # training object information (m)
  training_obj = unique(data.frame(
    Subject = APE$CO.ID,
    Measurement = 'Total length',
    Length = APE$CO.Length)), 
  

  # # Camera Specs: Sony Alpha 5100
  Sw = 23.5,  # Sensor width (mm)
  Iw = 6000,   # Image width (px)
  


  # # Filter UAS from APE dataset to be used as training data
  APE_filtered = APE %>% dplyr::filter(
    Aircraft %in% c('LemHex', 'Alta'),
    Altimeter == 'barometer',       # b/c laser has NAs, # filter duplicate obs.
    Analyst == 'KCB',               # just need single measurer (analyst) since there was no difference among them.
    #CO.ID == "NC-190626",           # to filter by CO.ID (calibration object ID)
    is.finite(Baro.Ht),
    is.finite(Laser_Alt)
  ),
  
  
  # extract standardized information about images
  APE_images = APE_filtered %>% 
    dplyr::mutate(
      Image = Image,
      AltitudeBarometer = Baro.Ht,
      AltitudeLaser = Laser_Alt,
      FocalLength = Focal_Length,
      ImageWidth = Iw,
      SensorWidth = Sw
    ) %>% 
    dplyr::select(
      Image, AltitudeBarometer, AltitudeLaser, FocalLength, ImageWidth, 
      SensorWidth
    ),
  
  # extract standardized information about pixel counts
  APE_pixels = APE_filtered %>%
    dplyr::mutate(
      Subject = CO.ID,
      Measurement = 'Total length',
      Image = Image,
      PixelCount = Lpix
    ) %>% 
    dplyr::select(
      Subject, Measurement, Image, PixelCount
    ),
  
  #
  # observation study
  #
  
  ## load observations of whales
  Mns = read.csv(file.path("data", "measurement_inputs.csv")),
  

  Mns_filtered = Mns %>% 
    # Create variables for focal length and altimeter of each aircraft
    dplyr::mutate(
      AltitudeLaser = LaserAlt,
      AltitudeBarometer = BaroAlt + Launch_Ht
    ), 

   
  # extract standardized information about images
  Mns_images = Mns_filtered %>% 
    dplyr::mutate(
      FocalLength = Focal_Length,
      ImageWidth = Iw,
      SensorWidth = Sw
    ) %>% 
    dplyr::select(
      Image, AltitudeBarometer, AltitudeLaser, FocalLength, ImageWidth, 
      SensorWidth
      ),
  
  
  #bw_mns_mx = read.csv(file.path("data", "Blues_AMWs_measurements.csv")),
  
  #Mns_pixels  =   bw_mns_mx %>%
  Mns_pixels  =   Mns %>%
    pivot_longer(cols = starts_with("TL"),
                 names_to = "Measurement", values_to = "Val")  %>%
    dplyr::mutate(
      Subject = AID,
      # Lengths computed in MorphoMetriX. If need to back-calculate pixels use line below. If already in pixel, just use Val
      PixelCount = Val * Focal_Length * Iw / Sw / Altitude
    ) %>%
    dplyr::select(
      Subject, Measurement, Image, PixelCount)
)
