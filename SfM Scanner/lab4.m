
clearvars,
close all,
clc,

addpath('./test/');

images_ = 293:294;
images = cell(numel(images_), 1);

showSURFfeatures = 0;
showRANSACinliers = 1;

for i=1:numel(images_)
    images{i} = imrotate(rgb2gray(imread(strcat('./temple/temple', num2str(images_(i),'%04d'),'.png'))), -90);
end

matchedPoints = surfFeatures(images);

if showSURFfeatures
    for i=1:numel(images)-1
        figure(1);ax = axes; 
        showMatchedFeatures(images{i},images{i+1},matchedPoints{i}{1},matchedPoints{i}{2},'montage','Parent', ax);
        pause(0.1);
    end
    pause(0.8);
   % close all
end

F = {numel(matchedPoints)};
inliers = {numel(matchedPoints)};

for i = 1:numel(matchedPoints)
    try
        image1Coords = matchedPoints{i}{1}.Location';
        image2Coords = matchedPoints{i}{2}.Location';
        [F{i}, inliers{i}] = ransacfitfundmatrix7(image1Coords, image2Coords, 0.01);
        F{i} = estimateFundamentalMatrix(image1Coords, image2Coords);
    catch
        warning('aaaaaaaa');
    end
end

if showRANSACinliers
    for i=1:numel(matchedPoints)
        RANSACinliers1 = matchedPoints{i}{1}.Location;RANSACinliers1 = RANSACinliers1(inliers{i},:);
        RANSACinliers2 = matchedPoints{i}{2}.Location;RANSACinliers2 = RANSACinliers2(inliers{i},:);
        figure(2);ax = axes; 
        showMatchedFeatures(images{i},images{i+1},RANSACinliers1, RANSACinliers2,'montage','Parent', ax);
        pause(0.1);
    end
    pause(0.8)
  %  close all
end

%%%%%%% INTRINSIC CAMERA PARAMETERS (K)
K = [1520.400000 0.000000    302.320000 
     0.000000    1525.900000 246.870000 
     0.000000    0.000000    1.000000];

%Essential matrixes
E = {numel(matchedPoints)};

for i=1:numel(matchedPoints)
   E{i} = transpose(K) * F{i} * K; 
end

P = cell(numel(F)+1,1);
tacc = cell(numel(F)+1,1);
R = cell(numel(F)+1,1);
points3d = cell(numel(F), 1);

P{1} = K*eye(3,4);  %all the cameras will be relative to de origin
[U,S,V] = svd(E{i});
T = U*[0,1,0;-1,0,0;0,0,0]*transpose(U);
R{1} = U*transpose([0,1,0;-1,0,0;0,0,1])*transpose(V);
R{1} = eye(3);
t = zeros(3,1);
Rlast = R{1};
tacc{1} = t;
for i=1:numel(E)
    [U,S,V] = svd(E{i});
    T = U*[0,1,0;-1,0,0;0,0,0]*transpose(U);
    R{i+1} = U*transpose([0,1,0;-1,0,0;0,0,1])*transpose(V);
    tt = null(T);
    t = t+Rlast*tt;
    tacc{i+1} = t;
    Rlast = R{i+1};
    P{i+1} = K*[R{i+1},t];
end

% P{1} = [3058.776820, 19.199695, -1179.568378, 3998.408801;
% 122.756171, -2954.561973, -1047.148435, -2.029950;
% 0.086493, -0.008698, -0.996214, 0.095682];
% 
% P{2} = [2844.993137, -229.034162, -1612.892752, 4514.882954;
% -239.929841, -2975.553107, -964.128417, -864.309903;
% -0.062289, -0.034574, -0.997459, -0.226867];


for i=1:numel(F)

    RANSACinliers1 = matchedPoints{i}{1}.Location;RANSACinliers1 = RANSACinliers1(inliers{i},:);
    RANSACinliers2 = matchedPoints{i}{2}.Location;RANSACinliers2 = RANSACinliers2(inliers{i},:);
    imsize = [size(images{1},1), size(images{1},2)];
    
    points3d{i} = [];
    for j=1:size(RANSACinliers1, 1)
        X = vgg_X_from_xP_nonlin([RANSACinliers1(j,:)', RANSACinliers2(j,:)'],{P{i},P{i+1}},[imsize; imsize]);
        X = X./X(4);
        points3d{i} = [points3d{i}; X(1:3)'];
    end
end

figure(6),
for i=1:numel(F)        %24-25 works pretty well -- 14-15 is also p good
    pcshow(points3d{i}, 'VerticalAxis', 'y', 'VerticalAxisDir', 'down', ...
        'MarkerSize', 120);
    hold on
    colormap winter
end

% pcshow(part1, 'VerticalAxis', 'y', 'VerticalAxisDir', 'down', ...
%     'MarkerSize', 120);
% hold on
% pcshow(part2, 'VerticalAxis', 'y', 'VerticalAxisDir', 'down', ...
%     'MarkerSize', 120);
% colormap winter


tmpAspect=daspect();
daspect(tmpAspect([1 2 2]))

% 
% for i=1:numel(P)
%   cam = plotCamera('Location',tacc{i},'Orientation',R{i},'Opacity',0,'Size',0.05); 
%   drawnow();
% end
% hold off

 



