libname HW "file_location";
ods graphics on;
proc import datafile = 'file_location\actg320.csv'
 out = hw.actg320
 dbms = csv REPLACE;
run;

proc univariate data=work.actg320;
var priorzdv_log;
histogram priorzdv_log / normal;
run;

data work.actg320;
set hw.actg320;
priorzdv_log = log(priorzdv);
cd4_sqrt = sqrt(cd4);
run;


proc phreg data=actg320;
class tx sex ivdrug karnof / ref=first;
model time*censor(0) = tx age sex ivdrug karnof cd4_sqrt priorzdv_log tx*priorzdv_log tx*age tx*karnof tx*cd4_sqrt tx*sex  tx*ivdrug / type3 ties=efron;
hazardratio tx / diff=ref;
run;
* only one significant interaction: tx*priorzdv_log;

proc phreg data=actg320;
class tx sex ivdrug karnof / ref=first;
model time*censor(0) = tx age sex ivdrug karnof cd4_sqrt priorzdv_log tx*priorzdv_log / type3 ties=efron;
hazardratio tx / diff=ref;
run;
* ivdrug p-value: 0.11, sex p-value: 0.61;

proc phreg data=actg320 plots=cumhaz;
class tx karnof / ref=first;
model time*censor(0) = tx age karnof cd4_sqrt priorzdv_log tx*priorzdv_log / type3 ties=efron;
hazardratio tx / diff=ref cl=wald;
run;
* final model. The remaining variable are significant to predicting
the outcome variable;



%macro phreg_score_test(time, event, xvars, strata, weight=, data=_last_, type="time");
		
/*creating ranked time variable*/
proc rank data = &data (where =(&event=1) keep = &time &event) 
          out = _tvars_;
  var &time;
  ranks _Rtime;
run;

/*creating survival time variable*/
proc lifetest data = &data noprint;
  time &time*&event(0);
  survival out = _surv_ (keep = &time survival);
run;
/*put the rank time and survival time together*/
proc sort data= _tvars_;
  by &time;
run;
proc sort data= _surv_ (keep=&time survival) nodups;
  by &time;
run;
data _surv_;
  set _surv_ (where=(survival^=.));
  lags = lag(survival);
  if _n_ = 1 then s = 0;
  else s = 1-lags;
run;
/*add log-time to it as well*/
data _tvars_ (keep = &time _Rtime _logtime s);
  merge _tvars_ (in=ranked) _surv_;
  by &time;
  if ranked;
  _logtime = log(&time);
run;
%let xvar_r =;
%let k = 1;					  
%let v = %scan(&xvars, 1);
%do %while ("&v"~="");
  %let xvar_r = &xvar_r  &v._r;
  %let k = %eval(&k + 1);
  %let v = %scan(&xvars, &k);
%end;
%let varnames = &time &xvars &xvar_r;
ods listing close;
%if "&weight"="" %then %do;
  proc phreg data=&data covout outest=_est_ (drop=_LNLIKE_);
    model &time*&event(0) = &xvars;
    strata &strata;
    output out = _res_ (where = (&event=1))  ressch = &xvar_r;
  run;
%end;
%else %do;  
proc phreg data=&data covout outest=_est_ (drop=_LNLIKE_);
  model &time*&event(0) = &xvars;
  strata &strata;
  weight &weight;
  output out = _res_ (where = (&event=1))  ressch = &xvar_r;
run;
%end;

proc sort data = _res_;
  by &time;
run;
/*counting the number of total events*/
proc sql noprint;
  select sum(&event) into :delta
  from &data;
quit;

ods listing; 
proc iml;
  reset noname printadv = 1;
  use _res_;
  read all variables {&xvar_r} into S;
  use _tvars_;
  read all variables {&time _logtime _Rtime s} into T;
  c = ncol(S);
  r = nrow(S);
  use _est_;
  read all var _num_ into V where (_TYPE_^="PARMS");
  read all var {_name_} into N where (_TYPE_^="PARMS");

  sv = J(r, c, 0);
  sv = &delta*S*V;
 
  %if (%upcase(&type)="TIME") %then %do;
     gbar = sum(T[,1])/&delta;
     top = J(c, 1, 0);
     do i = 1 to c;
       top[i] = sum((T[, 1]-gbar)#sv[, i])**2;
     end;
     bottom = J(c, 1, 1);
     do i = 1 to c;
       bottom[i] = &delta*t(T[,1]-gbar)*(T[,1]-gbar)*V[i,i];
     end;
     chi2 = top/bottom;
	 X = J(c+1, 4, 0);
	 print "Score test of proportional hazards assumption";
	 print "Time variable: &time";
									   
	 ct = T[, 1] - sum(T[,1])/&delta;
	 norm_ct = sqrt(t(ct)*ct);
     do i = 1 to c;	
	   csv = sv[, i] - sum(sv[,i])/&delta;
	   n_csv = sqrt(t(csv)*csv);
       X[i, 1] = t(ct)*csv/(norm_ct*n_csv);	/*correlation*/
	   X[i, 2] = chi2[i]; /*cstat*/
	   X[i, 3] = 1;
       X[i, 4] = 1- probchi(chi2[i], 1); /*probchi2*/
	 end; /* individual test*/
	 rname = N//"Global test";
     cname={"Rho" "Chi-Square"  "df"  "P-value"}; 
	
     rowmat = J(1,c,1);
     a = (T[,1]-gbar)#S;
     do i = 1 to c;
       rowmat[i] =sum(a[, i]);
     end;
     global = &delta*(rowmat*V*t(rowmat))/(t(T[,1]-gbar)*(T[,1]-gbar));
     probchi2=1-probchi(global,c);
	 X[c+1, 1] = .;
	 X[c+1, 2] = global;
	 X[c+1, 3] = c;
	 X[c+1, 4] = probchi2;
     print x[rowname=rname colname=cname format=12.3];
  %end;

  %if (%upcase(&type)="LOGTIME") %then %do;
     gbar = sum(T[,2])/&delta;
     top = J(c, 1, 0);
     do i = 1 to c;
       top[i] = sum((T[, 2]-gbar)#sv[, i])**2;
     end;
     bottom = J(c, 1, 1);
     do i = 1 to c;
       bottom[i] = &delta*t(T[,2]-gbar)*(T[,2]-gbar)*V[i,i];
     end;
     chi2 = top/bottom;
	 X = J(c+1, 4, 0);
	 print "Score test of proportional hazards assumption";
	 print "Time variable: LOG(&time)";
									   
	 ct = T[, 2] - sum(T[,2])/&delta;
	 norm_ct = sqrt(t(ct)*ct);
     do i = 1 to c;	
	   csv = sv[, i] - sum(sv[,i])/&delta;
	   n_csv = sqrt(t(csv)*csv);
       X[i, 1] = t(ct)*csv/(norm_ct*n_csv);	/*correlation*/
	   X[i, 2] = chi2[i]; /*cstat*/
	   X[i, 3] = 1;
       X[i, 4] = 1- probchi(chi2[i], 1); /*probchi2*/
	 end; /* individual test*/
	 rname = N//"Global test";
     cname={"Rho" "Chi-Square"  "df"  "P-value"}; 
	
     rowmat = J(1,c,1);
     a = (T[,2]-gbar)#S;
     do i = 1 to c;
       rowmat[i] =sum(a[, i]);
     end;
     global = &delta*(rowmat*V*t(rowmat))/(t(T[,2]-gbar)*(T[,2]-gbar));
     probchi2=1-probchi(global,c);
	 X[c+1, 1] = .;
	 X[c+1, 2] = global;
	 X[c+1, 3] = c;
	 X[c+1, 4] = probchi2;
     print x[rowname=rname colname=cname format=12.3];
  %end;

  %if (%upcase(&type)="RANK") %then %do;
     gbar = sum(T[,3])/&delta;
     top = J(c, 1, 0);
     do i = 1 to c;
       top[i] = sum((T[, 3]-gbar)#sv[, i])**2;
     end;
     bottom = J(c, 1, 1);
     do i = 1 to c;
       bottom[i] = &delta*t(T[,3]-gbar)*(T[,3]-gbar)*V[i,i];
     end;
     chi2 = top/bottom;
	 X = J(c+1, 4, 0);
	 print "Score test of proportional hazards assumption";
	 print "Time variable: RANK(&time)";
									   
	 ct = T[, 3] - sum(T[,3])/&delta;
	 norm_ct = sqrt(t(ct)*ct);
     do i = 1 to c;	
	   csv = sv[, i] - sum(sv[,i])/&delta;
	   n_csv = sqrt(t(csv)*csv);
       X[i, 1] = t(ct)*csv/(norm_ct*n_csv);	/*correlation*/
	   X[i, 2] = chi2[i]; /*cstat*/
	   X[i, 3] = 1;
       X[i, 4] = 1- probchi(chi2[i], 1); /*probchi2*/
	 end; /* individual test*/
	 rname = N//"Global test";
     cname={"Rho" "Chi-Square"  "df"  "P-value"}; 
	
     rowmat = J(1,c,1);
     a = (T[,3]-gbar)#S;
     do i = 1 to c;
       rowmat[i] =sum(a[, i]);
     end;
     global = &delta*(rowmat*V*t(rowmat))/(t(T[,3]-gbar)*(T[,3]-gbar));
     probchi2=1-probchi(global,c);
	 X[c+1, 1] = .;
	 X[c+1, 2] = global;
	 X[c+1, 3] = c;
	 X[c+1, 4] = probchi2;
     print x[rowname=rname colname=cname format=12.3];
  %end;

  %if (%upcase(&type)="KM") %then %do;
     gbar = sum(T[,4])/&delta;
     top = J(c, 1, 0);
     do i = 1 to c;
       top[i] = sum((T[, 4]-gbar)#sv[, i])**2;
     end;
     bottom = J(c, 1, 1);
     do i = 1 to c;
       bottom[i] = &delta*t(T[,4]-gbar)*(T[,4]-gbar)*V[i,i];
     end;
     chi2 = top/bottom;
	 X = J(c+1, 4, 0);
	 print "Score test of proportional hazards assumption";
	 print "Time variable: KM(&time)";
									   
	 ct = T[, 4] - sum(T[,4])/&delta;
	 norm_ct = sqrt(t(ct)*ct);
     do i = 1 to c;	
	   csv = sv[, i] - sum(sv[,i])/&delta;
	   n_csv = sqrt(t(csv)*csv);
       X[i, 1] = t(ct)*csv/(norm_ct*n_csv);	/*correlation*/
	   X[i, 2] = chi2[i]; /*cstat*/
	   X[i, 3] = 1;
       X[i, 4] = 1- probchi(chi2[i], 1); /*probchi2*/
	 end; /* individual test*/
	 rname = N//"Global test";
     cname={"Rho" "Chi-Square"  "df"  "P-value"}; 
	
     rowmat = J(1,c,1);
     a = (T[,4]-gbar)#S;
     do i = 1 to c;
       rowmat[i] =sum(a[, i]);
     end;
     global = &delta*(rowmat*V*t(rowmat))/(t(T[,4]-gbar)*(T[,4]-gbar));
     probchi2=1-probchi(global,c);
	 X[c+1, 1] = .;
	 X[c+1, 2] = global;
	 X[c+1, 3] = c;
	 X[c+1, 4] = probchi2;
     print x[rowname=rname colname=cname format=12.3];
  %end;
quit;
proc datasets;
  delete _tvars_ _res_ _est_ _surv_;
run;
quit;
%mend;



phreg_score_time(time,censor(0), tx, weight=, data=_last_, type="time")
