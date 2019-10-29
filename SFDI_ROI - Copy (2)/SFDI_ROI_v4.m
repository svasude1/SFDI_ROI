%% SFDI_code processed directory
par_dir='C:\Data\NIRS_June_July\PAD_Day3\PROCESSED\ApoE#561\190617';
processed_basename='Demo1_2019.06.17.05.35.25_3pro-rep_0';
filename_ROI='ApoE561_Day3';
processed_out_mat_file=strcat(par_dir,'\',processed_basename,'\',processed_basename,'_out.mat');
%% load processed data
A=load(processed_out_mat_file);

%% display Reflectance colormap gray
figure;
miImage(A.out.R_d(:,:,1,1),2);
colormap gray

%% display scattering map for one wavelength
figure;
miImage(A.out.op_maps(:,:,1,2),1.5);
colorbar
colormap jet
title('select ROI on the test leg');
[BW, xi2, yi2]=roipoly_sv;
yi2_width=yi2-(size(BW,1)/2);
yi22=(size(BW,1)/2)-yi2_width;
save('yi22','yi22');
title('select ROI on the control leg');
[BW, xi2_v2, yi2_v2]=roipoly_sv2;

%% two region of interests will be selected on each mice model - test and control
%% control
xdata=[1,size(BW,2)];
ydata=[1,size(BW,1)];
xi=xi2_v2;
num_cols=size(BW,2);
roix = axes2pix(num_cols, xdata, xi);
yi=yi2_v2;
num_rows=size(BW,1);
roiy = axes2pix(num_rows, ydata, yi);
d2 = poly2mask(roix, roiy, num_rows, num_cols);
clear roix roiy xi yi;

%% test
xi=xi2;
roix = axes2pix(num_cols, xdata, xi);
yi=yi2;
roiy = axes2pix(num_rows, ydata, yi);
d1 = poly2mask(roix, roiy, num_rows, num_cols);

%% hold on and display rois on figure 1
figure(1);
hold on;
plot(xi2,yi2,'linewidth',1.4)
hold on
plot(xi2_v2,yi2_v2,'linewidth',1.4)

%% hold on and display rois on figure 2
figure(2);
hold on;
plot(xi2,yi2,'linewidth',1.4)
hold on
plot(xi2_v2,yi2_v2,'linewidth',1.4)


m=1;
n=1;
for i=1:size(BW,1)
    for j=1:size(BW,2)
        if d1(i,j)==1
            chroms_roi1(m,:)=A.out.spec.chrom_maps(i,j,:);
            amap1(m,:)=A.out.A_map(i,j);
            bmap1(m,:)=A.out.b_map(i,j);
            mua_roi1(m,:)=A.out.op_maps(i,j,:,1);
            mus_roi1(m,:)=A.out.op_maps(i,j,:,2);
            m=m+1;
        end
        if d2(i,j)==1
            chroms_roi2(n,:)=A.out.spec.chrom_maps(i,j,:);
            amap2(n,:)=A.out.A_map(i,j);
            bmap2(n,:)=A.out.b_map(i,j);
            mua_roi2(n,:)=A.out.op_maps(i,j,:,1);
            mus_roi2(n,:)=A.out.op_maps(i,j,:,2);
            n=n+1;
        end
    end
end

data_analysis_SV_v2(chroms_roi1,amap1,bmap1,mua_roi1,mus_roi1,...
    chroms_roi2,amap2,bmap2,mua_roi2,mus_roi2,filename_ROI,A);


%% this data is documented for further data analysis
%%%%%%%%%%%%%%%%%%%%saving rois%%%%%%%%%%%%%%%%%%%%%
save(strcat(filename_ROI,'_chroms_roi_test'),'chroms_roi1');
save(strcat(filename_ROI,'_chroms_roi_control'),'chroms_roi2');
save(strcat(filename_ROI,'_amap_test'),'amap1');
save(strcat(filename_ROI,'_amap_control'),'amap2');
save(strcat(filename_ROI,'_bmap_test'),'bmap1');
save(strcat(filename_ROI,'_bmap_control'),'bmap2');
%%%%%%optical properties%%%%%%%%%%%%%%%
save(strcat(filename_ROI,'_mua_roi_test'),'mua_roi1');
save(strcat(filename_ROI,'_mua_roi_control'),'mua_roi2');
save(strcat(filename_ROI,'_mus_roi_test'),'mus_roi1');
save(strcat(filename_ROI,'_mus_roi_control'),'mus_roi2');