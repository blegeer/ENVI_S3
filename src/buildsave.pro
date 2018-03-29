.full_reset_session

mainDir = "d:\Github"
zipFile = filepath('envi3explorer.zip', ROOT=mainDir, SUBDIR="ENVI_S3")
if (file_test(zipFile)) then file_delete, zipFile
saveFile = filepath('envi3explorer.sav', ROOT=mainDir, SUBDIR=["ENVI_S3","SAVE"])
if (file_test(saveFile)) then file_delete, zipFile

cd, filepath("src", ROOT=mainDir, SUBDIR="ENVI_S3")
.compile envis3explorer
.compile idl_s3utils
resolve_all, SKIP_ROUTINES=['envi', 'image']
save, file=saveFile, /routines

cd, mainDir
file_zip, 'ENVI_S3', zipFile, /VERBOSE
 



