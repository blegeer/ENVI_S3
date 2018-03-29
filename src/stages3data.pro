PRO testS3Raster

compile_opt idl2


bucket = 'vendor-ingress'
key = 'ks-sites/SecureWatch/K3A_20170501102242_11598_00049515_L1R_Bundle.zip

;r = stages3data(accesskey = accesskey, secretkey = secretkey, bucket = bucket, key = key, /FILE)
;print, 'Single file returns '+r

bucket = 'content-stage'
key = 'stage/out13/'
r = stages3data(accesskey = accesskey, secretkey = secretkey, bucket = bucket, key = key, /COLLECT)
print, 'Collect returns '+r

END

FUNCTION StageS3Data, OUTDIR=outdir, $
  ACCESSKEY=accesskey, $
  SECRETKEY=secretkey, $
  BUCKET=bucketName, $
  KEY=key, $
  FILE=file, $
  COLLECT=collect, $
  STATUSLABEL = statuslabel

e = envi(/current)
if (e eq !NULL) then e = envi(/headless)

usestatus = !FALSE
if (n_elements(statuslabel) eq 1) then begin
  if (widget_info(statuslabel, /VALID)) then usestatus=!TRUE
endif

v = e.preferences["directories and files:extensions directory"]
extensionsDir = v.value
s3ToolsPython = extensionsDir + 'cso_s3utils.py'
if (not file_test(s3ToolsPython)) then begin
    err = 'ERROR opening required python library '+s3ToolsPython
    if (usestatus) then widget_control, statuslabel, SET_VALUE=err
    print, 'ERROR opening required python library '+s3ToolsPython
    return, !NULL
endif

; restore the python library
!NULL = Python.run('execfile(r"'+s3ToolsPython+'")')

credentialString = '"'+accessKey+'","'+secretKey+'"'
; handle the case where this is just a single file

retVal = !NULL

if (n_elements(outdir) eq 0) then begin
  outdir = file_dirname(filepath('test.dat', /TMP))
endif else begin
  if (not file_test(outdir)) then begin
    file_mkdir, outdir
  endif
endelse

if (keyword_set(file)) then begin
    
    localFile = outdir + path_sep() + file_basename(key)
    if (usestatus) then widget_control, statuslabel, SET_VALUE = 'Local File stored in '+localFile
    print, 'Local File stored in '+localFile
    if (usestatus) then widget_control, statuslabel, SET_VALUE = 'Getting '+key
    print, 'Getting '+key
    !NULL = Python.run('getKeyToFile("'+bucketName+'","'+key+'",r"'+localFile+'",'+credentialString+')')
    retVal = localFile
    
endif else if (keyword_set(collect)) then begin
    collectName = file_basename(key)
    localDir = outdir+path_sep()+collectName
    if (not file_test(localDir, /DIR)) then begin
       file_mkdir, localDir
    endif
    
    print, 'Collect Stored in '+localDir
    !NULL = Python.run('files = getS3FileList("'+bucketName+'","'+key+'",'+credentialString+')')
    files = Python.files

    ; get the files in the collect from S3
    foreach keyName, files do begin
      localFile = localDir+path_sep()+file_basename(keyName) 
      if (usestatus) then widget_control, statuslabel, SET_VALUE = 'Getting '+keyName
      print, 'Getting '+keyName    
      !NULL = Python.run('getKeyToFile("'+bucketName+'","'+keyName+'",r"'+localFile+'",'+credentialString+')')      
    endforeach
    retval = localDir
    
endif

return, retval

END
