# DOSI-SLM-SegmentedOut
Main method in R-only workflow cleans up DOS data from a Hamamatsu TRS-20, via splitting it by study phases, then runs the threshold analysis in R. Requires matching exercise data. See script comments for specifics. 

# Older Matlab to R workflow
Takes DOSI data, runs Matlab threshold analysis via SLM, then outputs CSVs for threshold analysis in R via 'Segmented'. There is another version of the script if you want to run the analysis without matching exercise data - that script will provide basic figure outputs only and no workbook output.
