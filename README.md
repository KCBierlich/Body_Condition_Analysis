README
================

**Comparing uncertainty associated with 1-, 2-, and 3D aerial
photogrammetry-based body condition measurements of baleen whales**  
*Data and model code*

*Steps:*  
1\. Run uncertainty model on total length and width measurements to
produce a posterior predictive distribution for each measurement of each
whale.  
2\. Calculate the different body condition measurements (1D, 2D,and 3D)
for each individual using the uncertainty model outputs (the posterior
predictive distributions for each measurement).  
3\. Analyze and compare the different body condition measurements.

 

# 1\. Running the uncertainty model

Uncertainty model from:
<https://github.com/KCBierlich/Uncertainty_Model>

The code is designed to be run using the `drake` package, by running the
code in the script [make.R](make.R) either via the command line (i.e.,
`R CMD BATCH make.R`), or from within an interactive `R` session. The
outline of all project components (i.e., the `drake` plan) is available
in the [R/subplans](R/subplans) directory.

The `drake` [Github page](https://github.com/ropensci/drake) page has a
good overview of what drake does, and includes some code snippets. After
running the [make.R](make.R) script, the `drake::loadd` function is the
most helpful function for loading output.

The `drake` [documentation](https://books.ropensci.org/drake/index.html)
itself is also a good resource for learning how to use the `drake`
package.  
Starting with the
[Walkthrough](https://books.ropensci.org/drake/walkthrough.html#set-the-stage.)
is a decent place to just jump in to some details.

## Data formats

The Error measurement model is implemented in the
[model\_joint.R](R/nimble/model_joint.R) script. The model
implementation is abstract, to allow multiple observations of any
object. The [data\_plan.R](R/subplans/data_plan.R) script creates the
necessary, raw data structures for the model. The
[flatten\_data()](R/nimble/flatten_data.R) function munges the data
structures for use with the model’s implementation in `nimble`.

### Training object information

Each training object must be documented in the same format as the
`training_obj` object (below). The first two columns specify the
training object, and the third column records its known length. The
[flatten\_data()](R/nimble/flatten_data.R) function will use the
information in `training_obj` to associate known lengths with image and
pixel measurements of the training objects.

    ## Warning: Auto-saved .RData file detected. Remove it to enhance reproducibility.

| Subject    | Measurement  | Length |
| :--------- | :----------- | -----: |
| WAP-180611 | Total length |  1.400 |
| WAP-180305 | Total length |  1.330 |
| CA-180906  | Total length |  1.270 |
| CA-170813  | Total length |  1.525 |
| NC-190626  | Total length |  1.480 |

### Image data

Each image must be documented in the same format as the `Mns_images`
object (preview below). The first column `Image` provides a unique
identifier for the image and will be used to create an altitude
variable, which will be estimated from the altitude sensor readings
provided by `AltitudeBarometer` and `AltitudeLaser` in conjunction with
training data. The remaining columns in `Mns_images` report the focal
length (mm), image width (pixels), and camera sensor width (mm)
associated with the image, which will be used to estimate the image’s
ground sampling distance (GSD) per pixel.

| Image                       | AltitudeBarometer | AltitudeLaser | FocalLength | ImageWidth | SensorWidth |
| :-------------------------- | ----------------: | ------------: | ----------: | ---------: | ----------: |
| 180829\_A\_F3\_DSC09961.JPG |           60.2411 |         56.39 |          35 |       6000 |        23.5 |
| 180829\_A\_F3\_DSC00039.JPG |           60.7411 |         56.98 |          35 |       6000 |        23.5 |
| 180830\_A\_F3\_DSC00505.JPG |           61.7111 |         60.38 |          35 |       6000 |        23.5 |
| 180830\_L\_F4\_DSC01483.JPG |          103.2718 |        103.77 |          50 |       6000 |        23.5 |
| 180830\_L\_F3\_DSC01423.JPG |           72.6719 |         73.79 |          50 |       6000 |        23.5 |

### Pixel count “measurement” data

All pixel measurements must also be documented in the same format as the
`Mns_pixels` object (preview below). The first two columns specify the
measurement. One measurement variable, which will be estimated, will be
associated with each unique combination of the first two columns. The
`Image` column links the measurement to an image and it’s estimated GSD.
Lastly, the `PixelCount` column records the pixel-length of the object
as it appears in the image.

| Subject     | Measurement     | Image                       | PixelCount |
| :---------- | :-------------- | :-------------------------- | ---------: |
| BW180829-30 | TL              | 180829\_A\_F3\_DSC09961.JPG |  3211.9149 |
| BW180829-30 | TL.05.00..Width | 180829\_A\_F3\_DSC09961.JPG |   240.0000 |
| BW180829-30 | TL.10.00..Width | 180829\_A\_F3\_DSC09961.JPG |   331.9149 |
| BW180829-30 | TL.15.00..Width | 180829\_A\_F3\_DSC09961.JPG |   385.5319 |
| BW180829-30 | TL.20.00..Width | 180829\_A\_F3\_DSC09961.JPG |   434.0426 |

### Many-to-Many relationships

Storing Image and Pixel count data in separate structures allows
multiple measurements to be estimated from a single image. For example,
total length and maximum width can be measured from the same image
through a pixel count table like the following:

| Subject  | Measurement  | Image   | PixelCount |
| :------- | :----------- | :------ | ---------: |
| Animal A | Total length | Image 1 |       1000 |
| Animal A | Max. width   | Image 1 |        100 |

Both `PixelCount` entries above relate to a different object being
measured, but use the same estimated altitude and implied GSD for
`Image 1` when estimating lengths from pixel counts.

Similarly, the Image and Pixel count structures also allow one object to
be estimated from multiple images. For example, total length can be
estimated from multiple observations through a pixel count table like
the following:

| Subject  | Measurement  | Image   | PixelCount |
| :------- | :----------- | :------ | ---------: |
| Animal A | Total length | Image 1 |  1000.0000 |
| Animal A | Total length | Image 2 |  1005.4916 |
| Animal A | Total length | Image 3 |   999.1957 |
| Animal A | Total length | Image 4 |   989.1591 |
| Animal A | Total length | Image 5 |  1026.1055 |

## Data

Data located in 1\_uncertainty\_model \> data

*calibration\_object-measurements.csv* - training/calibration data for
the LemHex-44 and FreeFly Alta 6.  
Data from: Bierlich, K. C., Schick, R. S., Hewitt, J., Dale, J.,
Goldbogen, J. A., Friedlaender, A. S., & Johnston, D. W. (2020). Data
and scripts from: A Bayesian approach for predicting photogrammetric
uncertainty in morphometric measurements derived from UAS. Duke Research
Data Repository. V2 <https://doi.org/10.7924/r4sj1jj6s>

  - CO.ID = calibration object ID  
  - CO.Length = the true length of the CO.ID  
  - Image = image used for measuring calibration object  
  - Lab = the lab that collected the data  
  - Cruise = research expedicition ID  
  - Date = date that imagery was collected of calbiration object  
  - Flight = the flight number/name  
  - Pilot = pilot during data collection  
  - VO = visual observer  
  - Aircraft = the UAS aircraft used to collect imagery of calibration
    object to measure  
  - Focal\_length = focal length of camera  
  - Iw = image width in pixels  
  - Sw = sensor width in mm  
  - pix.dim = pixel dimensions; Sw/Iw
  - Baro\_raw = the raw relative altitude recorded by the barometer  
  - Launch.Ht = the launch height of the drone, to be added to the
    BarAlt to get the absolute barometric altitude above the surface of
    the water  
  - Baro+Ht = the baro\_raw + Launch.Ht to get the absolute barometer
    altitude  
  - Laser\_Alt = the altitude recorded by the laser altimeter. Blanks
    spaces/NAs indicate no/false reading
  - Altitude = altitude used in measurement, either Laser\_Alt or Baro +
    Ht  
  - Altimeter = which altimeter was used for altitude in measurement;
    either barometer or laser  
  - Lpix = the length in pixels of the known sized object (calibration
    object)  
  - object\_position = indicates if calibration object is in center of
    corner of image frame  
  - Analyst = analyst that performed the measurement

*measurement\_inputs.csv* - total length and body width measurements for
blue, humpback, and Antarctic minke whales. Measurements performed using
[MorphoMetriX](https://github.com/wingtorres/morphometrix)

  - AID = unique animal ID for individual whale  
  - Species = the species of whale  
  - Image = the image ID used for measuring the whale  
  - TL = total length of the whale in meters, measure rostrum to fluke
    notch  
  - TL.05.00..Width - TL.95.00..Width = width measurements in %
    increments of TL  
  - Reproductive\_Class = actually pretty limited here, just “calf” or
    “adult”  
  - HTRange = Head to Tail Range used to calculate 2D and 3D body
    condition measurements  
  - SHrange = Short Range, only includes the three widths with the
    largest standard deviation for the population. Not included in the
    analysis  
  - SW = the Single Width (1D) measurement, width with the largest
    standard deviation for population  
  - BaroAlt = the raw relative altitude recorded by the barometer  
  - Launch\_Ht = the launch height of the drone, to be added to the
    BarAlt to get the absolute barometric altitude  
  - LaserAlt = the altitude recorded by the laser altimeter. Blanks
    spaces/NAs indicate no/false reading  
  - Altitude = altitude used in measurement, either LaserAlt or BaroAlt
    + Launch\_Ht  
  - Focal\_Length = focal length (mm) of the camera used  
  - Iw = image width, in pixels  
  - Sw = sensor width, in mm  
  - alt\_diff = percent difference between BaroAlt + Launch\_Ht and
    LaserAlt

## Steps

run ‘make.R’

This will generate an “output” folder that contains an ‘mcmc’ folder and
a ‘reports’ folder.

  - The ‘mcmc’ folder contains all the .rds outputs from the model.
      - “length\_samples\_mns.rds” contains the posterior predictive
        measurement distributions for TL and widths and is used to
        calculate body condition in the
        “2\_calculating\_body\_condition” folder.
  - The ‘reports’ folder contains .html files to evaluate the results
    from the model
      - See “posterior\_diagnostics\_mns.html” for a summary of model
        output for each measurement

After model is finished running, proceed to 2\_calculate\_body condition

# 2\. Calculating body condition

In the “calculate\_body\_condition” folder, run
“Calculate\_body\_condition.Rmd”.

This uses
[CollatriX](https://github.com/cbirdferrer/collatrix#installation) to
calculate body condition measurements.

*Creates:*  
\* whales\_merged.csv – cleaned dataframe to input into CollatriX  
\* collated\_allMC.rds – each animal’s dataframe containing the
posterior distribution (the mcmc iterations) for each measurement  
\* collated\_MC\_summarystats.csv – CollatriX summary sheet with the
mean and 95% HPD intervals for the posterior predictive distribution of
each body condition metric for each individual. Used in body condition
analysis.

# 3\. body condition analysis

Run “Body\_condition\_analysis.Rmd”

This will run the analysis comparing the different body condition
metrics and re-create figures from manuscript.

## Contact

[KC Bierlich](https://github.com/KCBierlich),
<kevin.bierlich@oregonstate.edu>

Core contributors:  
[Clara N. Bird](https://github.com/cbirdferrer)  
[Dr. Josh Hewitt](https://github.com/jmhewitt)
