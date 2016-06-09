# DOS-Segmented-Regression-Tools
A collection of R and Matlab scripts used to batch-analyze diffuse optical spectroscopy (DOS) and metabolic cart data via piecewise linear regression. These scripts were originally intended for internal use with the Hamamatsu Photonics TRS-20 and pocketNIRS for optical data, and the CareFusion Vmax system for metabolic cart data. The scripts are organized into folders by device.

### Example Output

![](https://github.com/btran29/DOSI-SLM-SegmentedOut/blob/master/example/fig1.PNG)

**Deoxyhemoglobin Threshold Analysis**: Prefrontal cortex deoxygenated hemoglobin levels (HbR) in a healthy adult human subject throughout a standardized ramped-cycling challenge. X-axis breakpoint locations are denoted by a hollow square with a vertical dashed AB line. The strength of fit (95% CI) given the shown breakpoints are denoted by horizontal lines extending from the hollow square. In this figure, the identified HbR threshold is the second breakpoint. Note that the y-axis data label, [HbR], would not apply to an analysis conducted on the pocketNIRS system. Unlike the TRS-20, the pocketNIRS uses a continuous-wave DOS method which can only quantify relative changes in HbR.

#### More information on what these scripts were used for
These tools were used to clean DOS and metabolic cart data then run a threshold analysis via a piecewise linear modeling package (['segmented', available in CRAN](https://cran.r-project.org/web/packages/segmented/index.html)). An analysis integrating both DOS and metabolic cart data was conducted by binning the metabolic cart data over key time points in DOS data.

The output is stratified by testing session, probe location, and with raw or binned data. For DOS variables, oxygenated hemoglobin (HbO2), reduced hemoglobin (HbR), total hemoglobin (tHb), and oxygen saturation (O2sat) were analyzed. For metabolic cart variables: O2 (VO2) and CO2 (VCO2) consumption, ventilatory equivalent (VE), heart rate (HR), and work rate (WR) were analyzed. Outputs were generated in tabular (CSV) and graphical formats (PDF,TIFF).

The main method, as written for the TRS-20 device, requires matching exercise data. See script comments for specifics.
