libname Reports "file_location";
libname Zipcodes "file_location";

PROC IMPORT DATAFILE= "file_location" 
	OUT= WORK.pat
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet0"; 
	GETNAMES=YES;
	Datarow=3;
RUN;
PROC IMPORT DATAFILE= "file_location"
	OUT= WORK.patadd
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet0"; 
	GETNAMES=YES;
	Datarow=3;
RUN;

PROC IMPORT DATAFILE= "file_location" 
	OUT= WORK.patnovjan
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet0"; 
	GETNAMES=YES;
	Datarow=3;
RUN;

data pat1;
	format DatB $10. DOBa VISD VISDT yymmdds10.;
	set pat patadd;
	if EMR ne '' then EMR2 = EMR;
	
	MRN = CL_patID ;

	*if missing(CL_patID) then delete;

	if GISP_DOB = 'Array' then DatB = '';
		else DatB = GISP_DOB;
	DOBa = input(DatB,anydtdte32.);

	VISD = datepart(RecordedDate);
	VISDT = VISD;


	drop rs_u rs_r rs_p rs_c return_rs CL_patID DOB DatB VISD;
run;

proc sort data = pat1;
	by MRN VISDT DOBa;
run;

PROC IMPORT DATAFILE= "file_location"
	OUT= WORK.clin
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet0"; 
	GETNAMES=YES;
	Datarow=3;
RUN;

PROC IMPORT DATAFILE= "file_location"
	OUT= WORK.clinadd
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet0"; 
	GETNAMES=YES;
	Datarow=3;
RUN;

PROC IMPORT DATAFILE= "file_location"
	OUT= WORK.clinnovjan
	DBMS=XLSX
	REPLACE;
	SHEET="Sheet0"; 
	GETNAMES=YES;
	Datarow=3;
RUN;

data clin1;
format VISD $32. VISDT DOBa yymmdds10.;

	set clin clinadd;

if EMR ne '' then MRN = EMR;
	else if missing(EMR) AND ACHD_EMR ne '' then MRN = ACHD_EMR;

	DOBa = input(DOB,anydtdte32.);
	VISD = datepart(RecordedDate);
	VISDT = VISD;


	drop rs_u rs_r rs_p rs_c return_rs VISD DOB;
run;

proc sort data= clin1;
	by MRN VISDT DOBa;
run;

data merge1;
	merge clin1(in=nrs) pat1(in=pt);
	by MRN VISDT DOBa;
	if nrs=1 then output;
run;

data junoct;
	length MENSEX FEMSEX PT_AGE 3.;
	set merge1;
	by MRN;
	format DATETX yymmdds10. DOB1 mmddyy10.
		GISP_GCHXN1 MENSEX FEMSEX PT_AGE 3. 
		GENDER SEXBIRTH HISP_ETH AIAN
		CL_STATE ANTIBIOT_NAME1 WHENHIVM TRMT11 TRMT21 $2. 
		ASIAN NHOPI BLACK WHITE MULTIRACE OTHRACE PREGNANT
		GISP_GCHX1 SURV_GCHX GISP_SEXWRK1 GISP_IDU1 GISP_NONIDU1 
		GISP_ETRVL1 GISP_ETRVL21 PENALLERGY1 MEN_TIME FEM_TIME GENDER_SP1 ExpSTD_PTR1
		ExpSTD_HD1 SXPHARYNGEAL1 SXDYSURIA1 SXDISCHARGE1 SXRECTAL1 SXABDOMEN1 EVERHIV1 
		TCT_SEX1 TCT_CONDUSE1 TCT_SAMEPTR1 TCT_SAMPETRCU1 TOC_VIS HIVRESULTLAST GISP_HIVRESULT 
		PREP1 PREP_REFER1 HIVCARE1 HIVCARE_REFER TOC_VIS1 $1.
		GISP_ANTIBIOT1 $3.
		WHENHIVY $4.
		MEDICATION1_OTH $50.
		;

	/* AGE and Date Fix */
	retain DOB1 zipcode cl_state MRN;

	if missing(DOBa) AND DOB1 ne '' then DOBa = DOB1;
	    if first.MRN then DOB1 = DOBa;

    PT_AGE = INT(yrdif(DOBa, VISDT, 'actual'));


    if missing(DOBa) AND DOB1 ne '' then DOBa = DOB1;

    if PT_AGE < 12 OR PT_AGE > 99 then PT_AGE = 999;

	* rename VisDate1=VisDate;

	/* State fix 42 is default */
	CL_STATE = '42';
	ZIPCODE = GISP_ZIP;

	/* EMR Salvage */

	/* DEMO Fix */
	if GISP_DEMO_GENDER = 1 then GENDER = '1';
			else if GISP_DEMO_GENDER = 2 then GENDER = '2';
			else if GISP_DEMO_GENDER = 3 then GENDER = '3';
			else if GISP_DEMO_GENDER = 4 then GENDER = '4';
			else if GISP_DEMO_GENDER = 5 then GENDER = '5';
			else if GISP_DEMO_GENDER = 6 then GENDER = '6';
			else if GISP_DEMO_GENDER = 8 then GENDER = '8';
				else GENDER = '9';


	if sex = 'Male' OR GISP_DEMO_SEX_BIRTH = 1 then SEXBIRTH = '1';
			else if sex = 'Female' OR GISP_DEMO_SEX_BIRTH = 2 then SEXBIRTH = '2';
			else if missing(sex) AND missing(GISP_DEMO_SEX_BIRTH) then SEXBIRTH = '8';
				else SEXBIRTH = '9';

	if GISP_DEMO_HISP_ETH = 0 then HISP_ETH = '0';
		else if GISP_DEMO_HISP_ETH = 1 then HISP_ETH = '1';
		else if GISP_DEMO_HISP_ETH = 8 then HISP_ETH = '8';
			else HISP_ETH = '9';

	array races[7] AIAN ASIAN NHOPI BLACK WHITE MULTIRACE OTHRACE;
	    do i = 1 to 7;
	        if GISP_RACE = i then races[i] = '1';
	        else if GISP_RACE = '8' then races[i] = '8';
			else if GISP_RACE = '9' then races[i] = '9';
	        else races[i] = '0';
	    end;


	 /* Pregnant Fix */
	 if SEXBIRTH = '2' AND (preg = 'NO' OR GISP_DEMO_PREG_STAT = '0') then PREGNANT = '0';
	 	else if SEXBIRTH = '2' AND (preg = 'YES' OR GISP_DEMO_PREG_STAT = '1') then PREGNANT = '1';
		else if SEXBIRTH = '1' then PREGNANT = '7';
		else if GISP_DEMO_PREG_STAT = '8' then PREGNANT = '8';
			else PREGNANT = '9';

	/* GISP Fix */
	if missing(GISP_GCHX) then GISP_GCHX1 = '9';
		else if GISP_GCHX = '0' OR GISP_GCHX = 'No' then GISP_GCHX1 = '0';
		else if GISP_GCHX = '1' OR GISP_GCHX = 'Yes' then GISP_GCHX1 = '1';
			else GISP_GCHX1 = '8';

	if missing(GISP_GCHXN) then GISP_GCHXN1 = '99';
		else GISP_GCHXN1 = put(GISP_GCHXN,3.);

	if GISP_GCHX1 = '8' then SURV_GCHX = '9';
		else SURV_GCHX = GISP_GCHX1;

	if GISP_ANTIBIOT ne '' then GISP_ANTIBIOT1 = GISP_ANTIBIOT;
		else GISP_ANTIBIOT1 = '9';


	if ANTIBIOT_NAME = '0' then ANTIBIOT_NAME1 ='00';
		else if ANTIBIOT_NAME = '1' then ANTIBIOT_NAME1 ='01';
		else if ANTIBIOT_NAME = '4' then ANTIBIOT_NAME1 ='04';
		else if ANTIBIOT_NAME = '6' then ANTIBIOT_NAME1 ='06';
		else if ANTIBIOT_NAME = '9' then ANTIBIOT_NAME1 ='09';
		else if ANTIBIOT_NAME = '10' then ANTIBIOT_NAME1 ='10';
		else if ANTIBIOT_NAME = '12' then ANTIBIOT_NAME1 ='11';
		else if ANTIBIOT_NAME = '22' then ANTIBIOT_NAME1 ='22';
		else if ANTIBIOT_NAME = '23' then ANTIBIOT_NAME1 ='23';
		else if ANTIBIOT_NAME = '31' then ANTIBIOT_NAME1 ='31';
		else if missing(ANTIBIOT_NAME) then ANTIBIOT_NAME1 = '99';
			else ANTIBIOT_NAME1 ='77';

	if missing(GISP_SEXWRK) then GISP_SEXWRK1 = '9';		
		else if GISP_SEXWRK = '0' OR GISP_SEXWRK = 'No' then GISP_SEXWRK1 = '0';
		else if GISP_SEXWRK = '1' OR GISP_SEXWRK = 'Yes' then GISP_SEXWRK1 = '1';
			else GISP_SEXWRK1 = '9';

	if missing(GISP_IDU) then GISP_IDU1 = '9';		
		else if GISP_IDU = '0' OR GISP_IDU = 'No' then GISP_IDU1 = '0';
		else if GISP_IDU = '1' OR GISP_IDU = 'Yes' then GISP_IDU1 = '1';
			else GISP_IDU1 = '8';

	if missing(GISP_NONIDU) then GISP_NONIDU1 = '9';		
		else if GISP_NONIDU = '0' OR GISP_NONIDU = 'No' then GISP_NONIDU1 = '0';
		else if GISP_NONIDU = '1' OR GISP_NONIDU = 'Yes' then GISP_NONIDU1 = '1';
			else GISP_NONIDU1 = '8';

	if missing(PENALLERGY) then PENALLERGY1 = '9';		
		else if PENALLERGY = '0' OR PENALLERGY = 'No' then PENALLERGY1 = '0';
		else if PENALLERGY = '1' OR PENALLERGY = 'Yes' then PENALLERGY1 = '1';
			else PENALLERGY1 = '8';

	if missing(GISP_ETRVL) then GISP_ETRVL1 = '9';
		else if GISP_ETRVL = '0' OR GISP_ETRVL = 'No' then GISP_ETRVL1 = '0';
		else if GISP_ETRVL = '1' OR GISP_ETRVL = 'Yes' then GISP_ETRVL1 = '1';

	if missing(GISP_ETRVL2) then GISP_ETRVL21 = '9';
		else if GISP_ETRVL2 = '0' OR GISP_ETRVL2 = 'No' then GISP_ETRVL21 = '0';
		else if GISP_ETRVL2 = '1' OR GISP_ETRVL2 = 'Yes' then GISP_ETRVL21 = '1';

	MEN_TIME = '1';
	FEM_TIME = '1';

	MENSEX = GISP_PTR_INV_M;
	if missing(GISP_PTR_INV_M) then MENSEX = 999;
	
	FEMSEX = GISP_PTR_INV_F;
	if missing(GISP_PTR_INV_F) then FEMSEX = 999;


*Check code;
	if index(GENDER_SP, ',') > 0 then GENDER_SP1 = '3';
	    else if GENDER_SP = '1' then GENDER_SP1 = '1';
	    else if GENDER_SP = '2' then GENDER_SP1 = '2';
	    else if GENDER_SP = '3' then GENDER_SP1 = '3';
	    else GENDER_SP1 = '9';

	if missing(ExpSTD_PTR) then ExpSTD_PTR1 = '9';		
		else if ExpSTD_PTR = '0' OR ExpSTD_PTR = 'No' then ExpSTD_PTR1 = '0';
		else if ExpSTD_PTR = '1' OR ExpSTD_PTR = 'Yes' then ExpSTD_PTR1 = '1';
			else ExpSTD_PTR1 = '8';

	if missing(ExpSTD_HD) then ExpSTD_HD1 = '9';		
		else if ExpSTD_HD = '0' OR ExpSTD_HD = 'No' then ExpSTD_HD1 = '0';
		else if ExpSTD_HD = '1' OR ExpSTD_HD = 'Yes' then ExpSTD_HD1 = '1';
			else ExpSTD_HD1 = '8';

	/* SX Fix */
	if missing(SXPHARYNGEAL) then SXPHARYNGEAL1 = '9';		
		else if SXPHARYNGEAL = '0' OR SXPHARYNGEAL = 'No' then SXPHARYNGEAL1 = '0';
		else if SXPHARYNGEAL = '1' OR SXPHARYNGEAL = 'Yes' then SXPHARYNGEAL1 = '1';
			else SXPHARYNGEAL1 = '8';

	if missing(SXDYSURIA) then SXDYSURIA1 = '9';		
		else if SXDYSURIA = '0' OR SXDYSURIA = 'No' then SXDYSURIA1 = '0';
		else if SXDYSURIA = '1' OR SXDYSURIA = 'Yes' then SXDYSURIA1 = '1';
			else SXDYSURIA1 = '8';

	if missing(SXDISCHARGE) then SXDISCHARGE1 = '9';		
		else if SXDISCHARGE = '0' OR SXDISCHARGE = 'No' then SXDISCHARGE1 = '0';
		else if SXDISCHARGE = '1' OR SXDISCHARGE = 'Yes' then SXDISCHARGE1 = '1';
			else SXDISCHARGE1 = '8';	

	if missing(SXRECTAL) then SXRECTAL1 = '9';		
		else if SXRECTAL = '0' OR SXRECTAL = 'No' then SXRECTAL1 = '0';
		else if SXRECTAL = '1' OR SXRECTAL = 'Yes' then SXRECTAL1 = '1';
			else SXRECTAL1 = '8';

	if missing(SXABDOMEN) then SXABDOMEN1 = '9';		
		else if SXABDOMEN = '0' OR SXABDOMEN = 'No' then SXABDOMEN1 = '0';
		else if SXABDOMEN = '1' OR SXABDOMEN = 'Yes' then SXABDOMEN1 = '1';
			else SXABDOMEN1 = '8';


	/* HIV Fix */

	WHENHIVM = HIV_LAST_RESULT_M;
	WHENHIVY = hiv_test_year;
	if missing(WHENHIVM) then WHENHIVM = ' ';
	if missing(WHENHIVY) then WHENHIVY = ' ';


	if hiv_test = '1' OR hiv_test = 'Yes' then EVERHIV1 = '1';
		else if hiv_test = '0' OR hiv_test = 'No' then EVERHIV1 = '0';	
		else if hiv_test = 'Prefer not to answer' then EVERHIV1 = '8';
			else EVERHIV1 = '9';

	if hiv_test = 'Negative' then HIVRESULTLAST = '0';
		else if hiv_test = 'Prefer not to answer' then HIVRESULTLAST = '8';
			else HIVRESULTLAST = '0';

	GISP_HIVRESULT = HIVRESULTLAST;

	if prep = 'No' then PREP1 = '0';
		else if prep = 'Yes' then PREP1 = '1';
		else if prep = 'Unknown' then PREP1 = '9';
		else if HIVLASTRESULT = '1' then PREP1 = '7';
			else PREP1 = '9';

	PREP_REFER1 = PREP_REFER;
	if missing(Prep_Refer) then Prep_Refer1 = '9';
		else if Prep_Refer = '10' then Prep_Refer1 = '1';
	

	if missing(hivcare) then HIVCARE1 = '9';
		else HIVCARE1 = hivcare;

	if HIVRESULTLAST = '1' then HIVCARE_REFER = '7';
		else HIVCARE_REFER = '9';

	/* TRMT Fix */
	if DATE_GON_TRT ne '' then DATETX = input(DATE_GON_TRT,anydtdte32.); 
		else DATETX = '';

	if missing(TRMT1) then TRMT11 = '99';
		else if TRMT1 = '0' then TRMT11 = '00';
		else if TRMT1 = '9' then TRMT11 = '99';
		else TRMT11 = TRMT1;

	if missing(TRMT2) then TRMT21 = '';
		else if TRMT2 = '0' then TRMT11 = '00';
		else if TRMT2 = '9' then TRMT11 = '09';
		else TRMT21 = TRMT2;


	if TRMT11 = '77' then Medication1_OTH = TRMT1_77_TEXT;
		else Medication1_OTH = '';


	/* TCT Fix */
	if TOC_VIS = '1' then TOC_VIS1 = '1';
		else if TOC_VIS = '0' then TOC_VIS1 = '0';
			else TOC_VIS1 = '';

	if missing(TCT_SEX) then TCT_SEX1 = '9';		
		else if TCT_SEX = '0' OR TCT_SEX = 'No' then TCT_SEX1 = '0';
		else if TCT_SEX = '1' OR TCT_SEX = 'Yes' then TCT_SEX1 = '1';
			else TCT_SEX1 = '8';

	if missing(TCT_SAMEPTR) then TCT_SAMEPTR1 = '9';		
		else if TCT_SAMEPTR = '0' OR TCT_SAMEPTR = 'No' then TCT_SAMEPTR1 = '0';
		else if TCT_SAMEPTR = '1' OR TCT_SAMEPTR = 'Yes' then TCT_SAMEPTR1 = '1';
			else TCT_SAMEPTR1 = '8';

	if missing(GISP_COND_USE) then TCT_CONDUSE1 = '9';		
		else if GISP_COND_USE = '0' OR GISP_COND_USE = 'No' then TCT_CONDUSE1 = '0';
		else if GISP_COND_USE = '1' OR GISP_COND_USE = 'Yes' then TCT_CONDUSE1 = '1';
			else TCT_CONDUSE1 = '8';

	if missing(TCT_SAMPETRCU) then TCT_SAMPETRCU1 = '9';		
		else if TCT_SAMPETRCU = '0' OR TCT_SAMPETRCU = 'No' then TCT_SAMPETRCU1 = '0';
		else if TCT_SAMPETRCU = '1' OR TCT_SAMPETRCU = 'Yes' then TCT_SAMPETRCU1 = '1';
			else TCT_SAMPETRCU1 = '8';
	

	drop StartDate EndDate Status IPAddress Progress Duration__in_seconds_ Finished
		 ResponseID ExternalReference RecipientLastName RecipientFirstName RecipientEmail LocationLatitude 
		 LocationLongitude DistributionChannel UserLanguage Q_BallotBoxStuffing  PTNR_FirstName 
		 PTNR_LastName FirstName_1 LastName_1 ART PEN Q14__Parent_topics Q14___Topics Q14___Parent_topics
		 Q1___Parent_Topics Q1___Topics Q42___Parent_topics Q42___Topics Q4___Parent_topics Q4___Topics
		 Q5___Parent_topics Q5___Topics Q56___Parent_topics Q56___Topics Q57_6_TEXT___Parent_topics Q57_6_TEXT___Topics
		 Q58_5_TEXT___Parent_topics Q58_5_TEXT___Topics Q65___Parent_topics Q65___Topics Q66___Parent_topics Q66___Topics
		 Q56 Q57 Q58 ANTIBIOT_Name_1 HIV_LAST_RESULT_M_1_TEXT HIV_LAST_RESULT_Y_2010_TEXT RS_U RS_P RS_C Visit_Date 
		 DOB DOB2 DOB3 DOB4 DOB_1 VisDate NAAT_TEST_VISIT_1--NAAT_TEST_VISIT_5 GON_CULT_VISIT_1--GON_CULT_VISIT_4
		 ;
	
	if missing(ACHD_EMR) AND EMR ne '' then MRN = EMR;
		else MRN = ACHD_EMR;

	ALTID = upcase(cats(substr(FirstName,1,3), substr(LastName,1,3), put(DOBa,yymmddn8.)));


run;

proc sort data = junoct;
	by zipcode;
run;

data orgjunoct;
	merge junoct(in=jun) zipcodes.zipcodes(in=zip);
	by zipcode;
	format COUNTYRES $3. PTJURIS $1. PTXCTRACT $11. CL_FACILITY_LOCATION $6.;


	if missing(county_no) then COUNTYRES = '999';
		else COUNTYRES = county_no;

	if number = '42' then PTJURIS = '1';
		else if number ne '42' then PTJURIS = '0';
		else PTJURIS = '9';

	PTXCTRACT = '';
	CL_FACILITY_LOCATION = 'SITE-01';

	drop county abb state number;
	 if jun = 1 then output;
run;

data orgClean;
	set orgjunoct;
	format ALTID $18.;

	drop
		ANTIBIOT_NAME TRMT1 TRMT2
		GISP_GCHX GISP_GCHXN EVERHIV GISP_SEXWRK GISP_IDU GISP_NONIDU
		GISP_ETRVL GISP_ETRVL2 PENALLERGY GENDER_SP ExpSTD_PTR
		ExpSTD_HD SXPHARYNGEAL SXDYSURIA SXDISCHARGE SXRECTAL SXABDOMEN 
		TCT_SEX TCT_CONDUSE TCT_SAMEPTR TCT_SAMPETRCU TOC_VIS
		PREP PREP_REFER HIVCARE
		GISP_ANTIBIOT GISP_GCHXN 
	; 

	run;

data orgrename;
set orgclean;
format MRN $18. GISP_ANTIBIOT $3. GISP_GCHXN 3.;
length GISP_ANTIBIOT1 $3. GISP_GCHXN1 3.;

	rename  VisDT = VisDate
			GISP_GCHXN1 = GISP_GCHXN
			ANTIBIOT_NAME1 = ANTIBIOT_NAME
			TRMT11 = TRMT1 
			TRMT21 = TRMT2
			GISP_GCHX1 = GISP_GCHX
			SURV_GCHX1 = SURV_GCHX
			GISP_SEXWRK1 = GISP_SEXWRK
			GISP_IDU1 = GISP_IDU 
			GISP_NONIDU1 = GISP_NONIDU
			GISP_ETRVL1 = GISP_ETRVL
			GISP_ETRVL21 = GISP_ETRVL2
			PENALLERGY1 = PENALLERGY
			GENDER_SP1 = GENDER_SP
			ExpSTD_PTR1 = ExpSTD_PTR
			ExpSTD_HD1 = ExpSTD_HD
			SXPHARYNGEAL1 = SXPHARYNGEAL
			SXDYSURIA1 = SXDYSURIA
			SXDISCHARGE1 = SXDISCHARGE
			SXRECTAL1 = SXRECTAL
			SXABDOMEN1 = SXABDOMEN
			EVERHIV1 = EVERHIV
			TOC_VIS1 = TOC_VIS
			TCT_SEX1 = TCT_SEX
			TCT_CONDUSE1 = TCT_CONDUSE
			TCT_SAMEPTR1 = TCT_SAMEPTR
			TCT_SAMPETRCU1 = TCT_SAMPETRCU
			PREP1 = PREP
			PREP_REFER1 = PREP_REFER
			HIVCARE1 = HIVCARE
			GISP_ANTIBIOT1 = GISP_ANTIBIOT
			

;
run;

proc sort data = orgrename;
	by MRN;
run;

data survey1;
set orgrename;
	keep 
		MRN
		ALTID
		DATETX 
		GISP_GCHXN 
		VISDATE
		CL_STATE
		VISDATE
		CL_FACILITY_LOCATION
		COUNTYRES
		PTXCTRACT
		PTJURIS
		GENDER
		SEXBIRTH
		PT_AGE
		HISP_ETH
		AIAN
		ASIAN
		NHOPI
		BLACK
		WHITE
		MULTIRACE
		OTHRACE
		PREGNANT
		GISP_GCHX
		SURV_GCHX
		GISP_GCHXN
		GISP_ANTIBIOT
		ANTIBIOT_NAME
		GISP_SEXWRK
		GISP_IDU
		GISP_NONIDU
		GISP_ETRVL
		GISP_ETRVL2
		PENALLERGY
		MENSEX
		MEN_TIME
		FEMSEX
		FEM_TIME
		GENDER_SP
		ExpSTD_PTR
		ExpSTD_HD
		SXPHARYNGEAL
		SXDYSURIA
		SXDISCHARGE
		SXRECTAL
		SXABDOMEN
		EVERHIV
		WHENHIVM
		WHENHIVY
		HIVRESULTLAST
		GISP_HIVRESULT
		PREP
		PREP_REFER
		HIVCARE
		HIVCARE_REFER
		DATETX
		TRMT1
		MEDICATION1_OTH
		TRMT2
		TOC_VIS
		TCT_SEX
		TCT_CONDUSE
		TCT_SAMEPTR
		TCT_SAMPETRCU
		;

		run;


proc sort data=survey1;
by ALTID descending MRN;
run;

%include "file_location";

proc sort data=survey2;
by ALTID DESCENDING MRN;
run;

%include "file_location";

proc sort data=surveyv2;
by MRN;
run;

data survey3;
	set survey1 survey2;

	if Gender_SP = '9' AND (0 < MENSEX < 999) then Gender_SP = '1';
		else if Gender_SP = '9' AND (0 < FEMSEX < 999) then Gender_SP = '2';
			else if Gender_SP = '9' AND (0 < FEMSEX < 999) AND (0 < MENSEX < 999) then Gender_SP = '3';


if missing(MRN) and ALTID = '.' then delete;
run;

%let varlist = MRN PT_AGE GENDER SEXBIRTH HISP_ETH AIAN BLACK NHOPI WHITE ASIAN MULTIRACE OTHRACE PENALLERGY EVERHIV WHENHIVM WHENHIVY;
%let varlist_w = MRN_w PT_AGE_w GENDER_w SEXBIRTH_w HISP_ETH_w AIAN_w BLACK_w NHOPI_w WHITE_w ASIAN_w MULTIRACE_w OTHRACE_w PENALLERGY_w EVERHIV_w WHENHIVM_w WHENHIVY_w;

proc sort data=survey3 out=surv_srt;
by ALTID &varlist.;
run; 

/*- Initialize columns with missing values (Blanks) by assigning special values(9,99,etc.) -*/

data surv(drop=j);
set surv_srt;
by ALTID &varlist.;
array vartmp[*] $ MRN GENDER SEXBIRTH HISP_ETH AIAN BLACK NHOPI WHITE ASIAN MULTIRACE OTHRACE PENALLERGY EVERHIV;
if not(first.ALTID and last.ALTID) then do;
	if PT_AGE = . then PT_AGE = 999;
    if compress(WHENHIVM) in ('','.') then WHENHIVM = '99';
    if compress(WHENHIVY) in ('','.') then WHENHIVY = '9999';
	do j = 1 to dim(vartmp);
    	if compress(vartmp[j]) in ('','.') then vartmp[j] = '9';
	end;
end;
run;

proc sort data=surv out=surv_srt;
by ALTID &varlist.;
run;
data surv_fnl(drop=&varlist_w.);
set surv_srt;
by ALTID &varlist.;
retain &varlist_w.;
/*- Replace missing values -*/
if not(first.ALTID and last.ALTID) then do; /* only apply to multiple records and leave single record unchanged*/
	if first.ALTID then do;
		MRN_w = MRN;
		PT_AGE_w = PT_AGE;
    	GENDER_w = GENDER;
    	SEXBIRTH_w = SEXBIRTH;
    	HISP_ETH_w = HISP_ETH;
    	AIAN_w = AIAN;
    	BLACK_w = BLACK;
        NHOPI_w = NHOPI;
        WHITE_w = WHITE;
        ASIAN_w = ASIAN;
        MULTIRACE_w = MULTIRACE;
        OTHRACE_w = OTHRACE;
        PENALLERGY_w = PENALLERGY;
        EVERHIV_w = EVERHIV;
        WHENHIVM_w = WHENHIVM;
        WHENHIVY_w = WHENHIVY;
	end;
	else do;
		MRN = MRN_w;
		PT_AGE = PT_AGE_w;
    	GENDER = GENDER_w;
    	SEXBIRTH = SEXBIRTH_w;
    	HISP_ETH = HISP_ETH_w;
    	AIAN = AIAN_w;
    	BLACK = BLACK_w;
        NHOPI = NHOPI_w;
        WHITE = WHITE_w;
        ASIAN = ASIAN_w;
        MULTIRACE = MULTIRACE_w;
        OTHRACE = OTHRACE_w;
        PENALLERGY = PENALLERGY_w;
        EVERHIV = EVERHIV_w;
        WHENHIVM = WHENHIVM_w;
        WHENHIVY = WHENHIVY_w;
	end;
end;
run;

proc sql;
   create table survey4 as
   select * 
   from surv_fnl
   where length(strip(MRN)) >= 4 AND NOT prxmatch("/[a-zA-Z]/",strip(MRN)) > 0
   order by length(strip(MRN)) desc;
quit;

data reports.survey;
set survey4 surveyv2;
run;

proc sort data=reports.survey ;
by MRN VISDATE;
run;

/*

proc freq data=reports.survey;
table SEXBIRTH;
table Gender;
table HISP_ETH;
table PREP;
table ASIAN;
table AIAN;
table BLACK;
table WHITE;
table NHOPI;
table OTHRACE;
table MULTIRACE;
table GENDER_SP;


run;

*/
