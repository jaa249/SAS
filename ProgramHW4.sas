libname HW "file_location";
ODS GRAPHICS/ MAXLEGENDAREA=100  WIDTH=200 HEIGHT=200 totalcellmax=3000;

DATA  hw.egfr ;
INFILE  "file_location/egfr-1.csv" 
     DSD 
     LRECL= 41 firstobs=2;
INPUT
 site
 subject
 time
 surgery
 age
 bmi
 income3
 egfr
;
if 
RUN;
data egfrgrowth;
set hw.egfr;
bmi2 = (bmi*bmi);
bmi3 = (bmi*bmi*bmi);
lbmi = sqrt(bmi);
run;


proc mixed data=hw.egfr method=ml covtest cl;
class subject site time surgery income3 / ref=first;
model egfr = site time surgery age income3 bmi / solution cl;
random int /s type=un sub=subject;
run;

*STATA code: xtsum birwt smoke black, i(momid)
we can use ANOVA model to get between and within group vairance
(i.e if the Sum of Squares of error is 0 then there is no within variation,
if the Sum of Squares of model is 0 then there is no between variation);
proc anova data = hw.egfr;
   class site;
   model eGFR = site;
run;
proc anova data = hw.egfr;
   class subject;
   model egfr = subject;
run;

proc mixed data=hw.egfr method=reml covtest cl;
class subject site time surgery income3 / ref=first;
model egfr = site time surgery age income3 bmi / solution cl outp=predicted residual;
random int /s type=un sub=subject;

run;
proc mixed data=egfrgrowth method=reml covtest cl;
class subject site time surgery / ref=first;
model egfr = site time surgery / solution cl ;
random int /s type=un sub=subject;
run;
