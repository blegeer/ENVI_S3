FUNCTION loadPythonLib, libName, ERROR = errMsg

compile_opt idl2

errMsg = ''
catch, errorno
if (errorno ne 0) then begin
   catch, /CANCEL
   help, /last_message, output = errMsg
   print, "ERROR loading python library"
   print, errMsg
   return, !NULL
endif

e = envi(/current)
if (e eq !NULL) then e = envi() 

; find the location of required python libraries and load them into the
; current IDL-Python session
; SearchPath: 
; 1) Current Directory
; 2) Users extensions directory
; 3) System Extensions directory

; subdirs
subdirs = ['python_lib']
; relative path
cd, current=curDir
dirLocations = [curDir, $
  e.preferences["directories and files:extensions directory"].value, $
  filepath('extensions', root = e.root)]

libDir = ''
libNamePy = libName+'.py'
libNamePyc = libName+'.pyc'

foreach dir, dirLocations do begin
   
  file = filepath(libNamePy, $
    ROOT=dir, $
    SUBDIR=subdirs)    
  if (file_test(file)) then libDir = file_dirname(file)
  
  file = filepath(libNamePyc, $
    ROOT=dir, $
    SUBDIR=subdirs)
  if (file_test(file)) then libDir = file_dirname(file)
  
endforeach

if (libDir ne '') then begin
  sys = Python.Import('sys')
  idx = sys.path.where(libDir, COUNT=cnt)
  if (cnt eq 0) then begin
    ; sys.path.add, libDir
    resp = Python.run('import sys')
    resp = Python.run('sys.path.append(r"'+libDir+'")')
  endif  
  libObj=Python.Import(libName)
endif else begin
  libObj = !NULL
endelse
return, libObj

END


FUNCTION getBucketNames, ERROR=errMsg

  errMsg=''
  catch, errorno
  if (errorno ne 0) then begin
    catch, /CANCEL
    help, /last_message, output = errMsg
    print, "ERROR getting S3 Bucket Name"
    print, errMsg
    return, !NULL
  endif

compile_opt idl2

  cso=loadpythonlib('cso_s3utils')
  buckets=cso.getBucketNames() 
  return, buckets.toArray()
  
END

FUNCTION getS3FolderList, bucketName, folderName, ERROR = errMsg

  errMsg=''
  catch, errorno
  if (errorno ne 0) then begin
    catch, /cancel
    help, /last_message, output = errMsg
    print, "ERROR getting S3 Folder List"
    print, errMsg
    return, !NULL
  endif
  
compile_opt idl2

cso=loadpythonlib('cso_s3utils')
folders = cso.getS3FolderList(bucketName, folderName)
return, folders.toArray()

END

FUNCTION getS3FileList, bucketName, folderName, FILTER=filter, ERROR = errMsg

compile_opt idl2

errMsg=''
catch, errorno
if (errorno ne 0) then begin
  catch, /CANCEL
  help, /last_message, output = errMsg
  print, "ERROR getting S3 File List"
  print, errMsg
  return, !NULL
endif

  cso=loadpythonlib('cso_s3utils')
    
  if (filter eq !NULL) then filter=!NULL
  files = cso.getS3FileList(bucketName, folderName, MATCH=filter)
  return, files.toArray()

END

PRO getS3File, bucketName, keyName, outFile, ERROR = errMsg

compile_opt idl2

errMsg=''
catch, errorno
if (errorno ne 0) then begin
  catch, /CANCEL
  help, /last_message, output = errMsg
  print, "ERROR getting S3 File"
  print, errMsg
  return
endif


  cso=loadpythonlib('cso_s3utils')
  files = cso.getKeyToFile(bucketName, keyName, outFile)
  
  
END

PRO getS3Folder, bucketName, folderName, rootDir, ERROR = errMsg

  errMsg=''
  catch, errorno
  if (errorno ne 0) then begin
    catch, /cancel
    help, /last_message, output = errMsg
    print, "ERROR getting S3 Folder"
    print, errMsg
    return
  endif
  
compile_opt idl2

  cso=loadpythonlib('cso_s3utils')
  resp = cso.getS3Folder(bucketName, folderName, rootDir)

END
