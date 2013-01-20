//
//  sun_position.c
//  Globe
//
//  Created by John Brewer on 6/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "sun_position.h"
#include <CoreFoundation/CoreFoundation.h>

// Vernal equinox 3/20/2011 1:16pm PDT
CFGregorianDate vernal_equinox = { 2011, 3, 20, 20, 16, 0.0 };
// Summer solstice 6/21/2011 1:10pm PDT
CFGregorianDate summer_solstice = { 2011, 6, 21, 20, 10, 0.0 };
// Autumnal equinox 9/23/2011 1:01pm PDT
CFGregorianDate autumnal_equinox = { 2011, 9, 23, 20, 01, 0.0 };
// Winter solstice 12/22/2011 12:06pm PST
CFGregorianDate winter_solstice = { 2011, 12, 22, 20, 06, 0.0 };
// 3rd edition test data 7/27/1980 midnight UTC
CFGregorianDate test_3rd_edition = { 1980, 7, 27, 0, 0, 0.0 };
// 4th edition test data 7/27/2003 midnight UTC
CFGregorianDate test_4th_edition = { 2003, 7, 27, 0, 0, 0.0 };

#define SECONDS_PER_DAY (60.0 * 60.0 * 24.0);
#define SECONDS_PER_YEAR (60.0 * 60.0 * 24.0 * 365.242191)
#define DAYS_PER_YEAR 365.242191

#define TO_RADIANS (M_PI / 180.0)
#define TO_DEGREES (180.0 / M_PI)

#define EPOCH_YEAR 1990

#if (EPOCH_YEAR == 1990)
#define JDepoch 2447891.5
#define eg 279.403303
#define wg 282.768422
#define e 0.016713
CFGregorianDate epoch_date = { 1989, 12, 31, 0, 0, 0.0 };
#elif (EPOCH_YEAR == 2010)
#error Not yet defined!
#else
#error EPOCH_YEAR not valid!
#endif

static double normalize360(double angle) {
  angle = fmod(angle, 360.0);
  if (angle < 0) {
    angle += 360.0;
  }
  return angle;
}

static double julean_date(int year, int month, double day) {
  if ((month == 1) || (month == 2)) {
    year -= 1;
    month += 12;
  }
  int A = year / 100;
  int B = 2 - A + (A / 4);
  int C = 365.25 * year;
  int D = 30.6001 * (month + 1);
  double jd = B + C + D + day + 1720994.5;
  return jd;
}

static double sidereal_time(CFAbsoluteTime time) {
  CFGregorianDate gdate = CFAbsoluteTimeGetGregorianDate(time, NULL);
//  CFGregorianDate gdate = { 1980, 4, 22, 14, 36, 51.67 };

  double JD = julean_date(gdate.year, gdate.month, gdate.day);
  double S = JD - 2451545.0;
  double T = S / 36525.0;
  double T0 = 6.697374558 + (2400.051336 * T) + (0.000025862 * T * T);
  while (T0 < 0) {
    T0 += 24;
  }
  while (T0 > 24) {
    T0 -= 24;
  }
  double UT = gdate.hour + gdate.minute / 60.0 + gdate.second / 3600.0;
  double GST = UT * 1.002737909;
  GST += T0;
  if (GST < 0) {
    GST += 24;
  } else if (GST > 24) {
    GST -= 24;
  }
  return GST * 15;
}

void sun_position(float positionVector[3]) {
  CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
//  CFAbsoluteTime now = CFGregorianDateGetAbsoluteTime(winter_solstice, NULL);
  
  CFAbsoluteTime epoch = CFGregorianDateGetAbsoluteTime(epoch_date, NULL);
  
  CFTimeInterval seconds = now - epoch;
  double D = seconds / SECONDS_PER_DAY;
  double N = 360.0 * D / DAYS_PER_YEAR;
  N = normalize360(N);

  double Msun = N + eg - wg;
  Msun = normalize360(Msun);

  double Ec = (360.0 / M_PI) * e * sin(Msun * TO_RADIANS);
  
  
  double lambda = N + Ec + eg;
  lambda = normalize360(lambda);

  double obliquity = 23.441884;
  
  double alpha = atan2(sin(lambda * TO_RADIANS)
                       * cos(obliquity * TO_RADIANS),
                       cos(lambda * TO_RADIANS)) * TO_DEGREES;
  double beta = asin(sin(obliquity * TO_RADIANS)
                     * sin(lambda * TO_RADIANS)) * TO_DEGREES;
  
  double theta = sidereal_time(now);
  double tau = theta - alpha;
  tau += 90.0;
  tau = normalize360(tau);

  positionVector[0] = cos(tau * TO_RADIANS);
  positionVector[2] = sin(tau * TO_RADIANS);
  positionVector[1] = sin(beta * TO_RADIANS);
//  now += 3600;
  return;
}