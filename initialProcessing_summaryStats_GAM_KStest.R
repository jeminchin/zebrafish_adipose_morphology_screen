################################################################################
###                    ADIPOSE TISSUE LIPID DROPLET ANALYSIS                 ###
###                                                                          ###
################################################################################
###                                                                          ###
### PURPOSE: This script processes lipid droplet measurements from ImageJ    ###
###          output, merges with coordinate data, generates summary          ###
###          statistics, fits GAM models, and compares experimental groups   ###
###                                                                          ###
### INPUT FILES:                                                             ###
###   - coords.csv: XY coordinates of lipid droplets                         ###
###   - Results.csv: ImageJ measurements (Area, Feret, etc.)                 ###
###                                                                          ###
### WORKFLOW:                                                                ###
###   1. Merge coordinates with measurements for each fish                   ###
###   2. Consolidate all fish data into group folders                        ###
###   3. Generate summary statistics per fish                                ###
###   4. Fit GAM model to control group                                      ###
###   5. Compare experimental group to control model                         ###
###   6. Perform statistical tests                                           ###
###                                                                          ###
################################################################################

# Load Required Libraries --------------------------------------------------
library(dplyr)
library(ggplot2)
library(MASS)
library(gridExtra)
library(mgcv)
library(pwr)
library(purrr)
library(tools)
library(tidyr)


################################################################################
# SECTION 1: MERGE COORDINATES AND MEASUREMENTS
################################################################################
# PURPOSE: Combines XY coordinate data with lipid droplet measurements
# INPUT: coords.csv (coordinates) + Results.csv (ImageJ measurements)
# OUTPUT: final_merged_csv.csv (combined data for one fish)
#
# NOTE: This section needs to be run for EACH fish individually
#       Update the file paths for each fish before running
################################################################################

# Iterate the code below over each fish file within the group folder
# IMPORTANT: Change 'fish15' to the appropriate fish number for each run

setwd("set_working_directory_here")

# Read the CSV files
csv1 <- read.csv('your_working_directory/coords.csv', stringsAsFactors = FALSE)
csv2 <- read.csv('your_working_directory/Results.csv', stringsAsFactors = FALSE, check.names = FALSE)

# Rename the 'Label' column in csv2 to 'image' (if it needs to be retained)
names(csv2)[names(csv2) == "Label"] <- "image"

# Adjust the 'Label' values in csv1 by adding 1 (to match with csv2 indices)
csv1$Label <- csv1$Label + 1

# Extract the numeric part from the first unnamed column in csv2
csv2$match_id <- as.integer(gsub("\\D", "", csv2[[1]]))

# Merge csv1 and csv2 using the 'Label' column from csv1 and the 'match_id' from csv2
merged_csv <- merge(csv1, csv2, by.x = 'Label', by.y = 'match_id')

# Remove the 'match_id' column if it's not needed in the final output
merged_csv$match_id <- NULL


################################################################################
# SECTION 2: SELECT AND CLEAN COLUMNS
################################################################################
# PURPOSE: Keeps only relevant measurement columns and cleans column names
# OUTPUT: Writes merged_csv_corrected.csv and final_merged_csv.csv
################################################################################

# Write the merged data to an intermediate CSV file
# This preserves all columns before selection (backup step)

write.csv(merged_csv, 'merged_csv_corrected.csv', row.names = FALSE)

# Assuming 'merged_csv' is your merged data frame
# Select only the necessary columns
# Label: Droplet ID number
# X, Y: Spatial coordinates
# image: Source image filename
# Area: Droplet area (µm²)
# Perim.: Perimeter length (µm)
# Circ.: Circularity (1.0 = perfect circle)
# Feret: Maximum caliper diameter (µm)
# FeretX, FeretY: Coordinates of Feret diameter endpoints
# FeretAngle: Angle of Feret diameter
# MinFeret: Minimum caliper diameter (µm)
# AR: Aspect Ratio (length/width)
# Round: Roundness (inverse of aspect ratio)
# Solidity: Convexity measure
# MinThr, MaxThr: Threshold values used

selected_columns <- merged_csv[c('Label', 'X.x', 'Y.x', 'image', 'Area', 'Perim.', 'Circ.', 'Feret', 
                                 'FeretX', 'FeretY', 'FeretAngle', 'MinFeret', 
                                 'AR', 'Round', 'Solidity', 'MinThr', 'MaxThr')]

# Clean up column names by removing '.x' and '.y'
names(selected_columns) <- gsub("\\.x|\\.y", "", names(selected_columns))

# Write the cleaned and selected data to a new CSV file
write.csv(selected_columns, 'final_merged_csv.csv', row.names = FALSE)

#once have final_merged_csv.csv files for all fish, move to next step


################################################################################
# SECTION 3: CONSOLIDATE FISH DATA FILES
################################################################################
# PURPOSE: Collects final_merged_csv.csv from all fish folders and adds
#          folder names to filenames for tracking
# OUTPUT: modified_csv_files/ folder containing all renamed fish files
################################################################################

# R script to process final_merged_csv.csv files
# Script will add folder name to the csv file and save them to a single folder

# Define the root directory containing all the fish folders
# This should be the parent directory that contains fish1, fish2, fish3, etc.
root_directory <- "your_parent_directory_here" # Update this path to parent directory

# Create a new directory for modified files
new_directory <- file.path(root_directory, "modified_csv_files")
if(!dir.exists(new_directory)) {
  dir.create(new_directory)
}

# Function to append folder name to filename and copy file to new directory
process_folder <- function(folder_path) {
  file_path <- file.path(folder_path, "final_merged_csv.csv")
  
  # Check if the file exists
  if(file.exists(file_path)) {
    folder_name <- basename(folder_path)
    new_file_name <- paste0(folder_name, "_final_merged_csv.csv")
    new_file_path <- file.path(new_directory, new_file_name)
    
    # Copy and rename the file to the new directory
    file.copy(file_path, new_file_path)
  }
}

# Get list of all subdirectories in the root directory
subdirectories <- list.dirs(root_directory, full.names = TRUE, recursive = TRUE)

# Exclude the root directory from the list
subdirectories <- subdirectories[subdirectories != root_directory]

# Process each folder
walk(subdirectories, process_folder)

# produces modified csv files to folder
# works, moves fish modified csv files to new folder in parent directory


################################################################################
# SECTION 4: ORGANISE BY IMAGING SESSION
################################################################################
# PURPOSE: Prepends parent folder name to each file and moves to imaging
#          session folder for better organization
# OUTPUT: imagingSessionCsvs_group_Y/ folder with renamed files
################################################################################

# Set the path to the 'modified_csv_files' folder created in Section 3
modified_csv_files_path <- "path_to/modified_csv_files"

# Identify the parent folder name
parent_folder <- basename(dirname(modified_csv_files_path))

# Create a path for the 'imagingSessionCsvs' folder
imagingSessionCsvs_path <- file.path(dirname(dirname(modified_csv_files_path)), "imagingSessionCsvs_group_insert_your_group_here")

# Create the folder if it doesn't exist
if (!dir.exists(imagingSessionCsvs_path)) {
  dir.create(imagingSessionCsvs_path, recursive = TRUE)
}

# List all CSV files in the 'modified_csv_files' folder
csv_files <- list.files(modified_csv_files_path, pattern = "\\.csv$", full.names = TRUE)

# Check how many files found
cat("Found", length(csv_files), "CSV files in:", modified_csv_files_path, "\n")

# Rename and move each file
for (file_path in csv_files) {
  file_name <- basename(file_path)
  new_file_name <- paste(parent_folder, file_name, sep = "_")
  new_file_path <- file.path(imagingSessionCsvs_path, new_file_name)
  
  # Copy and rename the file
  success <- file.copy(file_path, new_file_path)
  
  # Print debugging info
  cat("Copying:\n  FROM:", file_path, "\n  TO:  ", new_file_path, "\n")
  if (success) {
    cat("✅ File copied successfully.\n\n")
  } else {
    cat("❌ Copy failed!\n\n")
  }
}

# Print completion message
cat("✅ All files processed. Renamed and moved to:", imagingSessionCsvs_path, "\n")


######################################
# CHECKPOINT: All fish data now consolidated in imaging session folder
######################################


################################################################################
# SECTION 5: REMOVE COORDINATE COLUMNS
################################################################################
# PURPOSE: Creates versions of the files without X and Y coordinates
#          This makes the files smaller and easier to analyze
# OUTPUT: withoutCoords/ subfolder with coordinate-free versions
################################################################################

# Set the folder path containing CSV files from Section 4
folder_path <- "path_to/imagingSessionCsvs_group_your_group_here"
output_folder <- file.path(folder_path, "withoutCoords")

# ✅ Check if input folder exists
if (!dir.exists(folder_path)) {
  stop("❌ Input folder does not exist: ", folder_path)
}

# ✅ Create output folder (and parents if needed)
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
  cat("📁 Created output folder:", output_folder, "\n")
}

# ✅ List all CSV files in the input folder
files <- list.files(folder_path, pattern = "\\.csv$", full.names = TRUE)

# ✅ Check if any files found
if (length(files) == 0) {
  stop("❌ No CSV files found in:", folder_path)
}

# ✅ Process each file
for (file in files) {
  # Read the CSV file
  data <- read.csv(file)
  
  # Remove 'X' and 'Y' columns if present
  if ("X" %in% names(data) && "Y" %in% names(data)) {
    processed_data <- data %>%
      dplyr::select(-X, -Y) %>%
      dplyr::distinct()
    
  } else {
    processed_data <- data
  }
  
  # Create new filename with _withoutCoords suffix
  file_name <- basename(file)
  new_file_name <- sub("\\.csv$", "_withoutCoords.csv", file_name)
  new_file_path <- file.path(output_folder, new_file_name)
  
  # Write the processed data
  write.csv(processed_data, new_file_path, row.names = FALSE)
  
  # Feedback per file
  cat("✅ Processed:", file_name, "→", new_file_name, "\n")
}

# ✅ Done
cat("\n🎉 All files processed and saved to:", output_folder, "\n")


################################################################################
# SECTION 6: GENERATE SUMMARY STATISTICS
################################################################################
# PURPOSE: Calculate mean values for each fish and total adipose area
# INPUT: Individual fish CSV files (one row per lipid droplet)
# OUTPUT: summaryStats.csv (one row per fish with mean measurements)
#
# This aggregates thousands of individual droplet measurements into
# single representative values per fish for statistical analysis
################################################################################

# Generate mean values for each fish and save in summaryStats.csv (one file per group)

# Set the folder path containing CSV files without coordinates
folder_path <- "path_to/withoutCoords"
summary_folder <- "path_to/withoutCoords/summaryStats"

# Create a list of all CSV files in the folder
files <- list.files(folder_path, pattern = "\\.csv$", full.names = TRUE)

# Initialize an empty list to store data frames
summary_list <- list()

# Iterate over each file
for (file in files) {
  # Read the CSV file
  data <- read.csv(file)
  
  # Calculate mean for each column, skipping non-numeric columns
  mean_values <- sapply(data, function(x) if(is.numeric(x)) mean(x, na.rm = TRUE) else NA)
  
  # Calculate the sum of the 'Area' column, if it exists
  area_sum <- if("Area" %in% names(data)) sum(data$Area, na.rm = TRUE) else NA
  
  # Create a data frame for the mean values and area sum
  mean_df <- data.frame(fileName = basename(file), AreaSum = area_sum, t(mean_values))
  
  # Add the data frame to the list
  summary_list[[length(summary_list) + 1]] <- mean_df
}

# Bind all data frames in the list into one data frame
summary_data <- bind_rows(summary_list)

# Create summaryStats folder if it doesn't exist
if (!dir.exists(summary_folder)) {
  dir.create(summary_folder)
}

# Write the summary data to new CSV file
write.csv(summary_data, file.path(summary_folder, "summaryStats.csv"), row.names = FALSE)

# Print completion message
print("Summary statistics generated")


################################################################################
# SECTION 7: EXPLORATORY VISUALISATION
################################################################################
# PURPOSE: Create faceted scatter plots to explore relationships between
#          all metrics and total adipose area
# OUTPUT: Multi-panel plot showing each metric vs AreaSum
################################################################################

# Generate some summary plots to explore the data

# Read the summary statistics data
data <- read.csv("path_to/withoutCoords/summaryStats/summaryStats.csv")

# Reshape the data from wide to long format
# Excluding 'fileName' and 'AreaSum' columns from reshaping
long_data <- gather(data, key = "Metric", value = "Value", -fileName, -AreaSum)

# Create the scatter plot with facets
p <- ggplot(long_data, aes(x = AreaSum, y = Value)) +
  geom_point() +  # Scatter plot
  facet_wrap(~ Metric, scales = "free_y") +
  theme_minimal() +
  labs(x = "Area Sum", y = "Value", title = "Facet Scatter Plot of Various Metrics vs Area Sum")

# Print the plot
print(p)

# Save the plot as a PNG file
# ggsave("facet_scatter_plot.png", plot = p, width = 10, height = 8)


## CHECKPOINT: Data exploration complete, moving to statistical modeling


################################################################################
# SECTION 8: FIT GAM MODEL TO CONTROL DATA
################################################################################
# PURPOSE: Establish baseline relationship between adipose area and
#          lipid droplet size using control (wild-type) fish
# MODEL: Feret diameter ~ s(log(AreaSum))
#        This models how droplet size scales with total adipose tissue
# OUTPUT: GAM model object, diagnostic plots, residuals
#
# The log transformation accounts for allometric (non-linear) scaling
# The smooth spline s() allows flexible non-linear relationships
################################################################################

# Set working directory to the summary statistics folder
setwd("path_to/withoutCoords/summaryStats")

# Load the summaryStats CSV file
data <- read.csv("summaryStats.csv")

# code below is for baseline (control) data

# plot adipose area versus average LD diameter. fit a log curve
ggplot(data, aes(x = AreaSum, y = Feret)) + 
  geom_point(size = 4.5, alpha = 0.15, shape = 16) +
  geom_smooth(se = FALSE, colour = "Black", size = 1, method = "gam", formula = y ~ s(log(x))) +
  theme_classic()

# print the graph
pdf("feret_v_areaSum.pdf", width = 5, height = 5)
print(ggplot(data, aes(x = AreaSum, y = Feret)) + 
        geom_point(size = 4.5, alpha = 0.15, shape = 16) +
        geom_smooth(se = FALSE, colour = "Black", size = 1, method = "gam", formula = y ~ s(log(x))) +
        theme_classic())
dev.off()

# gam model
gam_model <- gam(Feret ~ s(log(AreaSum)), data = data)
head(gam_model)
str(gam_model)

# provide various summaries of gam model
summary(gam_model)
print(formula(gam_model))

# plot histogram of residuals using base r
hist(gam_model[["residuals"]])

residuals <- gam_model[["residuals"]]

# convert residuals into df to plot in ggplot
res <- data.frame(residuals)

x_min <- -40
x_max <- 40

# plot residuals in ggplot. use density instead of counts so that curve and bars are the same scale
ggplot(res, aes(x = gam_model[["residuals"]], y = ..density..)) + 
  geom_histogram(binwidth = 5, fill = "White", colour = "Grey", linewidth = 0.5) +
  geom_density(color = "Black", size = 1, adjust = 2) +
  theme_classic() +
  xlim(x_min, x_max)

# print the graph
pdf("av_diam_density.pdf", width = 2.5, height = 5)
print(ggplot(res, aes(x = gam_model[["residuals"]], y = ..density..)) + 
        geom_histogram(binwidth = 5, fill = "White", colour = "Grey", linewidth = 0.5) +
        geom_density(color = "Black", size = 1, adjust = 2) +
        theme_classic()) +
        xlim(x_min, x_max)
dev.off()

# CHECKPOINT: Control model established


################################################################################
# SECTION 9: CALCULATE DEVIATIONS FOR EXPERIMENTAL GROUP
################################################################################
# PURPOSE: Compare experimental (CRISPR, mutant, treated) fish to control
# METHOD: Use control GAM model to predict expected values for experimental
#         fish, then calculate deviations (observed - expected)
# OUTPUT: Deviation values for each experimental fish
#
# INTERPRETATION:
#   - Positive deviations = larger droplets than expected for that adipose area
#   - Negative deviations = smaller droplets than expected
#   - This controls for the confounding effect of total adipose area
################################################################################

# Calculate the deviations from a model fitted to a different set of data

# Training data (control)
# These are the control fish data used to build the reference model
train_x <- data$AreaSum
train_y <- data$Feret


# ============================================================================
# Ready to process CRISPR/experimental group
# ============================================================================

# Test data (experimental group)
# Option 1: Manually enter test data (currently commented out)
# test_x <- c(425.865528, 4748.082372, 268081.4232, 61420.39636, 665993.9318, 1031758.395, 1084956.16, 1536687.96, 955638.4678)
# test_y <- c(17.200656, 19.25566971, 56.2344882, 34.54032323, 70.69210088, 89.83134188, 71.16729231, 92.4565455, 69.63444135)

# Option 2: Load the data from a summaryStats CSV file with headers
# IMPORTANT: Change this path to your experimental group's summaryStats.csv
# Currently using same file as control (placeholder - should be different file)
data_test <- read.csv("path_to/withoutCoords/summaryStats/summaryStats.csv")

# Assign the columns to test_x and test_y using column names
test_x <- data_test$AreaSum
test_y <- data_test$Feret

# Fit a GAM model to the training data
model <- gam(train_y ~ s(log(train_x)), data = data.frame(train_x = train_x, train_y = train_y))

# Predict the values for the test data using the fitted model
predicted_y <- predict(model, newdata = data.frame(train_x = test_x))

# Calculate the deviations
deviations <- test_y - predicted_y

# Display deviations
print(deviations)

hist(deviations)

# convert residuals into df to plot in ggplot
devs <- data.frame(deviations)

# plot residuals in ggplot. use density instead of counts so that curve and bars are the same scale
ggplot(devs, aes(x = test_x, y = ..density..)) + 
  geom_histogram(binwidth = 5, fill = "White", colour = "Grey", linewidth = 0.5) +
  geom_density(color = "Black", size = 1, adjust = 1.5) +
  theme_classic() +
  xlim(x_min, x_max)


################################################################################
# SECTION 10: COMPARE CONTROL VS EXPERIMENTAL DISTRIBUTIONS
################################################################################
# PURPOSE: Visual and statistical comparison of residuals vs deviations
# METHODS: 
#   - Overlapping histograms
#   - Density curves
#   - Two-sample t-test (tests if means differ)
#   - Kolmogorov-Smirnov test (tests if distributions differ)
################################################################################

# Plot overlapping histograms to visualize residuals and deviations
# Blue = control residuals, Red = experimental deviations
hist(residuals, col = "blue")
hist(deviations, col = "red", add = TRUE)

# res <- as.numeric(res)

# Plotting density curves
plot(density(residuals), col = "blue", main = "Density Curve of Two Groups", xlab = "Value", ylab = "Density")
lines(density(deviations), col = "red")

result <- t.test(residuals, deviations)

# Print the t-test result
print(result)

# Perform Kolmogorov-Smirnov test
ks_test <- ks.test(residuals, deviations)

# Print the test result
print(ks_test)


################################################################################
# END OF SCRIPT
################################################################################
#
# SUMMARY OF OUTPUTS:
#   - final_merged_csv.csv: Per-fish merged data (coordinates + measurements)
#   - summaryStats.csv: Per-fish summary statistics
#   - feret_v_areaSum.pdf: Scatter plot with GAM fit
#   - av_diam_density.pdf: Residual distribution plot
#   - Statistical test results: t-test and K-S test
#
################################################################################
