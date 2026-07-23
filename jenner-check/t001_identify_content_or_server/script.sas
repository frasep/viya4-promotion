/* -------------------------------------------------------------------------- *
 * Bundle: t001_identify_content_or_server
 *
 * Exercises the %_identify_content_or_server macro from the repo's SAS Studio
 * custom step ExportViyaContentObject.step / ImportViyaContent.step. The macro
 * classifies a path reference by its scheme prefix (e.g. "sascontent" vs
 * "sasserver") using SCAN(...,1,":","MO") inside a DATA step + CALL SYMPUT.
 *
 * The macro definition below is copied verbatim from the repo. The Viya REST
 * calls in the original step are not part of this macro, so it runs stand-alone;
 * a small caller with mock path references drives it here.
 * -------------------------------------------------------------------------- */

/* --- repo macro, verbatim from templates.SAS in the .step files --- */
%macro _identify_content_or_server(pathReference);
   %global _path_identifier;
   data _null_;
      call symput("_path_identifier", scan("&pathReference.",1,":","MO"));
   run;
%mend _identify_content_or_server;

/* --- caller: drive the macro over a few representative path references --- */
%macro _demo_identify(pathReference);
   %_identify_content_or_server(&pathReference.);
   %put NOTE: input=&pathReference. -> _path_identifier=&_path_identifier.;
%mend _demo_identify;

%_demo_identify(sascontent:/Public/Reports/Sales);
%_demo_identify(sasserver:/opt/sas/viya/config/data/exports);
%_demo_identify(/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9);

/* Collect the classifications into a small dataset so the run has a listing. */
data path_classes;
   length pathReference $128 scheme $32;
   pathReference = "sascontent:/Public/Reports/Sales"; scheme = scan(pathReference,1,":","MO"); output;
   pathReference = "sasserver:/opt/sas/viya/config/data/exports"; scheme = scan(pathReference,1,":","MO"); output;
   pathReference = "/reports/reports/6b879807-19cd-4f27-bedc-17ce615fa9d9"; scheme = scan(pathReference,1,":","MO"); output;
run;

proc print data=path_classes noobs;
   var pathReference scheme;
run;
