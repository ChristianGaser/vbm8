function OV = cg_slover(OV, options);
% wrapper for slover
%__________________________________________________________________________
% Christian Gaser
% $Id: cg_slover.m 153 2009-09-03 22:49:18Z gaser $

rev = '$Rev: 153 $';

if nargin == 0

    imgs = spm_select(2, 'image', 'Select structural and overlay image');
    OV = pr_basic_ui(imgs,0);

    % set options
    options.opacity = 1;
    options.reference_image = imgs(1,:);
    options.reference_range = OV.img(1).range';
    options.name = imgs(2:end,:);
    options.cmap = OV.img(2).cmap;
    options.range = OV.img(2).range';
    options.slices_str = '';
    options.transform = OV.transform;
end

spm_input('!SetNextPos', 1);

% check filename whether log. scaling was used
options.logP = zeros(size(options.name,1));
for i=1:size(options.name,1)
    if findstr(options.name(i,:),'logP')
        options.logP(i) = 1;
    end
end

% check fields of OV structure
fieldnames = str2mat('reference_image','reference_range',...
    'opacity','cmap','name','range','logP','slices_str','transform');
for i=1:size(fieldnames,1)
    str = deblank(fieldnames(i,:));
    if ~isfield(options,str)
        error([str ' not defined']);
    end
end

cmap_bivariate = [1-(hot); hot]; % colormap if range(1) < 0 

if isfield(options,'labels')
	OV.labels = options.labels;
end

if isfield(options,'cbar')
	OV.cbar = options.cbar;
else
	OV.cbar = 2;	% colorbar
end

n = size(options.name,1);

str = deblank(options.name(1,:));
for i = 2:n, str = [str '|' deblank(options.name(i,:))]; end

if n>1
  sel = spm_input('Select image','+1','m',str);
else
  sel = 1;
end
nm = deblank(options.name(sel,:));

if size(options.logP,1) > 1
    logP = options.logP(sel);
else
    logP = options.logP;
end

[path tmp ext] = fileparts(nm);
img = nm;

n_slice = size(options.slices_str,1);

if n_slice > 0
    for i=1:n_slice, slices{i} = eval(options.slices_str(i,:)); end
else
    slices{1} = OV.slices;
end

sl_name = [];
for i=1:size(options.transform,1)
    if n_slice > 0
        sl_name = strvcat(sl_name,[options.transform(i,:) ': ' options.slices_str(i,:)]);
    else
        sl_name = strvcat(sl_name,[options.transform(i,:)]);
    end
end

str_select = deblank(sl_name(1,:));
for i = 2:n_slice, str_select = [str_select '|' deblank(sl_name(i,:))]; end
ind = spm_input('Select slices','+1','m',str_select);
OV.transform = deblank(options.transform(ind,:));
slices = slices{ind};

OV.img(1).vol = spm_vol(options.reference_image);
OV.img(1).prop = 1;
OV.img(1).cmap = gray(128);
OV.img(1).range = options.reference_range;

OV.img(2).vol = spm_vol(img);

OV.img(2).prop = options.opacity;   % transparent overlay
OV.img(2).cmap = options.cmap;	    % colormap

if ~isfield(options,'range')
	  [mx mn] = volmaxmin(OV.img(2).vol)
    options.range = spm_input('Intensity range for colormap','+1', 'e', [mn mx], 2)';
end

% if only one argument is given assume that parameters are the same for all files
if size(options.range,1) > 1
    range = options.range(sel,:);
else
    range = options.range;
end

if range(1)==range(2)
	[mx mn] = volmaxmin(OV.img(2).vol)
	OV.img(2).range = [mn mx];
else OV.img(2).range = range; end

% do not show background zeros
OV.img(2).func = 'i1(i1==0)=NaN;';

if range(1) >= 0
	OV.img(2).outofrange = {0,size(OV.img(2).cmap,1)};
else
	OV.img(2).outofrange = {1,1};
    OV.img(2).cmap    = cmap_bivariate;
end

OV.slices = slices;

n_images = length(slices) + length(OV.cbar);
xy = get_xy(n_images);

n = size(xy,1);
xy_name = num2str(xy);
str = deblank(xy_name(1,:));
for i = 2:n, str = [str '|' deblank(xy_name(i,:))]; end
indxy = spm_input('Select number of columns/rows','+1','m',str);
xy = xy(indxy,:);

% prepare overview of slices
V = OV.img(1).vol;
ref_vol = spm_read_vols(V);
ref_vol = 64*(ref_vol-OV.img(1).range(1))/(OV.img(1).range(2)-OV.img(1).range(1));
vx =  sqrt(sum(V.mat(1:3,1:3).^2));
Orig = round(V.mat\[0 0 0 1]');

h0 = figure(11);
clf
axes('Position',[0 0 1 1]);

hold on
dim = OV.img(1).vol.dim(1:3);
switch lower(OV.transform)
	case 'sagittal'
		ref_img = ref_vol(:,:,Orig(3))';
		slices_vx = slices/vx(1) + Orig(1);
		image(ref_img)
		for i=slices_vx
			h = line([i i],[1 dim(2)]);
			set(h,'Color','r')
		end
	case 'coronal'
		ref_img = squeeze(ref_vol(Orig(1),:,:))';
		slices_vx = slices/vx(2) + Orig(2);
		image(ref_img)
		for i=slices_vx
			h = line([i i],[1 dim(3)]);
			set(h,'Color','r')
		end
	case 'axial',
		ref_img = squeeze(ref_vol(Orig(1),:,:))';
		slices_vx = slices/vx(3) + Orig(3);
		image(ref_img)
		for i=slices_vx
			h = line([1 dim(2)],[i i]);
			set(h,'Color','r')
		end
end 

screensize = get(0,'screensize');
set(h0,'Position',[0, 0.9*screensize(4),size(ref_img,2),size(ref_img,1)],...
	'MenuBar','none',...
	'Resize','off',...
	'PaperType','A4',...
	'PaperUnits','normalized',...
	'NumberTitle','off',...
	'PaperPositionMode','auto');

hold off
axis off xy image
colormap(gray)
 
OV.xslices = xy(:,1);
switch lower(OV.transform)
	case 'sagittal'
		dim = xy.*OV.img(1).vol.dim(2:3);
	case 'coronal'
		dim = xy.*OV.img(1).vol.dim([1 3]);
	case 'axial'
		dim = xy.*OV.img(1).vol.dim(1:2);
end
screensize = get(0,'screensize');

scale = screensize(3:4)./dim;

% scale image only if its larger than screensize
if min(scale) < 1
	fig_size = min(scale)*dim*0.975;
else
	fig_size = dim;
end

h = figure(12);
set(h,...
	'Position',[1 1 fig_size],...
	'MenuBar','none',...
	'Resize','off',...
	'PaperType','A4',...
	'PaperUnits','normalized',...
	'PaperPositionMode','auto',...
	'Visible','off');

OV.figure = h;
OV.figure_struct.Position = get(h,'Position');
OV.figure_struct.Units = 'pixels';

OV.area.valign = 'bottom';
OV.area.halign = 'center';

paint(OV);

% change labels of colorbar for log-scale
if (OV.cbar == 2) & logP
  	H = gca;
	  YTick = get(H,'YTick');
	  mn = floor(min(YTick));
	  mx = ceil(max(YTick));
	  % allow only integer values
	  values = [floor(mn:mx)];
	  pos = get(get(gca,'YLabel'),'position');
	  pos(1) = 2.5;

  	set(H,'YTick',values);
		YTick = get(H,'YTick');

		YTickLabel = [];
		for i=1:length(YTick)
			YTickLabel = strvcat(YTickLabel,remove_zeros(sprintf('%.g',10^(-YTick(i)))));
		end
		set(H,'YTickLabel',YTickLabel)
		set(get(gca,'YLabel'),'string','p-value','position',pos)
  	set(H,'FontSize',0.35*get(H,'FontSize'))
else
  	H = gca;
  	set(H,'FontSize',0.35*get(H,'FontSize'))
end

% save image
saving = spm_input('Save png images?','+1','yes|no',[1 0],2);
if saving
	[pt,nm] = fileparts(img);
	imaname = spm_input('Filename','+1','s',[nm '_' lower(OV.transform) '.png']);
	print_fig(OV,imaname,'print -r300 -dpng -painters -noui')
	fprintf('Image %s saved.\n',imaname);
  if n_slice > 0
      imaname = [lower(OV.transform) '_' replace_strings(options.slices_str(ind,:)) '.png'];
  else
      imaname = [lower(OV.transform) '.png'];
  end
	saveas(h0,imaname,'png');
	fprintf('Image %s saved.\n',imaname);
end

function xy=get_xy(n)

nn = round(n^0.4);
if n>8, x = nn:round(n/nn); else x = 1:n; end
xy=[];
for i=1:length(x)
	y = round(n/x(i));
	% check whether y is to small
	while y*x(i)<n, y = y + 1; end
	if i>2
		if y*x(i-1)<n, xy = [xy; [x(i) y]]; end
	else xy = [xy; [x(i) y]]; end
end

% change order of x and y
for i=1:size(xy,2)
	yx = [xy(i,2) xy(i,1)];
	xy = [xy; yx];
end

% remove duplicates
xy = unique(xy,'rows');
return

% --------------------------------------------------------------------------
function s=remove_zeros(s)

pos = length(s);
while pos>1
	if strcmp(s(pos),'0')
		s(pos)='';
		pos = pos-1;
	else break
	end
end

% --------------------------------------------------------------------------
function s = replace_strings(s)

s = deblank(s);
% replace spaces with "_" and characters like "<" or ">"
s(findstr(s,' ')) = '_';
s(findstr(s,':')) = '_';
s = spm_str_manip(s,'v');

return

% --------------------------------------------------------------------------
function [mx,mn] = volmaxmin(vol)
mx = -Inf; mn = Inf;
for i=1:vol.dim(3),
    tmp = spm_slice_vol(vol,spm_matrix([0 0 i]),vol.dim(1:2),[0 NaN]);
    tmp = tmp(find(isfinite(tmp(:)) & (tmp(:)~=0)));
    if ~isempty(tmp)
        mx = max([mx; tmp]);
        mn = min([mn; tmp]);
    end
end
return


function obj = pr_basic_ui(imgs, dispf)
% GUI to request parameters for slover routine
% FORMAT obj = pr_basic_ui(imgs, dispf)
%
% GUI requests choices while accepting many defaults
%
% imgs  - string or cell array of image names to display
%         (defaults to GUI select if no arguments passed)
% dispf - optional flag: if set, displays overlay (default = 1)
%
% $Id: pr_basic_ui.m,v 1.1 2005/04/20 15:05:00 matthewbrett Exp $
 
if nargin < 1
  imgs = '';
end
if isempty(imgs)
  imgs = spm_select(Inf, 'image', 'Image(s) to display');
end
if ischar(imgs)
  imgs = cellstr(imgs);
end
if nargin < 2
  dispf = 1;
end
  
spm_input('!SetNextPos', 1);

% load images
nimgs = size(imgs);

% process names
nchars = 20;
imgns = spm_str_manip(imgs, ['rck' num2str(nchars)]);

% Get new default object
obj = slover;

% identify image types
cscale = [];
deftype = 1;
obj.cbar = [];
for i = 1:nimgs
  obj.img(i).vol = spm_vol(imgs{i});
  if i==1
    itype{1} = 'Structural';
  else
    itype{1} = 'Blobs';
  end
  imgns(i) = {sprintf('Img %d (%s)',i,itype{1})};
  [mx mn] = volmaxmin(obj.img(i).vol);
  if ~isempty(strmatch('Structural', itype))
    obj.img(i).type = 'truecolour';
    obj.img(i).cmap = gray;
    obj.img(i).range = [2*mn mx]; % increase minimum value to enhance contrast
    deftype = 2;
    cscale = [cscale i];
    if strcmp(itype,'Structural with SPM blobs')
      obj = add_spm(obj);
    end
  else
    cprompt = ['Colormap: ' imgns{i}];
    switch itype{1}
     case 'Truecolour'
      obj.img(i).type = 'truecolour';
      dcmap = 'flow.lut';
      drange = [mn mx];
      cscale = [cscale i];
      obj.cbar = [obj.cbar i];
     case 'Blobs'
      obj.img(i).type = 'split';
      dcmap = 'jet';
      drange = [0 mx];
      obj.img(i).prop = 1;
      obj.cbar = [obj.cbar i];
     case 'Negative blobs'
      obj.img(i).type = 'split';
      dcmap = 'winter';
      drange = [0 mn];
      obj.img(i).prop = 1;
      obj.cbar = [obj.cbar i];
     case 'Contours'
      obj.img(i).type = 'contour';
      dcmap = 'white';
      drange = [mn mx];
      obj.img(i).prop = 1;
    end
    obj.img(i).cmap = sf_return_cmap(cprompt, dcmap);
    obj.img(i).range = spm_input('Img val range for colormap','+1', 'e', drange, 2);
  end
end
ncmaps=length(cscale);
if ncmaps == 1
  obj.img(cscale).prop = 1;
else
  remcol=1;
  for i = 1:ncmaps
    ino = cscale(i);
    obj.img(ino).prop = spm_input(sprintf('%s intensity',imgns{ino}),...
                 '+1', 'e', ...
                 remcol/(ncmaps-i+1),1);
    remcol = remcol - obj.img(ino).prop;
  end
end
 

% use SPM figure window
%obj.figure = spm_figure('GetWin', 'Graphics'); 

obj = fill_defaults(obj);

obj.transform = deblank(spm_input('Image orientation', '+1', ['Axial|' ...
            ' Coronal|Sagittal'], strvcat('axial','coronal','sagittal'), ...
            1));

% slices for display
slices = obj.slices;
obj.slices = spm_input('Slices to display (mm)', '+1', 'e', ...
              sprintf('%0.0f:%0.0f:%0.0f',...
                  slices(1),...
                  mean(diff(slices)),...
                  slices(end)));

% and do the display
if dispf, obj = paint(obj); end

return


% Subfunctions 
% ------------
function cmap = sf_return_cmap(prompt,defmapn)
cmap = [];
while isempty(cmap)
  [cmap w]= slover('getcmap', spm_input(prompt,'+1','s', defmapn));
  if isempty(cmap), disp(w);end
end
return
