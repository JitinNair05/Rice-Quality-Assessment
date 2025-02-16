% Select rice image
[filename, pathname] = uigetfile('*.*', 'Select rice image');

% Check if a file was selected
if isequal(filename,0) || isequal(pathname,0)
    disp('Image selection canceled.');
    return;
end

% Read the selected image
filewithpath = fullfile(pathname, filename);
f = imread(filewithpath);

% Convert to grayscale if RGB
[~, ~, r] = size(f);
if r == 3
    f = rgb2gray(f);
end

% Resize image to have a width of 256 pixels
f = imresize(f, [nan, 256]);

% Binarize the image
fb = imbinarize(f, 'adaptive');

% Fill holes in binary image
fb = imfill(fb, 'holes');

% Erosion to separate touching grains
se = strel('disk', 2);
fe = imerode(fb, se);

% Remove objects touching image border
fecb = imclearborder(fe);

% Check if there are any grains
if nnz(fecb) > 0
    % Label connected components
    [L1, ~] = bwlabel(fecb);
    
    % Compute area of each component
    stats1 = regionprops(L1, 'Area');
    area = [stats1.Area];
    
    % Remove small noise components
    marea = mean(area);
    ba = bwareaopen(L1, round(1.1 * marea));
    
    % Remove background to separate grains
    LL = logical(fecb - ba);
    
    % Label separated grains
    [L2, ~] = bwlabel(LL);
    
    % Compute major and minor axis lengths of grains
    stats2 = regionprops(L2, 'MajorAxisLength', 'MinorAxisLength');
    majoraxis = [stats2.MajorAxisLength];
    minoraxis = [stats2.MinorAxisLength];
    
    % Compute ratio of major to minor axis lengths
    nmr = majoraxis ./ minoraxis;
    
    % Define threshold for good grain length
    thr = 4;
    
    % Count grains with ratio above threshold
    count = nmr > thr;
    
    % Calculate percentage of good grains
    outcome = (nnz(count) / numel(count)) * 100;
    
    % Determine message based on outcome
    if outcome >= 80
        msg = 'Rice is of good quality';
    else
        msg = 'Rice sample is rejected';
    end
else
    msg = 'No rice grains';
end

% Insert message onto image
imgo = insertText(f, [10, 10], msg, 'FontSize', 18, 'TextColor', 'white');

% Display annotated image
imshow(imgo);
