% Demo to draw multiple polygons and make a single binary image from them all.
%----- Initializing steps -----
% Clean up
clc;
clear vars;
close all;
workspace; % Display the workspace panel.
fontSize = 20;

hasIPT = license('test', 'image_toolbox');
if ~hasIPT
	% User does not have the toolbox installed.
	message = sprintf('Sorry, but you do not seem to have the Image Processing Toolbox.\nDo you want to try to continue anyway?');
	reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
	if strcmpi(reply, 'No')
		% User said No, so exit.
		return;
	end
end

% Display images to prepare for the demo.
originalImage = imread('coins.png');
[rows, columns, numberOfColorChannels] = size(originalImage);
subplot(2, 2, 1);
imshow(originalImage);
title('Original Image.  DRAW POLYGON HERE!!!', 'FontSize', fontSize);
subplot(2, 2, 2);
imshow(originalImage);
subplot(2, 2, 4);
imshow(originalImage);
title('Original Image with regions burned into image', 'FontSize', fontSize);
set(gcf, 'units','normalized','outerposition',[0 0 1 1]); % Maximize figure.
set(gcf,'name','Image Analysis Demo','numbertitle','off') 

%----- Ask user to draw polygons ---------------------------------------------------------------------
% Create a binary image for all the regions we will draw.
cumulativeBinaryImage = false(rows, columns);
subplot(2, 2, 4);
imshow(cumulativeBinaryImage);
title('Cumulative Binary Image', 'FontSize', fontSize);
% Create region mask, h, as an ROI object over the second image in the bottom row.
axis on;
again = true;
regionCount = 0;
while again && regionCount < 20
	promptMessage = sprintf('Draw region #%d in the upper right image,\nor Quit?', regionCount + 1);
	titleBarCaption = 'Continue?';
	button = questdlg(promptMessage, titleBarCaption, 'Draw', 'Quit', 'Draw');
	if strcmpi(button, 'Quit')
		break;
	end
	regionCount = regionCount + 1;

	% Ask user to draw freehand mask.
	message = sprintf('Left click vertices in the upper left image.\nRight click the last vertex to finish.\nThen double click in the middle to accept it.');
	uiwait(msgbox(message));
	subplot(2, 2, 1); % Switch to image axes.
	% Ask user to draw a polygon.
	% Use roipolyold() if you want to finish at the right click
	% and not have the user need to double-click inside the shape to confirm it.
% 	[thisSinglePolygonImage, xi, yi] = roipolyold();
	% Use roipoly() if you want to close the polygon at the right click
	% but give the user the opportunity to adjust the positions of the vertices, and then
	% the user needs to double-click inside the shape to confirm/accpet it.
	[thisSinglePolygonImage, xi, yi] = roipoly();
	% Display the last drawn polygon.
	subplot(2, 2, 3);
	imshow(thisSinglePolygonImage);
	caption = sprintf('Binary mask you just drew');
	title(caption, 'FontSize', fontSize);
	
	% Draw the polygon over the image in the upper right.
	subplot(2, 2, 2); % Switch to upper right image axes.
	hold on;
	plot(xi, yi, 'r-', 'LineWidth', 2);

	caption = sprintf('Original Image with %d regions in overlay.', regionCount);
	title(caption, 'FontSize', fontSize);

	% OR it in to the "all regions" binary image mask we're building up.
	cumulativeBinaryImage = cumulativeBinaryImage | thisSinglePolygonImage;
	% Display the regions mask.
	subplot(2, 2, 4);
	imshow(cumulativeBinaryImage);
	caption = sprintf('Binary mask of the %d regions', regionCount);
	title(caption, 'FontSize', fontSize);
end
% cumulativeBinaryImage is your final binary image mask that contains all the individual masks you drew.