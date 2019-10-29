# SFDI_ROI
Interactive user interface for ROI selection - test and control

Main function : SFDI_ROI_v4.m
Step 1:
Open SFDI_ROI_v2.m (this is the main code)
 
Put in the processed directory and filename of the results processed by the SFDI code.

 
Add a desired filename (this is where the chromophore results within test and control ROI will get saved).

Step 2:
Run the code.
2 figures will pop up:
 
Figure 1 is the total hemoglobin map and figure 2 is a raw file where you will select ROI on the test leg.

Step 3 a:
Select ROI on the test leg
Pick a few points to complete a polygon that covers the desired ROI (Use single clicks when you do this)
 

Step 3 b:
You can move the vertices around until you are satisfied with the polygon shape. 
 

Step 3 c.
If you hover the mouse over the ROI you will find that the pointer changes to  
You can then move around your ROI on the test leg. 


Step 3 d.
Once you are happy with test leg ROI, right click to open your options menu:
 
Click on save test leg ROI.


Step 3 e.
Double click on the ROI


Step 4 a.
 
The ROI on the control leg automatically pops up.

Step 4 b.
You can adjust the location of the control leg ROI. 
 

Step 4 c.
Once you are happy with the location of the control leg ROI, right click to open the options menu
 

Step 4 d.
Click on save control leg ROI

Step 4 e.
Double click on the ROI.


Step 5.
The selected ROIs will pop up on both figures
 

Step 6:
You will find a text file in the current matlab directory which has the ROI chromophore values saved.
 
The code will also populate a text file containing the absorption and reduced scattering over the regions selected.
 


