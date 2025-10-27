numROIs=roiManager("count");
nr=0;

for (i=0; i<numROIs; i++) {
	roiManager("Select", i);
	Roi.getCoordinates(x, y);
	
    for (j=0; j<x.length; j++) {
		setResult("Label", j+nr, i);
		setResult("X", j+nr, x[j]);
		setResult("Y", j+nr, y[j]);
	}
    nr+=x.length;
	updateResults();
	    
}
