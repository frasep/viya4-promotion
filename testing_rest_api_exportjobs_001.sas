%let BASE_URL = %sysfunc(getoption(servicesbaseurl));

%put &BASE_URL;

%macro transfer_export(objectURI,pkgName);
	FILENAME json_in temp ENCODING='UTF-8' ;
	FILENAME resp temp ENCODING='UTF-8' ;

	data _null_;
		file json_in;
		put '{'/
		  '"name" : "'&pkgName.'",'/
		  '"items": ["'&objectURI.'"],'/
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

%mend;


%transfer_export("/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9","PackageTest001");

/* Macro to wait for an export job to be completed using REST API (tested on 2024.08) */
%macro wait_transfer_exportjob(
  jobid=
  , sleep=1
  , maxloop=120
);
%local jobStatus i;

%do i = 1 %to &maxLoop;
  filename jobrc temp;
  proc http
    method='GET' 
    url="&BASE_URI//transfer/exportJobs/&jobid/state"
    oauth_bearer=sas_services
  
    out=jobrc
    verbose
    ;
    headers
      "Accept" = "text/plain"
    ;
    debug level=3;
  run;
  %put NOTE: &=SYS_PROCHTTP_STATUS_CODE;
  %put NOTE: &=SYS_PROCHTTP_STATUS_PHRASE;
  
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
%wait_transfer_exportjob(jobid=&jobid, sleep=1, maxloop=500)/*DBG 500*/;



/* Macro to launch an export of a given SAS Content object URI */
/* https://create.demo.sas.com/transfer/exportJobs */
/*
{
	"name":"Package_test",
	"items":["/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9"],
	"options": {"includeRules":true,"includeDependencies":true}
}
*/





* payload

/* POST 
https://create.demo.sas.com/transfer/exportJobs

content-type:
application/vnd.sas.transfer.export.job+json


{
	"name":"Package_test",
	"items":["/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9"],
	"options": {"includeRules":true,"includeDependencies":true}
}

*/



/*
Wait for state to be completed

completed value

https://create.demo.sas.com/transfer/exportJobs/463dab53-314f-45a2-8477-fe08a154418a/state
*/


/* get the json package 

GET

https://create.demo.sas.com/transfer/packages/a3ca2059-ad19-4f96-afce-f1961c3de569

content-type:
application/json



*/