function test_vbm8

if 1
%V = spm_vol('/Users/gaser/Desktop/SVE.LPBA40.testdata/S01.native.mri.nii');
%V = spm_vol('t1_icbm_normal_1mm_pn3_rf20.nii');
V = spm_vol('s07.nii');
%V = spm_vol('t1_icbm_masked_1mm_pn3_rf20.nii');
%V = spm_vol('Mary_brain.nii');
%V = spm_vol('t1_icbm_normal_1mm_pn3_rf20.nii');
%V = spm_vol('/Users/gaser/Desktop/A080105/wmA080105_affine.img');
%V = spm_vol('wmA080105_affine.img');
%V = spm_vol('w05.img');

vol = spm_read_vols(V);

Vmask = spm_vol('brainmask_LPBA40.nii');
mask = zeros(V(1).dim(1:3),'uint8');

Vpriors = spm_vol(str2mat('TPM.nii,1',...
    'TPM.nii,2',...
    'TPM.nii,3',...
    'TPM.nii,4',...
    'TPM.nii,5',...
    'TPM.nii,6'));
priors = zeros([V(1).dim(1:3) 6],'uint8');

for j=1:V(1).dim(3),

    Mi  = spm_matrix([0 0 j]);

    % Load slice j from all images
    M1  = V(1).mat\Vpriors(1).mat\Mi;
    mask(:,:,j) = uint8(round(255*spm_slice_vol(Vmask,M1,V(1).dim(1:2),[1 0])));
    for i=1:6
        priors(:,:,j,i) = uint8(round(255*spm_slice_vol(Vpriors(i),M1,V(1).dim(1:2),[1 0])));
    end
end

% dilate the mask by convolving
k = [1 1 1 1 1];
spm_conv_vol(mask,mask,k,k,k,-[1 1 1]);

vx = sqrt(sum(V(1).mat(1:3,1:3).^2));

save all
else
	clear all
	load all
end

slice = 80;
figure(1)
colormap(hot)

ind = find(mask > 32);

!rm *.mexmaci
pve = 1;
method = 3;
warp = 0;
%priors = uint8(0);
%mask(:) = 0;
tic;prob = PveAmapMex(vol, priors, mask, vx, pve, method, warp);toc

subplot(2,2,3)
imagesc(vol(:,:,slice))
axis image
[h,x] = hist(vol(ind),255);

V.fname = 'amap.nii';
V.pinfo = [1 0 0]';
%spm_write_vol(V,prob(:,:,:,2));
%spm_write_vol(V,label);
load all
subplot(2,2,1)
imagesc(vol(:,:,slice).*double(mask(:,:,slice)>32))
axis image
subplot(2,2,2)
h2 = hist(vol(ind),x);
plot([h(2:end);h2(2:end)]')
subplot(2,2,4)
imagesc(prob(:,:,slice,2))
axis image

end