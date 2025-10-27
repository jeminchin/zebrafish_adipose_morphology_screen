################################################################################
### ADIPOSE TISSUE LIPID DROPLET ANALYSIS PIPELINE
### Description: Processes lipid droplet measurements and coordinates from 
###              ImageJ/Fiji analysis, performs statistical analysis comparing
###              control and experimental groups
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


# SECTION 1: MERGE COORDINATES AND MEASUREMENTS ----------------------------
# Merges XY coordinates with lipid droplet measurements for individual fish

merge_fish_data <- function(fish_dir) {
  # Set working directory
  setwd(fish_dir)
  
  # Read CSV files
  coords <- read.csv(file.path(fish_dir, 'coords.csv'), 
                     stringsAsFactors = FALSE)
  measurements <- read.csv(file.path(fish_dir, 'Results.csv'), 
                           stringsAsFactors = FALSE, 
                           check.names = FALSE)
  
  # Rename 'Label' column in measurements to 'image'
  names(measurements)[names(measurements) == "Label"] <- "image"
  
  # Adjust Label values in coords (add 1 to match indices)
  coords$Label <- coords$Label + 1
  
  # Extract numeric ID from first column in measurements
  measurements$match_id <- as.integer(gsub("\\D", "", measurements[[1]]))
  
  # Merge datasets
  merged_data <- merge(coords, measurements, 
                       by.x = 'Label', 
                       by.y = 'match_id')
  
  # Remove temporary match_id column
  merged_data$match_id <- NULL
  
  # Write intermediate merged file
  write.csv(merged_data, 'merged_csv_corrected.csv', row.names = FALSE)
  
  # Select and clean columns
  selected_columns <- merged_data[c('Label', 'X.x', 'Y.x', 'image', 'Area', 
                                    'Perim.', 'Circ.', 'Feret', 'FeretX', 
                                    'FeretY', 'FeretAngle', 'MinFeret', 
                                    'AR', 'Round', 'Solidity', 'MinThr', 'MaxThr')]
  
  # Clean column names (remove .x and .y suffixes)
  names(selected_columns) <- gsub("\\.x|\\.y", "", names(selected_columns))
  
  # Write final merged file
  write.csv(selected_columns, 'final_merged_csv.csv', row.names = FALSE)
  
  message("✓ Merged data for: ", basename(fish_dir))
}


# SECTION 2: PROCESS ALL FISH IN GROUP -------------------------------------
# Adds folder names to CSV files and consolidates them

process_fish_group <- function(root_dir) {
  # Create directory for modified files
  new_dir <- file.path(root_dir, "modified_csv_files")
  if (!dir.exists(new_dir)) {
    dir.create(new_dir)
  }
  
  # Function to copy and rename individual fish files
  process_folder <- function(folder_path) {
    file_path <- file.path(folder_path, "final_merged_csv.csv")
    
    if (file.exists(file_path)) {
      folder_name <- basename(folder_path)
      new_file_name <- paste0(folder_name, "_final_merged_csv.csv")
      new_file_path <- file.path(new_dir, new_file_name)
      file.copy(file_path, new_file_path)
    }
  }
  
  # Get all subdirectories
  subdirs <- list.dirs(root_dir, full.names = TRUE, recursive = TRUE)
  subdirs <- subdirs[subdirs != root_dir]  # Exclude root
  
  # Process each folder
  walk(subdirs, process_folder)
  
  message("✓ Processed all fish files in: ", root_dir)
}


# SECTION 3: ORGANIZE FILES BY IMAGING SESSION -----------------------------
# Renames and moves files to imaging session folder

organize_imaging_session <- function(modified_csv_path) {
  # Get parent folder name
  parent_folder <- basename(dirname(modified_csv_path))
  
  # Create imaging session folder path
  session_folder <- file.path(dirname(dirname(modified_csv_path)), 
                              paste0("imagingSessionCsvs_", parent_folder))
  
  # Create folder if needed
  if (!dir.exists(session_folder)) {
    dir.create(session_folder, recursive = TRUE)
  }
  
  # List all CSV files
  csv_files <- list.files(modified_csv_path, 
                          pattern = "\\.csv$", 
                          full.names = TRUE)
  
  message("Found ", length(csv_files), " CSV files")
  
  # Rename and move each file
  for (file_path in csv_files) {
    file_name <- basename(file_path)
    new_file_name <- paste(parent_folder, file_name, sep = "_")
    new_file_path <- file.path(session_folder, new_file_name)
    
    success <- file.copy(file_path, new_file_path)
    
    if (success) {
      message("✓ Copied: ", file_name)
    } else {
      warning("✗ Failed to copy: ", file_name)
    }
  }
  
  message("✓ All files moved to: ", session_folder)
  return(session_folder)
}


# SECTION 4: REMOVE COORDINATE COLUMNS -------------------------------------
# Creates versions without XY coordinates for easier analysis

remove_coordinates <- function(input_folder) {
  output_folder <- file.path(input_folder, "withoutCoords")
  
  # Check input folder exists
  if (!dir.exists(input_folder)) {
    stop("Input folder does not exist: ", input_folder)
  }
  
  # Create output folder
  if (!dir.exists(output_folder)) {
    dir.create(output_folder, recursive = TRUE)
    message("Created output folder: ", output_folder)
  }
  
  # List all CSV files
  files <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)
  
  if (length(files) == 0) {
    stop("No CSV files found in: ", input_folder)
  }
  
  # Process each file
  for (file in files) {
    data <- read.csv(file)
    
    # Remove X and Y columns if present
    if ("X" %in% names(data) && "Y" %in% names(data)) {
      processed_data <- data %>%
        select(-X, -Y) %>%
        distinct()
    } else {
      processed_data <- data
    }
    
    # Create new filename
    file_name <- basename(file)
    new_file_name <- sub("\\.csv$", "_withoutCoords.csv", file_name)
    new_file_path <- file.path(output_folder, new_file_name)
    
    # Write processed data
    write.csv(processed_data, new_file_path, row.names = FALSE)
    message("✓ Processed: ", file_name)
  }
  
  message("✓ All files saved to: ", output_folder)
  return(output_folder)
}


# SECTION 5: GENERATE SUMMARY STATISTICS -----------------------------------
# Calculates mean values for each fish

generate_summary_stats <- function(input_folder) {
  summary_folder <- file.path(input_folder, "summaryStats")
  
  # Create summary folder
  if (!dir.exists(summary_folder)) {
    dir.create(summary_folder)
  }
  
  # List all CSV files
  files <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)
  
  # Initialize list for summary data
  summary_list <- list()
  
  # Process each file
  for (file in files) {
    data <- read.csv(file)
    
    # Calculate mean for numeric columns
    mean_values <- sapply(data, function(x) {
      if (is.numeric(x)) mean(x, na.rm = TRUE) else NA
    })
    
    # Calculate area sum
    area_sum <- if ("Area" %in% names(data)) {
      sum(data$Area, na.rm = TRUE)
    } else {
      NA
    }
    
    # Create summary dataframe
    mean_df <- data.frame(
      fileName = basename(file), 
      AreaSum = area_sum, 
      t(mean_values)
    )
    
    summary_list[[length(summary_list) + 1]] <- mean_df
  }
  
  # Combine all summaries
  summary_data <- bind_rows(summary_list)
  
  # Write summary file
  output_file <- file.path(summary_folder, "summaryStats.csv")
  write.csv(summary_data, output_file, row.names = FALSE)
  
  message("✓ Summary statistics saved to: ", output_file)
  return(summary_data)
}


# SECTION 6: VISUALIZATION --------------------------------------------------
# Creates exploratory plots

plot_metrics_vs_area <- function(summary_data, output_dir = NULL) {
  # Reshape data to long format
  long_data <- gather(summary_data, 
                      key = "Metric", 
                      value = "Value", 
                      -fileName, -AreaSum)
  
  # Create faceted scatter plot
  p <- ggplot(long_data, aes(x = AreaSum, y = Value)) +
    geom_point() +
    facet_wrap(~ Metric, scales = "free_y") +
    theme_minimal() +
    labs(x = "Area Sum", 
         y = "Value", 
         title = "Metrics vs Total Adipose Area")
  
  print(p)
  
  # Save if output directory specified
  if (!is.null(output_dir)) {
    ggsave(file.path(output_dir, "facet_scatter_plot.png"), 
           plot = p, 
           width = 10, 
           height = 8)
  }
  
  return(p)
}


# SECTION 7: GAM MODELING (CONTROL GROUP) ----------------------------------
# Fits GAM model to control data and generates diagnostic plots

fit_control_model <- function(summary_file, output_dir) {
  # Set working directory
  setwd(output_dir)
  
  # Load data
  data <- read.csv(summary_file)
  
  # Fit GAM model: Feret diameter ~ log(Total Area)
  gam_model <- gam(Feret ~ s(log(AreaSum)), data = data)
  
  # Print model summary
  cat("\n=== GAM Model Summary ===\n")
  print(summary(gam_model))
  print(formula(gam_model))
  
  # Extract residuals
  residuals <- gam_model$residuals
  res_df <- data.frame(residuals = residuals)
  
  # Plot 1: Feret vs AreaSum with GAM fit
  p1 <- ggplot(data, aes(x = AreaSum, y = Feret)) + 
    geom_point(size = 4.5, alpha = 0.15, shape = 16) +
    geom_smooth(se = FALSE, 
                colour = "black", 
                linewidth = 1, 
                method = "gam", 
                formula = y ~ s(log(x))) +
    theme_classic() +
    labs(title = "Lipid Droplet Diameter vs Total Adipose Area",
         x = "Total Adipose Area (µm²)",
         y = "Average Feret Diameter (µm)")
  
  print(p1)
  ggsave("feret_v_areaSum.pdf", plot = p1, width = 5, height = 5)
  
  # Plot 2: Residuals distribution
  x_lim <- c(-40, 40)
  
  p2 <- ggplot(res_df, aes(x = residuals, y = after_stat(density))) + 
    geom_histogram(binwidth = 5, 
                   fill = "white", 
                   colour = "grey", 
                   linewidth = 0.5) +
    geom_density(color = "black", linewidth = 1, adjust = 2) +
    theme_classic() +
    xlim(x_lim) +
    labs(title = "Distribution of Model Residuals",
         x = "Residuals (µm)",
         y = "Density")
  
  print(p2)
  ggsave("av_diam_density.pdf", plot = p2, width = 5, height = 5)
  
  message("✓ Control model fitted and plots saved")
  
  return(list(model = gam_model, residuals = residuals))
}


# SECTION 8: COMPARE EXPERIMENTAL TO CONTROL -------------------------------
# Calculates deviations of experimental group from control model

compare_to_control <- function(control_model, test_summary_file) {
  # Load test data
  data_test <- read.csv(test_summary_file)
  
  # Extract variables
  test_x <- data_test$AreaSum
  test_y <- data_test$Feret
  
  # Predict using control model
  predicted_y <- predict(control_model, 
                         newdata = data.frame(train_x = test_x))
  
  # Calculate deviations
  deviations <- test_y - predicted_y
  
  cat("\n=== Deviations from Control Model ===\n")
  print(summary(deviations))
  
  return(deviations)
}


# SECTION 9: STATISTICAL COMPARISON -----------------------------------------
# Performs statistical tests comparing control and experimental groups

compare_distributions <- function(control_residuals, experimental_deviations, 
                                  output_dir = NULL) {
  
  # Histogram comparison
  hist(control_residuals, 
       col = rgb(0, 0, 1, 0.5), 
       main = "Distribution Comparison",
       xlab = "Residuals/Deviations (µm)",
       xlim = range(c(control_residuals, experimental_deviations)))
  hist(experimental_deviations, 
       col = rgb(1, 0, 0, 0.5), 
       add = TRUE)
  legend("topright", 
         legend = c("Control", "Experimental"), 
         fill = c(rgb(0, 0, 1, 0.5), rgb(1, 0, 0, 0.5)))
  
  # Density plot
  plot(density(control_residuals), 
       col = "blue", 
       main = "Density Comparison", 
       xlab = "Value (µm)", 
       ylab = "Density",
       lwd = 2)
  lines(density(experimental_deviations), 
        col = "red", 
        lwd = 2)
  legend("topright", 
         legend = c("Control", "Experimental"), 
         col = c("blue", "red"), 
         lwd = 2)
  
  # T-test
  cat("\n=== Two-Sample T-Test ===\n")
  t_result <- t.test(control_residuals, experimental_deviations)
  print(t_result)
  
  # Kolmogorov-Smirnov test
  cat("\n=== Kolmogorov-Smirnov Test ===\n")
  ks_result <- ks.test(control_residuals, experimental_deviations)
  print(ks_result)
  
  return(list(t_test = t_result, ks_test = ks_result))
}


################################################################################
# EXAMPLE USAGE WORKFLOW
################################################################################

# Define paths (UPDATE THESE FOR YOUR DATA)
# root_dir <- "C:/Users/james/Desktop/final_processing_check_TEST/20240116_y_NR_40dpf_tatTATsm/group_y"
# fish_dir <- file.path(root_dir, "fish15")

# Step 1: Merge coordinates and measurements for a single fish
# merge_fish_data(fish_dir)

# Step 2: Process all fish in the group
# process_fish_group(root_dir)

# Step 3: Organize by imaging session
# modified_path <- file.path(root_dir, "modified_csv_files")
# session_folder <- organize_imaging_session(modified_path)

# Step 4: Remove coordinates
# data_folder <- remove_coordinates(session_folder)

# Step 5: Generate summary statistics
# summary_data <- generate_summary_stats(data_folder)

# Step 6: Visualize
# plot_metrics_vs_area(summary_data, data_folder)

# Step 7: Fit control model
# summary_file <- file.path(data_folder, "summaryStats", "summaryStats.csv")
# control_results <- fit_control_model(summary_file, 
#                                       file.path(data_folder, "summaryStats"))

# Step 8: Compare experimental group
# test_file <- "path/to/experimental/summaryStats.csv"
# deviations <- compare_to_control(control_results$model, test_file)

# Step 9: Statistical comparison
# stats <- compare_distributions(control_results$residuals, deviations)

################################################################################
# END OF SCRIPT
################################################################################
