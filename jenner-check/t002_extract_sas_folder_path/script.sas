/* -------------------------------------------------------------------------- *
 * Bundle: t002_extract_sas_folder_path
 *
 * Exercises the %_extract_sas_folder_path macro from the repo's SAS Studio
 * custom step ExportViyaContentObject.step / ImportViyaContent.step. The macro
 * strips the scheme prefix off a path reference and returns the folder path,
 * using SCAN(...,2,":","MO") inside a DATA step + CALL SYMPUT. It pairs with
 * %_identify_content_or_server (which returns element 1, the scheme).
 *
 * The macro definition below is copied verbatim from the repo. It runs
 * stand-alone; a small caller with mock path references drives it here.
 * -------------------------------------------------------------------------- */

/* --- repo macro, verbatim from templates.SAS in the .step files --- */
%macro _extract_sas_folder_path(pathReference);
   %global _sas_folder_path;
   data _null_;
      call symput("_sas_folder_path", scan("&pathReference.",2,":","MO"));
   run;
%mend _extract_sas_folder_path;

/* --- caller: drive the macro over a few representative path references --- */
%macro _demo_extract(pathReference);
   %_extract_sas_folder_path(&pathReference.);
   %put NOTE: input=&pathReference. -> _sas_folder_path=&_sas_folder_path.;
%mend _demo_extract;

%_demo_extract(sascontent:/Public/Reports/Sales);
%_demo_extract(sasserver:/opt/sas/viya/config/data/exports);
%_demo_extract(sascontent:/create-export/create/homes);

/* Collect scheme + folder path pairs so the run has a listing. */
data folder_paths;
   length pathReference $128 scheme $32 folderPath $96;
   pathReference = "sascontent:/Public/Reports/Sales";
      scheme = scan(pathReference,1,":","MO"); folderPath = scan(pathReference,2,":","MO"); output;
   pathReference = "sasserver:/opt/sas/viya/config/data/exports";
      scheme = scan(pathReference,1,":","MO"); folderPath = scan(pathReference,2,":","MO"); output;
   pathReference = "sascontent:/create-export/create/homes";
      scheme = scan(pathReference,1,":","MO"); folderPath = scan(pathReference,2,":","MO"); output;
run;

proc print data=folder_paths noobs;
   var pathReference scheme folderPath;
run;
