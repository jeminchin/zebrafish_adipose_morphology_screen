# Analysis pipelines for image-based adipose morphology screening in zebrafish

This repository contains analysis pipelines for the paper available here: https://doi.org/10.7554/eLife.107327.1

<img width="1294" height="705" alt="image" src="https://github.com/user-attachments/assets/497e7326-e8ef-43dc-9ba4-03297b5d8e8f" />


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
4) Fit GAM model to control and experimental groups
5) Compare experimental group to control model
6) Perform statistical tests (Kolmogorov-Smirnov test) 

R
11) merge outline measurements with coordinates and save as csv
12) 
