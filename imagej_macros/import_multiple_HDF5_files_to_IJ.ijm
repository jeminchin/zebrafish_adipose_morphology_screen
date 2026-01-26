// tested with ilastik plugin version 1.8.2
// macro works to import multiple hdf5 files

#@ File (label = "Input directory", style = "directory") input_dir

processFolder(input_dir);

// function to scan folder to find files with correct suffix
function processFolder(input_dir) {
	suffix = ".h5";
	list = getFileList(input_dir);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			processFile(input_dir, list[i]);
	}
}

function processFile(input, file) {
	inputFilePath = input + File.separator + file;
	print("Processing: " + inputFilePath);
	run("Import HDF5", "select=[" + inputFilePath + "] datasetname=/exported_data axisorder=yxc");
	//run("Import HDF5", "select=" + inputFilePath + " datasetname=/exported_data axisorder=yxc");
}
