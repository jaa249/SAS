libname HW "file_location";
ods graphics on;
DATA  gtsg;
INFILE  "file_location\GTSG_LONG.txt" firstobs=2;
INPUT obs t trt c;
drop obs;
run;

proc phreg data=gtsg;
class trt / ref=first;
model t*c(0) = trt/ ties=efron;
hazardratio trt / diff=ref;
run;

proc phreg data=gtsg;
model t*c(0) = trt t_trt / risklimits ties=efron;
t_trt = trt*log(t);
proportionality_test: test t_trt;
run;


data gtsgfix;
set gtsg;
if trt = 1 AND t le 254 then Z1 = 1;
	else Z1 = 0;
if trt = 1 AND t > 254 then Z2 = 1;
	else Z2 = 0;

run;

proc phreg data=gtsgfix;
class Z1 Z2 / ref=first;
model t*c(0) = Z1 Z2 / risklimits ties=efron;
run;

data whas500;
set hw.whas500;
bmifp1=(bmi/10)**2;
bmifp2=(bmi/10)**3;
run;

* WHAS500 Final Model;
proc phreg data=whas500;
class sex chf / ref=first;
model lenfol*fstat(0) = bmifp1 bmifp2 age hr diasbp bmi sex chf sex*age/ ties=efron;
run;

* WHAS500 Final model with stratum year;
proc phreg data=whas500;
class sex chf / ref=first;
model lenfol*fstat(0) = bmifp1 bmifp2 age hr diasbp bmi sex chf sex*age / ties=efron;
strata year;
run;

data covars;
input year bmi age hr diasbp chf sex bmifp1 bmifp2;
cards;
1 28 50 80 100 1 0 7.84 21.952
;
run;

* WHAS500 Final model with stratum year;
proc phreg data=whas500 plots(overlay)=(survival);
class sex chf / ref=first;
model lenfol*fstat(0) = bmifp1 bmifp2 age hr diasbp bmi sex chf age*sex / ties=efron;
strata year;
*estimate 'Year 2' bmi 28 age 50 hr 80 diasbp 100 chf 1 sex 0 / exp cl;
baseline covariates=work.covars;
run;

data actg320;
set hw.actg320;
run;

proc sort data=actg320;
by descending tx;
run;

proc lifereg data=actg320 order=data;
class tx;
model time*censor(0) = tx cd4 / distribution=exponential;
estimate 'Time Ratio @ CD4 50' CD4 50 tx 0/exp cl;
run;

data calcq;
z = (exp((.6668 * 0) + (0.0161*50)));
y = 1/z;
t = exp(-3.932 + (0.05 * 60));
q = 1/t;
b1 = (28/10)**2;
b2 = (28/10)**3;
run;
