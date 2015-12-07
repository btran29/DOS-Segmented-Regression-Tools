# DOSI-SLM-SegmentedOut
A collection of R scripts used to batch-analyze diffuse optical spectroscopy and metabolic cart data via piecewise linear regression.

![](https://github.com/btran29/DOSI-SLM-SegmentedOut/blob/master/example/fig1.PNG)
Example figure for deoxygenated hemoglobin levels in a healthy human subject throughout a standardized ramped-cycling challenge.

#### R-only workflow
Cleans up DOS data from a Hamamatsu TRS-20 via splitting it by study phases, then runs the threshold analysis via the 'segmented' package available in R. Outputs testing-session-wise data for HbO2, HbR, THb, and O2sat + VE, HR, W. Using testing-session-wise identifiers, the data is output in both binned and unbinned tables by study phases, and PDF or PNG figures. Comparison of data between the TRS-20 (3- or 5-sec itnervals between measurements) and metabolic cart (breath by breath) is completed by averaging metabolic cart data over a set span of time (e.g. +/- 5 sec from a breakpoint). Requires matching exercise data. See script comments for specifics. 

#### Older Matlab to R workflow
Takes DOSI data, runs Matlab threshold analysis via SLM, then outputs CSVs for threshold analysis in R via 'Segmented'. There is another version of the script if you want to run the analysis without matching exercise data - that script will provide basic figure outputs only and no workbook output.
