function data_analysis_SV_v2(chroms_roi1,amap1,bmap1,mua_roi1,mus_roi1,...
    chroms_roi2,amap2,bmap2,mua_roi2,mus_roi2,filename_ROI,A)

fileID = fopen(strcat(filename_ROI,'_ROI','.txt'),'w');
fprintf(fileID,'%s %s %s %s %s\n','chromophore','test (mean)','test (std)','control (mean)','control (std)');
for i=1:4
fprintf(fileID,'%s %d %d %d %d\n',A.out.spec.chrom.names{i},mean(chroms_roi1(:,i)),std(chroms_roi1(:,i)),mean(chroms_roi2(:,i)),std(chroms_roi2(:,i)));
end
fprintf(fileID,'%s %d %d %d %d\n','A',mean(amap1),std(amap1),mean(amap2),std(amap2));
fprintf(fileID,'%s %d %d %d %d\n','b',mean(bmap1),std(bmap1),mean(bmap2),std(bmap2));
fclose(fileID);

fileID = fopen(strcat(filename_ROI,'_op_maps','.txt'),'w');
fprintf(fileID,'%s %s %s %s %s\n','wavelengths','mua_test','mua_control','mus_test','mus_control');
for i=1:length(A.out.data_wv)
fprintf(fileID,'%d %d %d %d %d\n',A.out.data_wv(i),mean(mua_roi1(:,i)),mean(mua_roi2(:,i)),mean(mus_roi1(:,i)),mean(mus_roi2(:,i)));
end
fclose(fileID);

[h1,c1]=hist(mus_roi1(:,1));
[h2,c2]=hist(mus_roi2(:,1));

m1=find(h1==max(h1));
m2=find(h2==max(h2));
if length(m1)>1
    c11=mean(c1(m1));
else
    c11=c1(m1);
end
if length(m2)>1
    c22=mean(c2(m2));
else
    c22=c2(m2);
end
X1=find(mus_roi1(:,1)<c11+0.5 & mus_roi1(:,1)>c11-0.5);
X2=find(mus_roi2(:,1)<c22+0.5 & mus_roi2(:,1)>c22-0.5);



fileID = fopen(strcat(filename_ROI,'_withDA_ROI','.txt'),'w');
fprintf(fileID,'%s %s %s %s %s\n','chromophore','test (mean)','test (std)','control (mean)','control (std)');
for i=1:4
fprintf(fileID,'%s %d %d %d %d\n',A.out.spec.chrom.names{i},mean(chroms_roi1(X1,i)),std(chroms_roi1(X1,i)),mean(chroms_roi2(X2,i)),std(chroms_roi2(X2,i)));
end
fprintf(fileID,'%s %d %d %d %d\n','A',mean(amap1(X1)),std(amap1(X1)),mean(amap2(X2)),std(amap2(X2)));
fprintf(fileID,'%s %d %d %d %d\n','b',mean(bmap1(X1)),std(bmap1(X1)),mean(bmap2(X2)),std(bmap2(X2)));
fclose(fileID);

fileID = fopen(strcat(filename_ROI,'_withDA_op_maps','.txt'),'w');
fprintf(fileID,'%s %s %s %s %s\n','wavelengths','mua_test','mua_control','mus_test','mus_control');
for i=1:length(A.out.data_wv)
fprintf(fileID,'%d %d %d %d %d\n',A.out.data_wv(i),mean(mua_roi1(X1,i)),mean(mua_roi2(X2,i)),mean(mus_roi1(X1,i)),mean(mus_roi2(X2,i)));
end
fclose(fileID);
