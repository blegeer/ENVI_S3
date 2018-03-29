FUNCTION getS3FolderList, bucketName, folderName

s3utilspath = 'd:\Github\cso_s3utils'
resp = Python.run('sys.path.append("'+s3utilspath+'")')
resp = Python.run('import cso_s3utils as cso')

resp = Python.Run('folders = cso.getS3FolderList("'+bucketName+'","'+folderName+'", None, None)')
folders = Python.folders
return, folders.toArray()

END

FUNCTION getS3FileList, bucketName, folderName, FILTER=filter

  s3utilspath = 'd:\Github\cso_s3utils'
  resp = Python.run('sys.path.append("'+s3utilspath+'")')
  resp = Python.run('import cso_s3utils as cso')

  if (filter eq !NULL) then sfilter = 'None' else sfilter = '"'+filter+'"'
  resp = Python.Run('files = cso.getS3FileList("'+bucketName+'","'+folderName+'", None, None, match='+sfilter+')')
  files = Python.files
  return, files.toArray()

END

PRO getS3File, bucketName, keyName, outFile

  s3utilspath = 'd:\Github\cso_s3utils'
  resp = Python.run('sys.path.append("'+s3utilspath+'")')
  resp = Python.run('import cso_s3utils as cso')

  if (filter eq !NULL) then sfilter = 'None' else sfilter = '"'+filter+'"'
  resp = Python.Run('files = cso.getS3KeyToFile("'+bucketName+'","'+keyName+'","'+outFile+'", None, None)')
   
END