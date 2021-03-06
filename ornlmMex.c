/*
 * Christian Gaser
 * $Id$ 
 *
 */

#include "math.h"
#include "mex.h"
#include <stdlib.h>
#include "matrix.h"

extern void ornlm(double* ima, double* fima, int v, int f, double h, const int* dims);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

/* Declarations */
double *ima, *fima;
double h;
int v,f,ndim;
const int *dims;

/* check inputs */
if (nrhs!=4)
  mexErrMsgTxt("4 inputs required.");
else if (nlhs>2)
  mexErrMsgTxt("Too many output arguments.");
  
if (!mxIsSingle(prhs[0]))
	mexErrMsgTxt("First argument must be double.");


/* get input image */
ima = (double*)mxGetPr(prhs[0]);

ndim = mxGetNumberOfDimensions(prhs[0]);
if (ndim!=3)
  mxErrMsgTxt("Images does not have 3 dimensions.");
  
dims = mxGetDimensions(prhs[0]);

/* get parameters */
v = (int)(mxGetScalar(prhs[1]));
f = (int)(mxGetScalar(prhs[2]));
h = (double)(mxGetScalar(prhs[3]));

/*Allocate memory and assign output pointer*/
plhs[0] = mxCreateNumericArray(ndim,dims,mxSINGLE_CLASS, mxREAL);

/*Get a pointer to the data space in our newly allocated memory*/
fima = mxGetPr(plhs[0]);

ornlm(ima, fima, v, f, h, dims); 

return;

}

