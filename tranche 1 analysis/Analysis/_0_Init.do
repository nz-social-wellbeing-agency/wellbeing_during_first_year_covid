/////////INITILIALISATION FILE



global DL_DRIVE "wprdfs09/"
global logs "I:\MAA2013-16 Citizen pathways through human services\Shaan\Immigration\logs/"
global raw_dats "I:\MAA2013-16 Citizen pathways through human services\Shaan\Immigration\data/raw/"
global dtas "I:\MAA2013-16 Citizen pathways through human services\Shaan\Immigration\data/stata/"
global progs "I:\MAA2013-16 Citizen pathways through human services\Shaan\Immigration\progs/"
global output "I:\MAA2013-16 Citizen pathways through human services\Shaan\Immigration\output/"



adopath + "//${DL_DRIVE}/gendata/motu census/projects/dave/ado/"
adopath + "//${DL_DRIVE}/GenData/motu census/Programs/Uniform_Files/ado/plus/m/"
adopath + "//${DL_DRIVE}/Gendata/dl common files/stata ado files/"
adopath + "//${DL_DRIVE}/Gendata/Stata common files/"
 run "I:\MAA2013-16 Citizen pathways through human services\Shaan\Immigration\progs\mmerge.ado" 
adopath + "//${DL_DRIVE}/gendata-motu census/projects/dave/ado/"
adopath + "I:\MAA2003-18\Projects\Shaan\DoMe"
adopath + "K:\Stata Common Files\estout"
adopath + "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code/"
adopath + "I:\MAA2003-18\Projects\Dave\_Archive\Dave_Confid_files\DM_confid_2016_02"
capture run "tabout.ado" 
do "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\grr.ado"
run "I:\MAA2021-49\SWA_development\Main\Staging\Stata_code\grrnum.ado"

