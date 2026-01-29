# Analysis pipelines for image-based adipose morphology screening in zebrafish

This repository contains analysis pipelines for the paper available here: https://doi.org/10.7554/eLife.107327.1

# Code repository can be found here:

1) morphology screen analysis:
https://github.com/jeminchin/zebrafish_adipose_morphology_screen/tree/main/morphology_crispr_screen_analysis

3) spatial responses to HFD:

# Analysis reports can be found here:

1) morphology screen analysis:
https://jeminchin.github.io/zebrafish_adipose_morphology_screen/CRISPR_screen_analysis_merged_v7.html

2) spatial responses to HFD:
https://jeminchin.github.io/zebrafish_adipose_morphology_screen/foxp1_spatial_analysis_github.html


![2025-04-15_fig3_lsat_growth_v3](https://github.com/user-attachments/assets/a6bb0fa8-5c5d-4cdb-92b3-f08571c49d63)

## Input images for screen
1) two images:
      - whole animal
      - zoom LSAT

## Initial processing steps in ImageJ
1) in ImageJ, clearOutside on zoom LSAT image (CO image)
2) perform additional processing in IJ, eg filters, sharpening, denoising etc

## Segmentation of LDs in Cellpose
1) open CO image in cellpose
2) run cyto segmentation algorithm
3) save outlines (.txt)
4) save masks (.png)
5) save _seg.npy file

## LD measurements in ImageJ
1) open CO image in IJ
2) run imagej_roi_converter.py script to import outlines into IJ
3) run XYcoord macro (getFullXyCoords.ijm)
4) save coords as coords.csv
5) clear results in IJ
6) select all ROIs (in ROI manager) and measure ROIs in ROI manager
7) save measurements as Results.csv

## Processing #1: initialProcessing_summaryStats_GAM_KStest.R
basic workflow for script:
1) Merge coordinates with measurements for each fish (coords.csv & Results.csv)
2) Consolidate all fish data into group folders
3) Generate summary statistics per fish
4) Fit GAM model to control and experimental groups (morphology value)
5) Compare experimental group to control model
6) Perform statistical tests (Kolmogorov-Smirnov test)

## Processing #2: linear_mixed_models.R
basic workflow for script:
1) log transform and linearise SAT area and mean SAT LD diameter
2) perform linear mixed model regression with replicate as random effect

## Processing #3: Benjamini-Hochberg_FDR_correction.R
basic workflow for script:
1) apply BH FDR correction for KS and LMM tests

## Processing #4: defining_strata_and_strataStats.R
basic workflow for script:
1) load LD coords
2) calculate LD centroids
3) calculate 200um strata from anterior-most centroid
4) calculate metrics per strata
5) plot LD coords with strata

## Processing #5: total_adiposity.R
basic workflow for script:
1) to segment total nile red area per fish (ie, total adiposity), use trained model (xx) in Ilastik
2) run Ilastik in headless mode to batch process nile red images
3) export as .HDF5 files
4) run process_segmented_HDF5s_IJ.ijm
5) save output as total_adiposity.csv

