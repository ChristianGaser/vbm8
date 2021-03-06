/*
 * Christian Gaser
 * $Id$ 
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "optimizer3d.h"
#include "diffeo3d.h"
#include "Amap.h"
#include "PveAmap.h"

void PveAmap(double *src, unsigned char *priors, unsigned char *mask, unsigned char *prob, double *mean, double *separations, int *dims, int pve, int method, int warp)
{

  int thresh, thresh_kmeans_int, vol, vol2, vol3, i;
  int n_loops, update_label, sum_priors;
  unsigned char *label;
  double max_src, max_mask;
  float *flow;
  
  /* change some default parameters */
/*  Niters = 10; */
  
  vol   = dims[0]*dims[1]*dims[2];
  vol2  = vol*2;
  vol3  = vol*3;
  label = (unsigned char*)malloc(sizeof(unsigned char)*vol);
  flow  = (float *)malloc(sizeof(float)*vol3);
  
  /* initialize flow field with zeros */
  for (i = 0; i < (vol3); i++) flow[i] = 0.0;
  
  /* check maximum of mask to indicate whether it's defined or not */
  max_mask = -HUGE;
  for (i=0; i<vol; i++) max_mask = MAX(mask[i], max_mask);

  /* if mask is not defined */
  if(max_mask == 0) {
    /* compute mask based on sum of tissue priors for GM/WM/CSF if not given */
    if(priors != (unsigned char *)0) {
      printf("Mask will be estimated based on sum of tissue priors\n.");
      for (i=0; i<vol; i++) {
        sum_priors = (int)priors[i] + (int)priors[i+vol] + (int)priors[i+vol2];
        if(sum_priors >= 255) mask[i] = 255;
        else mask[i] = (unsigned char) sum_priors;
      }
    } else {
    /* or set mask to 255 if src > 0 */
      for (i=0; i<vol; i++) {
        if(src[i] > 0) mask[i] = 255;
        else mask[i] = 0;
      }
    }
  }
    
  if((method == BAYES) && (pve == KMEANS)) {
    pve = MARGINALIZED;
    printf("Warning: Bayes estimation cannot be combined with PVE based on Kmeans. PVE was changed to marginalized likelihood method.\n");
  }

  if((method == BAYES) && (priors == (unsigned char *)0)) {
    method = KMEANS;
    printf("Warning: Bayes estimation does need priors. Method was changed to Kmeans.\n");
  }

  if((warp) && (priors == (unsigned char *)0))
    printf("Warning: Warping is disabled because no priors were defined.\n");

  thresh = (int)ROUND(255*thresh_brainmask);
  thresh_kmeans_int = (int)ROUND(255*thresh_kmeans);

  /* initial nu-correction works best with 5 class Kmeans approach followed by a 3 class approach */
  max_src = Kmeans( src, label, mask, 25, n_pure_classes, separations, dims, thresh, thresh_kmeans_int, iters_nu, KMEANS);
  max_src = Kmeans( src, label, mask, 25, n_pure_classes, separations, dims, thresh, thresh_kmeans_int, iters_nu, NOPVE);
  
  /* calculate initial probability */
  for(i=0; i<vol; i++) {
    switch(label[i]) {
    /* background */
    case 0:
      prob[i] = 0;   prob[i+vol] = 0;   prob[i+vol2] = 0;
      break;
    /* CSF */
    case 1:
      prob[i] = 255; prob[i+vol] = 0;   prob[i+vol2] = 0;
      break;
    /* GM */
    case 2:
      prob[i] = 0;   prob[i+vol] = 255; prob[i+vol2] = 0;
      break;
    /* WM */
    case 3:
      prob[i] = 0;   prob[i+vol] = 0;   prob[i+vol2] = 255;
      break;
    }
  }

  /* initial warp */
  n_loops = 6;
  if(priors != (unsigned char *)0) {
    if(warp) WarpPriors(prob, priors, mask, flow, dims, n_loops, subsample_warp);
  }

  /* use Kmeans or Bayes for estimate */
  if(method == BAYES)
    Bayes(src, label, priors, mask, separations, dims, iters_nu);
  else
    max_src = Kmeans( src, label, mask, 25, n_pure_classes, separations, dims, thresh, thresh_kmeans_int, iters_nu, pve);

  /* update probabilities optionally using PVE */
  if (pve) {
    update_label = 0;
    Pve5(src, prob, label, mean, dims, update_label);
  } else {
    for(i=0; i<vol; i++) {
      switch(label[i]) {
      /* background */
      case 0:
        prob[i] = 0;   prob[i+vol] = 0;   prob[i+vol2] = 0;
        break;
      /* CSF */
      case 1:
        prob[i] = 255; prob[i+vol] = 0;   prob[i+vol2] = 0;
        break;
      /* GM */
      case 2:
        prob[i] = 0;   prob[i+vol] = 255; prob[i+vol2] = 0;
        break;
      /* WM */
      case 3:
        prob[i] = 0;   prob[i+vol] = 0;   prob[i+vol2] = 255;
        break;
      }
    }
  }
    
  /* mask src image with warped mask */
  for(i=0; i<vol; i++)
    if(mask[i] < 1) src[i] = 0.0;
  
  /* Adaptiv MAP approach */
  Amap( src, label, prob, mean, n_pure_classes, Niters, subsample, dims, pve);

  /* PVE */
  if (pve) {
    printf("Calculate Partial Volume Estimate.\n");
    update_label = 1;
    Pve5(src, prob, label, mean, dims, update_label);
  }

  /* final warping */
  n_loops = 6;
  if(priors != (unsigned char *)0) {
    if(warp) WarpPriors(prob, priors, mask, flow, dims, n_loops, subsample_warp);
  }
  
  /* apply warped mask to tissue maps */ 
  for(i=0; i<vol; i++) {
    if(mask[i] < 16) {
      prob[i     ] = 0;
      prob[i+vol ] = 0;
      prob[i+vol2] = 0;
    }
  }
  
  free(label);
  free(flow);
}
