# DOSI-SLM-SegmentedOut
A collection of R and Matlab scripts used to batch-analyze diffuse optical spectroscopy and metabolic cart data via piecewise linear regression.

![](https://github.com/btran29/DOSI-SLM-SegmentedOut/blob/master/example/fig1.PNG)

**Example figure**: Prefrontal cortex deoxygenated hemoglobin levels (HbR) in a healthy adult human subject throughout a standardized ramped-cycling challenge.

#### R-only workflow
Cleans up DOS data from a Hamamatsu TRS-20 via splitting it by study phases, then runs the threshold analysis via the ['segmented' package available in CRAN for R](https://cran.r-project.org/web/packages/segmented/index.html). Outputs testing-session-wise data for DOS-obtained variables: oxygenated hemoglobin, reduced hemoglobin, total hemoglobin, and oxygen saturation, as well as metabolic cart variables: O2 and CO2 consumption, ventilatory equivalent, heart rate, and work rate. Using testing-session-wise and probe-location-wise identifiers, the data is output in both binned and unbinned tables by study phases, and PDF or TIFF figures. Comparison of data between the TRS-20 (3- or 5-sec intervals between measurements) and metabolic cart (breath by breath) is completed by averaging metabolic cart data +/- over a set span of time from a key optical data timepoint (e.g. +/- 5 sec from a breakpoint). The main method, as written, requires matching exercise data, however variables to be analyzed can be added/removed as needed. See script comments for specifics.

#### Older Matlab to R workflow
Takes DOSI data, runs Matlab threshold analysis via the [shape language modeling (SLM) package avaiable in the file exchange for Matlab](http://www.mathworks.com/matlabcentral/fileexchange/24443-slm-shape-language-modeling), then outputs CSVs for threshold analysis in R via 'Segmented'. There is another version of the script if you want to run the analysis without matching exercise data - that script will provide basic figure outputs only and no workbook output.
