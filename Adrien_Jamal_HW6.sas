data ED2010;
infile 'file_location\ED2010' missover lrecl=9999;
input @103 Diag1 $char3. @4 Age 3. @21 Sex 1. @36 Pay 2.;
run;

data OPD2010;
infile 'file_location\OPD2010' missover lrecl=9999;
input @51 Diag1 $char3. @164 Proc1 $char4. @4 Age 3. @7 Sex 1. @20 Pay 2.;
run;

data NAMCS2010;
infile 'file_location\NAMCS2010' missover lrecl=9999;
input @55 Diag1 $char3. @168 Proc1 $char4. @8 Age 3. @11 Sex 1. @24 Pay 2.;
run;

data combined;
set ED2010 OPD2010 NAMCS2010;
if Diag1 = 595 OR Diag1 = 590 OR Diag1 = 599 then diag = 1;
if Diag1 = 460 OR Diag1 = 461 OR Diag1 = 462 OR Diag1 = 463 OR Diag1 = 465
OR Diag1 = 466 OR Diag1 = 473 then diag = 2;
if Diag1 = 675 OR Diag1 = 680 OR Diag1 = 681 OR Diag1 = 682
OR Diag1 = 684 OR Diag1 = 704 OR Diag1 = 705 OR Diag1 = 782 then diag = 3;

if Proc1 = 5732 OR Proc1 = 5733 OR Proc1 = 5739 OR Proc1 = 5794 then proc = 1;
if Proc1 = 8937 OR Proc1 = 8938 OR Proc1 = 8939  then proc = 2;
if Proc1 = 9032 OR Proc1 = 9033 OR Proc1 = 9039 then proc = 3;
if Proc1 = 9162 OR Proc1 = 9169 then proc = 4;

if Age > 18 then agegrp = 0; else agegrp = 1;

if Pay = -9 OR Pay = -8 then Pay = 'missing';

run;
data hw6.formatlabel;
set combined;
format diag $char1. agegrp 1. sex $char1. proc $char1. pay 2.;
label diag = 'Diagnosis' agegrp = 'Age Group' proc = 'Procedure' sex = 'Gender' 
pay = 'Payment';
run;
proc format;
value diag (multilabel)
1 = "Urinary tract infections"
2 = 'Upper respiratory 
infections'
3 = 'Skin and soft tissue 
infections';
value proc (multilabel)
1 = 'Bladder procedures'
2 = 'Manual examination'
3 = 'Microscopic examination 
of ENT'
4 = 'Microscopic examination 
of integument';
value pay (multilabel)
1 = 'Private Insurance'
2 = 'Medicare'
3 = 'Medicaid'
4 = 'Worker’s Compensation'
5 = 'Self-Pay'
6 = 'No Charge'
7 = 'Other'
-8 = 'Unknown'
-9 =  'Blank';
value agegrp (multilabel)
0 = 'Adult'
1 = 'Pediatric';
value sex (multilabel)
1 = 'Male'
2 = 'Female';
run;
proc contents data= hw6.formatlabel;
run;

data infection;
set hw6.formatlabel;
where diag in (1,2,3);
run;

data procedure;
set hw6.formatlabel;
where proc in (1,2,3,4);
run;

ODS PDF file='file_location\Adrien_Jamal_HW6.pdf'
style = Analysis;

*Infections*;

proc freq data=infection;
table diag / norow nopercent;
title "Distribution of Infections";
run;
proc freq data=infection;
table diag*sex / norow nopercent;
title "Distribution of Infections by Gender";
run;
proc freq data=infection;
table diag*agegrp / norow nopercent;
title "Distribution of Infections by Age Groups";
run;
proc freq data=infection;
table diag*Pay / norow nopercent;
title "Distribution of Infections by Payments";
run;

*Procedure*;

proc freq data=procedure;
table proc / norow nopercent;
title "Distribution of Procedures";
run;
proc freq data=procedure;
table proc*sex / norow nopercent;
title "Distribution of Procedures by Gender";
run;
proc freq data=procedure;
table proc*agegrp / norow nopercent;
title "Distribution of Procedures by Age Groups";
run;
proc freq data=procedure;
table proc*Pay / norow nopercent;
title "Distribution of Procedures by Payments";
run;

ODS PDF Close;
