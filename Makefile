#!/usr/bin/env make -f

VERSION=`svn info |grep Revision|sed -e 's/Revision: //g'`
DATE=`svn info |grep 'Last Changed Date: '|sed -e 's/Last Changed Date: //g'|cut -f1 -d' '`

TARGET=/Users/gaser/spm/spm8b/toolbox/vbm8

STARGET=141.35.200.101:/Applications/xampp/htdocs/

FILES=Contents.m cg_config_vbm8.m Amap.* AmapMex.* MrfPrior.c Pve5.c cg_vbm8_run.m cg_vbm8_write.m cg_check_sample_sd.m cg_showslice_all.m cg_spmT2x.m cg_vbm8_tools.m cg_vbm8_debug.m cg_morph_vol.m cg_cleanup_gwc.m spm_vbm8.m vbm8.man brainmask_LPBA40.nii maci w32 a64 glx EBTKS

ZIPFILE=vbm8_r$(VERSION).zip

include Makefile.var

OBS = PveAmap.o Amap.o MrfPrior.o Pve5.o Kmeans.o WarpPriors.o Bayes.o optimizer3d.o diffeo3d.o splineSmooth.o

archive: PveAmap.a

PveAmap.a: $(OBS)
	$(DEL) $@
	$(AR) $@ $(OBS)

%.o : %.c %.cc
	$(MEX) -c $< $(MEXEND)
#	$(MOVE) %.$(MOSUF) $@

%.$(SUF) : %.c %.cc
	$(MEX) $< $(MEXEND)

PveAmapMex.$(SUF): PveAmapMex.c PveAmap.a
	$(MEX) PveAmapMex.c PveAmap.a -lEBTKS -L$(EXT) -I./ $(MEXEND)

install: 
	-@echo install
	-@test ! -d ${TARGET} || rm -rf ${TARGET}
	-@mkdir ${TARGET}
	-@cp -R ${FILES} ${TARGET}

help:
	-@echo Available commands:
	-@echo install zip scp update

update:
	-@svn update
	-@echo '% Voxel Based Morphometry Toolbox' > Contents.m
	-@echo '% Version ' ${VERSION} ' (VBM8) ' ${DATE} >> Contents.m
	-@cat Contents_info.txt >> Contents.m

zip: update
	-@echo zip
	-@test ! -d vbm8 || rm -r vbm8
	-@cp -rp ${TARGET} .
	-@zip ${ZIPFILE} -rm vbm8

scp: zip
	-@echo scp
	-@cp ${ZIPFILE} vbm8_latest.zip
	-@scp -pr vbm8_latest.zip ${ZIPFILE} ${STARGET}
