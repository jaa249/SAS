libname Weekly 'file_location';
libname Reports "file_location";
libname Zipcodes "file_location";

PROC IMPORT DATAFILE= "file_location" 
	OUT= WORK.cliniclab
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet1"; 
	GETNAMES=YES;
	Datarow=2;
RUN;

PROC IMPORT DATAFILE= "file_location" 
	OUT= WORK.colab
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet1"; 
	GETNAMES=YES;
	Datarow=2;
RUN;

PROC IMPORT DATAFILE= "file_location"
	OUT= WORK.cliniccdd1
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet1"; 
	GETNAMES=YES;
	Datarow=2;
RUN;

PROC IMPORT DATAFILE= "file_location" 
	OUT= WORK.clinic
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet1"; 
	GETNAMES=YES;
	Datarow=2;
RUN;

PROC IMPORT DATAFILE= "file_location" 
	OUT= WORK.qpat
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet0"; 
	GETNAMES=YES;
	Datarow=3;
RUN;

PROC IMPORT DATAFILE= "file_location" 
	OUT= WORK.qnur
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet0"; 
	GETNAMES=YES;
	Datarow=3;
RUN;

%include "file_location\WeeklyclinicCO.sas";
%include "file_location\WeeklyCDD.sas";
%include "file_location\WeeklyQUAL.sas";

%let start_date = '01MAY2023'd;
%let end_date = '31MAY2023'd;

data weekly.survey;
    length PATIENT_ID1 $20.;  
    set weekly.survey;
run;

data reports.cdd;
    length PATIENT_ID1 $20.;  
    set reports.cdd;
run;

data weekly.cliniccolab;
    length PATIENT_ID1 $20.;  
    set weekly.cliniccolab;
run;

proc sort data = weekly.survey;
	by descending PATIENT_ID1 descending VISDATE;
run;
proc sort data = reports.cdd nodupkey;
	by descending PATIENT_ID1 descending VISDATE;
run;
proc sort data = weekly.cliniccolab;
	by descending PATIENT_ID1 descending VISDATE;
run;

proc format; 
value $gender_fmt (multilabel)
1 = 'Male'
2 = 'Female'
3 = 'FTM Transgender'
4 = 'MTF Transgender'
5 = 'Other Identity'
8 = 'RTA'
9 = 'Unknown'
;

value $msm_fmt (multilabel)
0 = 'No'
1 = 'Yes'
;

value $YNU_fmt (multilabel)
0 = 'No'
1 = 'Yes'
9 = 'Unknown'
;

value $SPEC_fmt (multilabel)
'E' = 'Endocervical'
'U' = 'Urethral'
'UR' = 'Urine'
'P' = 'Pharyngeal'
'R' = 'Rectal'
'T' = 'Pharyngeal'
;

value $result_fmt (multilabel)
0 = 'Negative'
1 = 'Positive'
3 = 'Indeterminate'
;

value $naat_fmt (multilabel)
0 = 'Both Collected'
1 = 'Missing NAAT'
. = 'N/A'
;

value $cult_fmt (multilabel)
0 = 'Both Collected'
1 = 'Missing Culture'
. = 'N/A'
;


run;

data report;
set weekly.survey(in=a); *weekly.cliniccolab(in=c);
format gender $gender_fmt. msm $msm_fmt. SXPHARYNGEAL SXDYSURIA SXDISCHARGE SXRECTAL SXABDOMEN ExpSTD_PTR ExpSTD_HD $YNU_fmt.;

run;

proc freq data = weekly.survey;
table gender;
run;

data weekly.report;
set report; *reports.cdd(in=b);
format Phar_Cult_Flag Rect_Cult_Flag Uret_Cult_Flag Cerv_Cult_Flag $30. expstd $8.;

label Phar_Not_Obtai = 'Pharyngeal Cult. not Obtained'
	  Rect_Not_Obtai = 'Rectal Cult. not Obtained'
	  Uret_Not_Obtai = 'Urethral Cult. not Obtained'
	  Cerv_Not_Obtai = 'Cervical Cult. not Obtained'
	  Phar_Cult_Flag = 'Pharyngeal Cult. Flag'
	  Rect_Cult_Flag = 'Rectal Cult. Flag'
	  Uret_Cult_Flag = 'Urethral Cult. Flag'
	  Cerv_Cult_Flag = 'Cervical Cult. Flag'
	  expstd_hd = 'Notified Exposure by Health Department '
	  expstd_ptr = 'Notified Exposure by Partner'
	  sxpharyngeal = 'Symptom: Pharyngeal'
	  sxdysuria = 'Symptoms: Dysuria'
	  sxdischarge = 'Symptoms: Discharge'
	  sxrectal = 'Symptoms: Rectal'
	  sxabdomen = 'Symptoms: Abdomen'
	  MSM = 'Men Who Have Sex with Men'
	;

if Phar_Cult_Fla = '2' then Phar_Cult_Flag = 'Flagged but Not Collected';
	else if Phar_Cult_Fla = '1' then Phar_Cult_Flag = 'Flagged and Collected';
		else Phar_Cult_Flag = 'Not Flagged';

if Rect_Cult_Fla = '2' then Rect_Cult_Flag = 'Flagged but Not Collected';
	else if Rect_Cult_Fla = '1' then Rect_Cult_Flag = 'Flagged and Collected';
			else Rect_Cult_Flag = 'Not Flagged';

if Uret_Cult_Fla = '2' then Uret_Cult_Flag = 'Flagged but Not Collected';
	else if Uret_Cult_Fla = '1' then Uret_Cult_Flag = 'Flagged and Collected';
		else Uret_Cult_Flag = 'Not Flagged';

if Cerv_Cult_Fla = '2' then Cerv_Cult_Flag = 'Flagged but Not Collected';
	else if Cerv_Cult_Fla = '1' then Cerv_Cult_Flag = 'Flagged and Collected';
		else Cerv_Cult_Flag = 'Not Flagged';

if expstd_ptr = '.' or expstd_ptr = '9' then expstd = 'Unknown';
	else if expstd_ptr = '1' then expstd = 'No';
	else if expstd_ptr = '2' then expstd = 'Yes';
	else if expstd_ptr = '8' then expstd = 'RTA';

if Gender = '.' and Uret_Cult_Flag ne 'Flagged but Not Collected' then Gender = '1';
	else if Gender = '.' and Cerv_Cult_Flag ne 'Flagged but Not Collected' then Gender = '2';

	if Gender = '.' then gender = '9';

where &start_date. LE VISDATE LE &end_date.;

run;

data No_Culta;
set weekly.report;

MRN = PATIENT_ID1;

where Phar_Not_Obtai ne '' or Rect_Not_Obtai ne '' or Uret_Not_Obtai ne '' or Cerv_Not_Obtai ne '';

run;

data No_Cult;
set No_culta;

if Phar_Not_Obtai = '' and Phar_Cult_Fla = '1' then Phar_Not_Obtai = '[Flagged and Collected]';
if Rect_Not_Obtai = '' and Rect_Cult_Fla = '1' then Rect_Not_Obtai = '[Flagged and Collected]';
if Uret_Not_Obtai = '' and Uret_Cult_Fla = '1' then Uret_Not_Obtai = '[Flagged and Collected]';
if Cerv_Not_Obtai = '' and Cerv_Cult_Fla = '1' then Cerv_Not_Obtai = '[Flagged and Collected]';

keep MRN VISDATE Gender Phar_Not_Obtai Rect_Not_Obtai Uret_Not_Obtai Cerv_Not_Obtai;

run;

proc sort data = no_cult;
by MRN VISDATE;
run;

data cliniclab1;
set cliniclab;
format spec_source $SPEC_fmt. Result $15.;


if result1 = 1 then Result = 'Positive';
	else if result1 = 0 then Result = 'Negative';
	else if result1 = 3 then Result = 'Indeterminate';

run;

data cliniclab2;
set weekly.cliniccolab;

spec_source = put(spec_source, $1. -L);

run;

data colab1;
set colab;
format spec_source $SPEC_fmt. Result $15.;

if result1 = 1 then Result = 'Positive';
	else if result1 = 0 then Result = 'Negative';
	else if result1 = 3 then Result = 'Indeterminate';

run;

proc sort data= weekly.cliniccolab; 
by PATIENT_ID1 SPEC_SOURCE VISDATE; 
run; 

data cddnaat;
set weekly.cdd;
format spec_source $SPEC_fmt. Result $15.;

if result1 = 1 then Result = 'Positive';
	else if result1 = 0 then Result = 'Negative';
	else if result1 = 3 then Result = 'Indeterminate';

run;

data opps;
    set reports.cliniccolab cddnaat;

keep MRN PATIENTID SENT_SITE GISP_SPEC_ID EVENTID JURISDICTION_PHL FACILITY_LOCATION 
SPEC_COLLECT_DATE SPEC_SOURCE AGE_LAB DATETESTLAB DATEDONE1 ETDATEDONE DATESENTEC
DATESENTGT DATESENTCLIN DATEALTCDCLAB DATESENTARLN DATESENTCDC ETESTYPE TESTTYPE1
RESULT1 LAB_GENDER CFX_MIC_DD CRO_MIC_DD AZI_MIC_DD EVENTID OTH_TEST OTH_RSLT 
SURRG_SPEC_ID ACCESSION_NO VISDATE;
run;

proc sort data= opps out = opps2; 
by SPEC_SOURCE PATIENTID;
where FACILITY_LOCATION = 'PIT-01' AND &start_date. LE VISDATE LE &end_date.;

run; 

data flagged_opps (drop=onaat_flag ocult_flag);
    set opps2;
    by spec_source PATIENTID;
    retain onaat_flag ocult_flag;

    if TESTTYPE1 = 2 and RESULT1 = 1 then onaat_flag = 1;
    if TESTTYPE1 = 1 then ocult_flag = 1;

    if last.PATIENTID then do;
        if onaat_flag = 1 and ocult_flag = . then pos_naat_no_cult = 1; else pos_naat_no_cult = 0;
        if ocult_flag = 1 and onaat_flag = . then cult_no_naat = 1; else cult_no_naat = 0;

        onaat_flag = .;
        ocult_flag = .;
    end;
run;

data pid mrn;
set weekly.cdd;

if MRN4 ne '' then output mrn;
	else if pid ne '' then output pid;


run;

data test1;
set opps mrn;
if missing(MRN) then delete;
run;

data test2;
set opps pid;
if missing(pid) then delete;
run;

proc sort data=test1;
by mrn;
run;

data flagged;
set flagged_opps;
format cult_no_naat1 pos_naat_no_cult1 $30. spec_source $SPEC_fmt.;
label pos_naat_no_cult1 = 'Positive NAAT but No Culture'
	  cult_no_naat1 = 'Culture Collected but No NAAT'
;

if pos_naat_no_cult = 0 then pos_naat_no_cult1 = 'Both Collected';
	else if pos_naat_no_cult = 1 then pos_naat_no_cult1 = 'Missing Culture';
	else pos_naat_no_cult1 = 'N/A';

if cult_no_naat = 0 then cult_no_naat1 = 'Both Collected';
	else if cult_no_naat = 1 then cult_no_naat1 = 'Missing NAAT';
	else cult_no_naat1 = 'N/A';


if cult_no_naat1 = 'Missing NAAT' then a = 2;
else if pos_naat_no_cult1 = 'Missing Culture' then a = 1;
else a = 0;


drop cult_no_naat pos_naat_no_cult;

run;

ods rtf file="file_location\WeeklyReport.rtf"
	style = Analysis;

title 'SITREP Data May 1, 2023 - May 31, 2023';

title2 'STD CLINIC';

title3 'Projected Cultures vs Actual Cultures';

proc freq data = weekly.report;
table Phar_Cult_Flag*gender / nocum nocol norow;
where Phar_Cult_Flag ne 'Not Flagged';
title4 'Pharyngeal Cultures by Gender';
run;

proc freq data = weekly.report;
table Rect_Cult_Flag*gender / nocum nocol norow;
where Rect_Cult_Flag ne 'Not Flagged';
title4 'Rectal Cultures by Gender';
run;

proc freq data = weekly.report;
table Uret_Cult_Flag*gender / nocum nocol norow;
where gender ne '2' and Uret_Cult_Flag ne 'Not Flagged';
title4 'Urethral Cultures by Gender';
run;

proc freq data = weekly.report;
table Cerv_Cult_Flag*gender / nocum nocol norow;
where gender ne '1' and Cerv_Cult_Flag ne 'Not Flagged';
title4 'Cervical Cultures by Gender';

run;

title3 'Reason for Flagged with No Culture Completed by MRN';

proc print data=no_cult;
var MRN VISDATE Gender Phar_Not_Obtai Rect_Not_Obtai Uret_Not_Obtai Cerv_Not_Obtai;
run;

title3 'Risk Factors by Gender';

proc freq data = weekly.report;

table MSM / nocum nocol norow;
table expstd_HD*gender / nocum nocol norow;
table ExpSTD_PTR*GENDER / nocum nocol norow;
table SXPHARYNGEAL*gender / nocum nocol norow;
table SXDYSURIA*gender / nocum nocol norow;
table SXDISCHARGE*gender / nocum nocol norow;
table SXRECTAL*gender / nocum nocol norow;
table SXABDOMEN*gender / nocum nocol norow;

run;

title3 'NAAT and Culture Results';

title4 'NAAT Results by Specimen Source';
proc freq data = cliniclab1;
table spec_source*result / nocum nocol norow nopercent;
where TESTTYPE1 = 2 AND &start_date <=SPEC_COLLECT_DATE<= &end_date;
run;

title4 'Culture Results by Specimen Source';
proc freq data = cliniclab1;
table spec_source*result / nocum nocol norow nopercent;
where TESTTYPE1 = 1 AND &start_date <=SPEC_COLLECT_DATE<= &end_date;
run;

title4 'Missing NAATs and Cultures';

title5 'Missing NAAT by Specimen Source';
proc freq data = flagged;
table cult_no_naat1*spec_source / nocum nocol norow nopercent;
where cult_no_naat1 = 'Missing NAAT' ;
run;

title5 'Missing Culture by Specimen Source';
proc freq data = flagged;
table pos_naat_no_cult1*spec_source / nocum nocol norow nopercent;
where pos_naat_no_cult1 = 'Missing Culture';
run;

title2 'Non-STD CLINIC';

title3 'NAAT and Culture Results';

title4 'NAAT Results by Specimen Source';

title5 ;

proc freq data = cddnaat;
table spec_source*result / nocum nocol norow nopercent;
where &start_date <=SPEC_COLLECT_DATE<= &end_date AND FACILITY_LOCATION = 'PIT-02';
run;

title4 'Culture Results by Specimen Source';

proc freq data = colab1;
table spec_source*result / nocum nocol norow nopercent;
where &start_date<=SPEC_COLLECT_DATE<=&end_date;
run;


ods rtf close;

title;
title2;
title3;
title4;

/*
data search;
set flagged_opps;
where '';
run;
*/
