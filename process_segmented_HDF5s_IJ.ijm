imgs = getList("image.titles");
for (i = 0; i < imgs.length; i++) {
   setAutoThreshold("Default");
//run("Threshold...");
//setThreshold(0, 1);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Measure");
close;
}
