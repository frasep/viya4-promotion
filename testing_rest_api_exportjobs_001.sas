%let BASE_URL = %sysfunc(getoption(servicesbaseurl));
%put &BASE_URL;
%let pkg_location = /create-export/create/homes/Sebastien.Poussart@sas.com/;

%macro transfer_export(objectURI,pkgName);

	/* Create export job */
	%let pkg_full_name=&pkg_location.&pkgName..json;

	%put "&pkg_full_name";

	FILENAME json_in temp ENCODING='UTF-8' ;
	FILENAME resp temp ENCODING='UTF-8' ;
	FILENAME json_PKG "&pkg_full_name" ENCODING='UTF-8' ;

	data _null_;
		file json_in;
		put '{'/
		  '"name" : "'"&pkgName."'",'/
		  '"items": ["'"&objectURI."'"],'/
		  '"options": {"includeDependencies":true}'/
		  '}';
	run;

    proc http 
		oauth_bearer=sas_services 
		method="POST" url="&BASE_URL/transfer/exportJobs" in=json_in out=resp;
        headers 
			"Accept"="application/json"
			"Content-type"="application/vnd.sas.transfer.export.request+json";
		debug level=3;
	run;

	LIBNAME resp clear;
	LIBNAME resp json;
	
	proc sql noprint;
	  select id into :job_id trimmed from resp.root;
	quit;

	%put &job_id;

	/* Wait until the job is completed */

	%wait_transfer_exportjob(&job_id, sleep=1, maxloop=120);

	/* Get the resulting export package URI */

	proc http method='GET' url="&BASE_URL/transfer/exportJobs/71a72065-3e28-49ed-9af9-e13fd649d2ea" oauth_bearer=sas_services out=resp;
	  headers
	    "Accept" = "application/json";
	  debug level=0;
	run;
	LIBNAME resp clear;
	LIBNAME resp json;

	proc sql noprint;
	  select packageUri into :pkg_uri trimmed from resp.root;
	quit;
	
	%put &pkg_uri;

	/* Download the resulting export package */

	proc http method='GET' url="&BASE_URL/&pkg_uri" oauth_bearer=sas_services out=json_PKG;
	  headers
	    "Accept" = "application/vnd.sas.transfer.package+json"
    	"Accept-encoding" = "gzip, deflate, br, zstd";
	  debug level=0;
	run;

	/* Delete the remaining export package from the sas content */
	
%mend;

/* Macro to wait for an export job to be completed using REST API (tested on 2024.08) */
%macro wait_transfer_exportjob(jobid, sleep=1, maxloop=120);
%local jobStatus i;

%do i = 1 %to &maxLoop;
  filename jobrc temp  ENCODING='UTF-8';
  proc http method='GET' url="&BASE_URL/transfer/exportJobs/&jobid/state" oauth_bearer=sas_services out=jobrc verbose;
    headers
      "Accept" = "text/plain";
    debug level=0;
  run;
  
  %put NOTE: response check job status;
  data _null_;
      infile jobrc;
      input line : $32.;
      putlog "NOTE: &sysmacroname jobId=&jobid i=&i status=" line;
      if line in ("completed", "failed") then do;
      end;
      else do;
        putlog "NOTE: &sysmacroname &jobid status=" line "sleep for &sleep.sec";
        rc = sleep(&sleep, 1);
      end;  
      call symputx("jobstatus", line);
  run;
  %put Dbg: &=jobstatus;
  filename jobrc clear;
  %if &jobstatus = completed %then %do;
    %put NOTE: &sysmacroname &=jobid &=jobStatus;
    %return;
  %end;
  %if &jobstatus = failed %then %do;
    %put ERROR: &sysmacroname &=jobid &=jobStatus;
    %return;
  %end;
%end;
%mend wait_transfer_exportjob;

%transfer_export(/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9,PackageTest001);
