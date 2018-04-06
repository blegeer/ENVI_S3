; NOTES: 
;
; This library of routines interfaces the 'cso_s3utils.py' module
; for access AWS S3 objects
; AWS credentials can be sent it either via keyword parameters or 
; set through other AWS standard mechanisms such as environment variables
; or config files. See AWS docuementation for details.

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
   
  search_path = expand_path('+'+dir, /ALL_DIR)
  foreach testFile, [libNamePy, libNamePyc] do begin
    tFile = file_which(search_path, testFile)
    if (tFile ne '') then libDir = file_dirname(tFile) 
  endforeach
  
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


FUNCTION getBucketNames, ERROR=errMsg, $
  ACCESS_KEY=access_key, $
  SECRET_KEY=secret_key, $
  TOKEN=token

; Get the list of available buckets for the account specified by the credentials

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

; if credentials are not sent in, boto will use the AWS environment vars

  if (access_key eq !NULL) then access_key=Python.None
  if (access_key eq !NULL) then access_key=Python.None
  if (token eq !NULL) then token=Python.None
  
  cso=loadpythonlib('cso_s3utils')
  buckets=cso.getBucketNames(accessKey=access_key, secretKey=secret_key, token=token) 
  return, buckets.toArray()
  
END

FUNCTION getS3FolderList, bucketName, folderName, ERROR = errMsg, $
  ACCESS_KEY=access_key, $
  SECRET_KEY=secret_key, $
  TOKEN=token

; Given an S3 bucket and a folder (key) under that bucket
; return a list of folders within that bucket/folder

compile_opt idl2

  errMsg=''
  catch, errorno
  if (errorno ne 0) then begin
    catch, /cancel
    help, /last_message, output = errMsg
    print, "ERROR getting S3 Folder List"
    print, errMsg
    return, !NULL
  endif

if (access_key eq !NULL) then access_key=Python.None
if (access_key eq !NULL) then access_key=Python.None
if (token eq !NULL) then token = Python.None

cso=loadpythonlib('cso_s3utils')
folders = cso.getS3FolderList(bucketName, folderName,accesskey=access_key, secretkey=secret_key, token=token)
return, folders.toArray()

END

FUNCTION getS3FileList, bucketName, folderName, FILTER=filter, ERROR = errMsg, $
  ACCESS_KEY=access_key, $
  SECRET_KEY=secret_key, $
  TOKEN=token

; give an S3 bucket and folder name - return a list of regular files in that bucket. 

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

if (access_key eq !NULL) then access_key=Python.None
if (access_key eq !NULL) then access_key=Python.None
if (token eq !NULL) then token = Python.None


  cso=loadpythonlib('cso_s3utils')
    
  if (filter eq !NULL) then filter=!NULL
  files = cso.getS3FileList(bucketName, folderName, MATCH=filter,accesskey=access_key, secretkey=secret_key, token=token)
  return, files.toArray()

END

PRO getS3File, bucketName, keyName, outFile, ERROR = errMsg, $
  ACCESS_KEY=access_key, $
  SECRET_KEY=secret_key, $
  TOKEN=token

; given a bucket and keyname, download the file contained in that key to the local location in outfile 

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

if (access_key eq !NULL) then access_key=Python.None
if (access_key eq !NULL) then access_key=Python.None
if (token eq !NULL) then token = Python.None


  cso=loadpythonlib('cso_s3utils')
  files = cso.getKeyToFile(bucketName, keyName, outFile,accesskey=access_key, secretkey=secret_key, token=token)
  
  
END

PRO getS3Folder, bucketName, folderName, rootDir, ERROR = errMsg, $
  ACCESS_KEY=access_key, $
  SECRET_KEY=secret_key, $
  TOKEN=token


; given a bucketname, foldername download the contents of that folder and
; all subdirs to the rootDir. 
; The root Dir will contain the entire path heirarchy of the foldername

compile_opt idl2

  errMsg=''
  catch, errorno
  if (errorno ne 0) then begin
    catch, /cancel
    help, /last_message, output = errMsg
    print, "ERROR getting S3 Folder"
    print, errMsg
    return
  endif
  
if (access_key eq !NULL) then access_key=Python.None
if (access_key eq !NULL) then access_key=Python.None
if (token eq !NULL) then token = Python.None

  cso=loadpythonlib('cso_s3utils')
  resp = cso.getS3Folder(bucketName, folderName, rootDir,accesskey=access_key, secretkey=secret_key, token=token)

END
