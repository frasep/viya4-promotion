/* -------------------------------------------------------------------------- *
 * Bundle: t003_path_to_json_items
 *
 * Exercises the folder-path -> JSON-items transformation from the
 * %_obtain_sas_content_folder_uri macro in ExportViyaContentObject.step /
 * ImportViyaContent.step. In the original step this builds the request body
 * POSTed to the Viya /folders/paths endpoint; the string-building step itself
 * needs no Viya services, so it is exercised here in isolation.
 *
 * The transformation (verbatim from the repo) turns a slash-delimited folder
 * path into a JSON "items" array by:
 *   1. transtrn(path, "/", "   ")  -- each "/" becomes three spaces
 *   2. strip(...)                  -- drop the leading/trailing whitespace
 *   3. transtrn(..., "   ", '","') -- each interior gap becomes '","'
 * so "/Public/Reports/Sales" -> {"items": ["Public","Reports","Sales"], ...}.
 * A small wrapper macro drives it over a few mock paths.
 * -------------------------------------------------------------------------- */

%macro _build_path_json(targetFolderContent);
   %global targetPathJSON;
   /* --- string builder, verbatim from the repo's _obtain_sas_content_folder_uri --- */
   data _null_;
      call symput("targetPathJSON",'{"items": ['||'"'||transtrn(strip(transtrn(&targetFolderContent.,"/","   ")),"   ",'","')||'"'||'], "contentType": "folder"}');
   run;
   %put NOTE: input=&targetFolderContent. -> targetPathJSON=&targetPathJSON.;
%mend _build_path_json;

%_build_path_json("/Public/Reports/Sales");
%_build_path_json("/create-export/create/homes");
%_build_path_json("/gelcontent/GEL/Reports");

/* Materialize the same transformation into a dataset for a printable listing. */
data path_json;
   length folderPath $96 itemsJSON $256;
   folderPath = "/Public/Reports/Sales";
      itemsJSON = '{"items": ['||'"'||transtrn(strip(transtrn(folderPath,"/","   ")),"   ",'","')||'"'||'], "contentType": "folder"}';
      output;
   folderPath = "/create-export/create/homes";
      itemsJSON = '{"items": ['||'"'||transtrn(strip(transtrn(folderPath,"/","   ")),"   ",'","')||'"'||'], "contentType": "folder"}';
      output;
   folderPath = "/gelcontent/GEL/Reports";
      itemsJSON = '{"items": ['||'"'||transtrn(strip(transtrn(folderPath,"/","   ")),"   ",'","')||'"'||'], "contentType": "folder"}';
      output;
run;

proc print data=path_json noobs;
   var folderPath itemsJSON;
run;
