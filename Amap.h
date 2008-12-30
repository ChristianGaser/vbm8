/*
 * Christian Gaser
 * $Id$ 
 *
 */

#ifndef SQR
#define SQR(x) ((x)*(x))
#endif

#define SQRT2PI 2.506628
#define G 6

#ifndef MAX
#define MAX(A,B) ((A) > (B) ? (A) : (B))
#endif

#ifndef MIN
#define MIN(A,B) ((A) < (B) ? (A) : (B))
#endif

#define MAX_NC 5
#define TH_COLOR 1

#define CSFLABEL   0
#define GMLABEL    1
#define WMLABEL    2
#define GMCSFLABEL 3
#define WMGMLABEL  4

#ifndef ROUND
#define ROUND( x ) ((int) ((x) + ( ((x) >= 0) ? 0.5 : (-0.5) ) ))
#endif

struct point {
  double mean;
  double var;
};

struct ipoint {
  int n;
  double s;
  double ss;
};
