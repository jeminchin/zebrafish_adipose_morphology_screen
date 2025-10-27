# Analysis pipelines for image-based adipose morphology screening in zebrafish

This repository contains analysis pipelines for the paper available here: https://doi.org/10.7554/eLife.107327.1

## Input images for screen
1) two images:
      - whole animal
      - zoom LSAT

## Initial processing steps in ImageJ
1) in ImageJ, clearOutside on zoom LSAT image (CO image)
2) perform other processing in IJ, eg filters, sharpening, denoising etc

## Segmentation of LDs in Cellpose
1) open CO image in cellpose
2) run cyto segmentation algorithm
3) save outlines (.txt)
4) save masks (.png)
5) save _seg.npy file (full segmentation file?)

## LD measurements in ImageJ
1) open CO image in IJ
2) run .py script to import outlines into IJ (imagej_roi_converter.py)
3) run XYcoord macro (getFullXyCoords.ijm)
4) save coords as coords.csv
5) clear results in IJ
6) select all ROIs (in ROI manager) and measure ROIs in ROI manager
7) save measurements as Results.csv

## Processing #1: check normality

9) run r script (process_and_check_normal_distribution) to merge coords.csv with Results.csv and clean up (output = final_merged_csv.csv), also to test for normality in both original and transformed data 
    input = final_merged_csv.csv
    output = summary stats from Shapiro Wilks test (text)
    output = graph showing distributions with annotation (saved to working directory)
    
## Processing #2: aggregate and add image details to filename

10) process final_merged_csv.csv files (script) - point the script at an ImagingSession folder (eg, 20230407_1) which contains all image folders from the ImagingSession (contains: CO image, outlines, coords.csv & Results.csv). script will add image number (ie, folder name. Image12) to the final_merged_csv.csv and copy all files to a new folder (modified_csv_files). this is to bring all final_merged_csv.csv files together for further processing.
    script = add_image_imageSession_to_filename
    output = *image#*_final_merged_csv.csv

## Processing #3: add imagingSession details to filename

11) add imagingSession to title and move to parent-level new folder (imagingSessionCsvs)
            - want script to rename *image#*_final_merged_csv.csv files according to imagingSession (eg 20230407_1) folder and save in new foder at level where image_session
    script = script = add_image_imageSession_to_filename
    - output = *imagingSession*_*image*_final_merged_csv.csv
            - this will produce a folder with all fmc files which have imagingSession and image information in title

## Processing #4: remove coords and collapse data

12) run script to remove coords (lots of duplicated rows), this will allow to produce sumamry stats easier
   script = removeCoords_collapseData

## Processing #5: generate summary stats

13) generate summary stats (including mean Feret, sum of Area) in one file
    script = summaryStats

## Processing #6: plot exploratory graphs

14) plot graphs to explore variable relationship with sumArea 
    script = plot_variables_against_sumArea
    
#############################

Calculate regions:
input = final_merged_csv.csv
1) plot XY coordinates (lines not points)
flip coordinates (coords currently top left start, flip to top right so anterior to posterior, dorsal to ventral)
calculate centroids
calculate bounding box (not based on centroids, but based on LD perimeter)
output length and width of sat
calculate regions
calculate mean LDs sizes in regions
calculate metric based on size changes across regions


Stratified sampling:

Calculate sample size needed for true mean (LDs measured):





IJ
1)  tif file
2)  clear outside in IJ
3)  save as CO

Cellpose
4)  open in cellpose
5)  segment
6)  save outlines file (text file)

IJ
7)  open in IJ
8)  run python macro/script in IJ to import outlines
9)  quantify
10) run IJ macro to get full XY coordinates of outlines

R
11) merge outline measurements with coordinates and save as csv
12) 
