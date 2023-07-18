/*

data reports.RANDID;
	length CL_patID $18;
	call streaminit(593876);
	  do NOBS = 1 to 3000000 ;
	    CL_patID = "                  " ; 
	    do i = 1 to 7;

	      rannum = int(uniform(0)*36) ;                          

	      if (0  <= rannum <= 9) then ranch = byte(rannum + 48) ;

	      if (10 <= rannum <= 36) then ranch = byte(rannum + 55); 

	      substr(CL_patID,i,1) = ranch ;
	    end;
	    ranord = uniform(1);
		randnum = ranuni(1010);
	    output ;
	  end;
	keep CL_patID ranord randnum;
run;

*/


data pidmrnachdco;
	set reports.achdcolab reports.cdd;
	format ALTID CL_patID $18.;
	length temp $100 pat_id1 $18.;

	if missing(patID) AND MRN ne '' then pat_ID1 = MRN;
		else if missing(patID) AND missing(MRN) and pat_ID ne '' then pat_ID1 = pat_ID;
		else if missing(patID) AND missing(MRN) and pat_ID ne '' then pat_ID1 = pat_ID;
		else pat_ID1 = patID;

	if pat_ID1 = '000000000' or pat_ID1 = '00000000' or pat_ID1 = 'mr' then pat_ID1 = ALTID;


	*temp = catx('', pat_ID1, MRN, ALTID);


	*if FACILITY_LOCATION = 'PIT-01' then output pidmrnachd;
		*else if FACILITY_LOCATION = 'PIT-02' then output pidmrnco;

	keep MRN patID pat_ID1 ALTID;
run;

data idmerg;
	set pidmrnachdco;
	if MRN = 'xyz' then delete;

if pat_ID1 ne '' then temp = pat_ID1;
	else temp = ALTID;


array vars {*} _character_;
miss_count = 0;
do i=1 to dim(vars);
if missing(vars{i}) then miss_count = miss_count + 1;
end;

run;

proc sort data=idmerg;
	by temp miss_count;
run;

data idmerg2;
set idmerg;
by temp;
if first.temp;
run;

proc sort data = reports.randid nodupkey;
	by randnum;
run;

data falseid;
	call streaminit(593876);
	merge idmerg2 reports.Randid;

	output;
	drop ranord;
run;

data reports.CLpatID;
	call streaminit(593876);
	set falseid;

	md5 = substr(put(md5(temp), $hex32.), 1, 18);
	drop miss_count i randnum;
run;


data reports.CLpatID;
    merge reports.clpatid_master (in=a)
          falseid (in=b);
    by temp;

    if a and b then do;
        /* If the record is in both datasets, 
        it's an old record, so keep the ID from the master dataset */
        id = id;
    end;
    else if b then do;
        /* If the record is only in the falseid dataset, 
        it's a new record, so assign the new ID */
        id = md5;
    end;

    drop md5;

run;

proc compare base=reports.CLpatID_master compare=reports.CLpatID_master_copy outnoequal;
id temp;

run;


/*
* Run the following only if report above shows no duplicates;

data reports.clpatid_master;
set reports.clpatid;
run;
*/


/* 
proc freq data = pidmrnachdco order=freq;
	table pat_ID1;
run;

proc sql;
	create table test5 as
	select CL_patID, count(distinct CL_patID) as count
	from work.clnlabfix3
	group by CL_patID;
quit;

proc freq data = idmerg order=freq;
	table ALTID MRN pat_ID;
run;

proc compare base=reports.CLpatID_master compare=reports.CLpatID_master_copy outnoequal;
id temp;

run;

proc compare base=reports.CLpatID_master compare=reports.CLpatID_master_copy outnoequal;
id temp;

run;
*/
