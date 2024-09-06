%let BASE_URI = %sysfunc(getoption(servicesbaseurl));
%let BASE_URI = %substr(&BASE_URI, 1, %length(&BASE_URI)-1);

/* Macro to wait for an export job to be completed using REST API (tested on 2024.08)
 * https://developer.sas.com/apis/rest/v3.5/Visualization/#get-the-state-of-the-job
 * https://create.demo.sas.com/transfer/exportJobs/463dab53-314f-45a2-8477-fe08a154418a/state
 */
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
%mend va_img_check_jobstatus;
%va_img_check_jobstatus(jobid=&jobid, sleep=1, maxloop=500)/*DBG 500*/;








/* Macro to launch an export of a given SAS Content object URI */
/* https://create.demo.sas.com/transfer/exportJobs */

%macro export(objectURI=);
        proc http oauth_bearer=sas_services method="post" url="&baseurl//transfer/exportJobs" out=resp headerout=headout HEADEROUT_OVERWRITE;
            headers "Accept"="application/json";
%mend;



* payload

/* POST 
https://create.demo.sas.com/transfer/exportJobs

content-type:
application/vnd.sas.transfer.export.job+json


{name: "Package_test", items: ["/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9"],…}
items
: 
["/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9"]
0
: 
"/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9"
name
: 
"Package_test"
options
: 
{includeRules: true, includeDependencies: true}
includeDependencies
: 
true
includeRules
: 
true

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