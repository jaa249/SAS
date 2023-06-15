libname HW "file_location";
ods graphics on;

proc import datafile = 'file_location\Recid.csv'
 out = work.Recid
 dbms = csv REPLACE;
run;

proc phreg data=work.recid;
class fin race wexp mar / ref=first;
model week*arrest(0) = fin age prio race wexp mar educ / type3 risklimits ties=efron;
hazardratio fin / cl=wald;
run;

proc phreg data=work.recid;
class fin / ref=first;
model week*arrest(0) = fin age prio / type3 risklimits ties=efron;
hazardratio fin / cl=wald;
run;

proc phreg data=work.recid;
class fin / ref=first;
model week*arrest(0) = fin age prio aget / type3 risklimits ties=efron;
aget = age*log(week);
hazardratio fin / cl=wald;
proportionality_test: test aget;
run;


* Model fixing;
proc phreg data=work.recid;
class fin race wexp mar / ref=first;
model week*arrest(0) = fin age prio race wexp mar educ / type3 risklimits ties=efron;
run;

proc phreg data=work.recid;
class fin race mar / ref=first;
model week*arrest(0) = fin age prio race mar educ / type3 risklimits ties=efron;
run;

proc phreg data=work.recid;
class fin mar / ref=first;
model week*arrest(0) = fin age prio mar educ / type3 risklimits ties=efron;
run;

proc phreg data=work.recid;
class fin / ref=first;
model week*arrest(0) = fin age prio / type3 risklimits ties=efron;
run;

proc phreg data=work.recid;
class fin / ref=first;
model week*arrest(0) = fin prio age2 age3/ type3 risklimits ties=efron;
age2 = age**2;
age3 = age**3;
run;

proc phreg data=work.recid;
class fin / ref=first;
model week*arrest(0) = fin age prio agef/ type3 risklimits ties=efron;
agef= age*fin;
agep= age*prio;
finp= fin*prio;
run;

proc phreg data=work.recid;
class fin / ref=first;
model week*arrest(0) = fin prio age2 age3 / type3 risklimits ties=efron;
age2 = age**2;
age3 = age**3;
hazardratio fin / diff=ref;
run;
