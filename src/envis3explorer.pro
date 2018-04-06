PRO envis3explorer_extensions_init

compile_opt idl2

e = envi(/current)

e.AddExtension, 'ENVI AWS S3 Explorer', 'envis3explorer'

END


FUNCTION getBitmap, bitmapName, squareSize

compile_opt idl2

e = envi(/current)

if (n_params() eq 1) then squareSize=16

; subdirs
subdirs = ['envi_s3','bitmaps']
; relative path
cd, current=curDir
dirLocations = [curDir, $
  e.preferences["directories and files:extensions directory"].value, $
  filepath('extensions', root = e.root)]

bitmapFile = ''
foreach dir, dirLocations do begin
  if (~bitmapName.endswith('.png')) then bitmapName+='.png'
  
  search_path = expand_path('+'+dir, /ALL_DIR)
  file = file_which(search_path, bitmapName)
  if (file ne '') then bitmapFile=file
  
endforeach

if (bitmapFile ne '') then begin
   bitmap = congrid(transpose(read_png(bitmapfile),[1,2,0]), squareSize, squareSize, 4)
endif else begin
   bitmap = !NULL
endelse

return, bitmap

END

FUNCTION GoodAWSEnvironmentVars

compile_opt idl2 

goodAWS = !TRUE

aKey = getenv('AWS_ACCESS_KEY_ID')
if (aKey eq !NULL OR aKey eq '') then goodAWS=!FALSE 

sKey = getenv('AWS_SECRET_ACCESS_KEY')
if (sKey eq !NULL OR sKey eq '') then goodAWS=!FALSE

return, goodAWS

END

PRO OpenS3CollectInENVI, bucketName, folderName,ACCESS_KEY=access_key, SECRET_KEY=secret_key, TOKEN=token

compile_opt idl2

e = envi(/current)
  
  
  tifFiles = downloadCollect(bucketName, folderName, $
     OUTPUT_DIR=output_dir, ACCESS_KEY=access_key, SECRET_KEY=secret_key, TOKEN=token)
    
  output_path = filepath('', root=output_dir, subdir=strsplit(folderName,'/',/EXTRACT))
  
  ; if no TIF files where found - prompt to select
  if (tifFiles eq !NULL) then begin
     tifFiles = dialog_pickfile(TITLE = 'Select Files to Open In ENVI', $
       PATH=output_path, /MULTIPLE)
     if (tifFiles[0] eq '') then return
  endif 
  
  ; I have files that are either found automatically (TIF) or 
  ; selected - do you want to open these?
  msg = ['Open the following files in ENVI: ', tifFiles]
  ans = dialog_message(msg, /QUESTION)
  
  
  if (ans eq 'Yes') then begin
      ; open them
      OpenFilesInENVI, tifFiles
  endif else begin
      ; try again - this would happen when the user does not like the autoselect
      tifFiles = dialog_pickfile(TITLE = 'Select Files to Open In ENVI', $
         PATH=output_path, /MULTIPLE)
      if (tifFiles[0] ne '') then begin
         OpenFilesInENVI, tifFiles
      endif
  endelse
  
END

PRO OpenFilesInENVI, fileNames


compile_opt idl2

e = envi(/current)

foreach tempFile, fileNames do begin
    print, 'Opening '+tempFile
    rasters = e.openRaster(tempFile, ERROR = sErr)
    if (sErr ne '') then begin
      
      msg = [ 'ERROR opening S3 Item '+tempFile, sErr]
      a = dialog_message(msg)
      
    endif else begin
      ; handle multiple rasters
      foreach r, rasters do begin
        view = e.getView()
        layer = view.createLayer(r, ERROR = serr)
        if (serr ne '') then begin
          msg = ['ERROR creating data layer in ENVI',serr]
          a = dialog_message(msg)
        
        endif
     endforeach
    endelse

  endforeach
  
END

PRO OpenS3InENVI, bucketName, itemName, ACCESS_KEY=access_key, SECRET_KEY=secret_key, TOKEN=token

compile_opt idl2

e = envi(/current)

tempfile = downloadItem(bucketName, itemName, ERROR = errMsg, $
  ACCESS_KEY=access_key, SECRET_KEY=secret_key, TOKEN=token)
if (errMsg[0] eq '') then begin
  OpenFilesInEnvi, tempfile
endif

END


FUNCTION downloadItem, bucketName, itemName, OUTPUT_DIR=output_dir, ERROR=errMsg, $
  ACCESS_KEY=access_key, SECRET_KEY=secret_key,TOKEN=token

compile_opt idl2
errMsg = ''

e = envi(/current)
; if outDir is not specified then default to temp
if (output_dir eq !NULL) then begin 
  outFile = filepath(file_basename(itemName), ROOT=e.preferences["directories and files:temporary directory"].value)
endif else begin
  outFile = filepath(file_basename(itemName), ROOT=output_dir)
endelse

gets3file, bucketName, itemName, outFile, ERROR = errMsg, ACCESS_KEY=access_key, SECRET_KEY=secret_key, TOKEN=token
if (errMsg[0] ne '') then begin
  print, 'Error downloading file'
  outFile = ''
  
endif

return, outFile

END

FUNCTION downloadCollect, bucketName, folderName, OUTPUT_DIR=output_dir, ERROR=errMsg, $
  ACCESS_KEY=access_key, SECRET_KEY=secret_key, TOKEN=token

compile_opt idl2
errMsg=''

e = envi(/current)
; if outDir is not specified then default to temp
if (output_dir eq !NULL) then begin
    output_dir = e.preferences["directories and files:temporary directory"].value
endif

gets3folder, bucketName, folderName, output_dir, ERROR = errMsg, $
  ACCESS_KEY=access_key, SECRET_KEY=secret_key, TOKEN=token
if (errMsg[0] ne '') then begin
  print, 'ERROR getting s3 folder'
  return,''
endif

output_path = filepath('', root=output_dir, subdir = strsplit(folderName,'/', /EXTRACT))
print, output_path
tifFiles = file_search(output_path, '*.tif',/EXPAND_ENVIRONMENT, COUNT=cnt)
if (cnt eq 0) then tifFiles = !NULL

return, tifFiles


END

PRO badS3Message

compile_opt idl2

  sMsg = ['ERROR not a properly formed S3 Address', $
    '   Required format: S3://<bucket_name>/<folder_name>']
  a = dialog_message(sMsg)
  
END

PRO CreateBucketNodes, treeID, bucketNames

compile_opt idl2

foreach bucket, bucketNames do begin
    bucketNode = widget_tree(treeID, /FOLDER, VALUE = bucket, $
      EVENT_PRO='ENVIS3_BucketNode', $
      BITMAP=getBitmap('Storage_AmazonS3_bucketwithobjects', 24), $
      UVALUE={type:'bucket', bucketName:bucket})
      
endforeach

END

FUNCTION ParseS3Address, s3Address

compile_opt idl2

  bParts = s3Address.split('//')
  if (n_elements(bParts) ne 2) then begin
    badS3Message
    return, !NULL
  endif else if (strupcase(bParts[0]) ne 'S3:') then begin
    bads3Message
    return, !NULL
  endif
  bItems = bParts[1].split('/')
  
  bucketName = bItems[0]
  if (n_elementS(bItems) eq 1) then begin
    folderName = ''
  endif else begin
    folderName = bItems[1:*].join('/')
    if (~folderName.endsWith('/')) then folderName+='/'
  endelse
  
  return, {bucketName:bucketName , folderName:folderName}
  
END

PRO ENVIS3_OpenCollect, event

compile_opt idl2

widget_control, event.top, GET_UVALUE = cData
i = cData.contextItemInfo
widget_control, cData.statusText, SET_VALUE = 'Downloading Collect'
OpenS3CollectInENVI, i.bucketName, i.folderName, $
  ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken



END



PRO ENVIS3_Resize, event

compile_opt idl2

widget_control, event.top, GET_UVALUE = cData

gTree = widget_info(cData.s3Tree, /GEOMETRY)
gTopBase = widget_info(cData.topBase, /GEOMETRY)
gTop = widget_info(event.top, /GEOMETRY)
gStatus= widget_info(cData.statusBase, /GEOMETRY)

gSettings = widget_info(cData.settingsBase, /GEOMETRY)
widget_control, cData.settingsBase, XOFFSET = gTop.scr_xsize-(2*gTop.margin)-gSettings.scr_xsize-(2*gsettings.margin)

newX = event.x - (2*gTop.xpad)
newY = event.y - (2*gTop.ypad) - gTopBase.scr_ysize - gStatus.scr_ysize


widget_control, cData.s3Tree, SCR_XSIZE=newX, SCR_YSIZE=newY

END

PRO ENVIs3_Tree, event

compile_opt idl2

widgeT_control, event.top, GET_UVALUe=cdata

if (isa(event,'WIDGET_CONTEXT')) then begin
  widget_control, widget_info(event.id, /TREE_SELECT), GET_UVALUe=i
  cData.contextItemInfo = i
  case i.type of
    'folder':widget_displaycontextmenu, event.id, event.x, event.y, cData.folderContextMenu
    'item':widget_displaycontextmenu, event.id, event.x, event.y, cData.itemContextMenu
    else:
  endcase
  
endif

END

PRO ENVIS3_BucketNode, event

compile_opt idl2

  widget_control, event.top, GET_UVALUE = cData
  widget_control, event.id, GET_UVALUE = i
  
  
  if (event.type eq 0) then begin
    if (event.clicks eq 2) then begin
      
       if (widget_info(event.id, /CHILD) ne 0) then return
       
       s3address = 'S3://'+i.bucketName
  
       s3info = parses3address(s3address)
       if (s3info eq !NULL) then return
       
       folderNames = gets3FolderList(s3Info.bucketName, s3Info.folderName, ERROR=errMsg, $
        ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken)
      
       if (folderNames ne !NULL) then begin
        foreach folder, folderNames do begin
          node = widget_tree(event.id, VALUE = folder, /FOLDER,  $
             UVALUE = {bucketName:s3info.bucketName, folderName:folder}, $
             EVENT_PRO='ENVIS3_FolderNode')

        endforeach
        widget_control, event.id, /SET_TREE_EXPANDED
       endif else begin
        widget_control, cData.statusText, SET_VALUE='Error getting folders'
       endelse
       
     ENDIF
   ENDIF
   
END

PRO ENVIS3_ItemPreviewText, event

compile_opt idl2

  widget_control, event.top, GET_UVALUE = cData

  i= cData.contextItemInfo
  print, 'Previewing Item '+i.itemName
  txtFile = downloadItem(i.bucketName, i.itemName, ERROR=errMsg,$
     ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken)
  if (errMsg[0] eq '') then begin
    xdisplayfile, txtFile
  endif else begin
    a = dialog_message('ERROR downloading item for preview')
  endelse

END


PRO ENVIS3_ItemPreviewImage, event

compile_opt idl2

  widget_control, event.top, GET_UVALUE = cData
  
  i= cData.contextItemInfo
  print, 'Previewing Item '+i.itemName
  img = downloadItem(i.bucketName, i.itemName, ERROR = errMsg, $
    ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken)
  if (errMsg[0] eq '') then begin
    i = image(img, TITLE=file_basename(i.itemName), $
        WINDOW_TITLE=file_basename(i.itemName))
  endif
  
  
END


PRO ENVIS3_CollectDownload, event

compile_opt idl2

  widget_control, event.top, GET_UVALUE = cData

  i= cData.contextItemInfo
  outDir = dialog_pickfile(TITLE = 'Select Output Root Directory', /DIR)
  if (outDir eq '') then return

  widget_control, cData.statusText, SET_VALUE='Downloading Collect...'
  outfile = downloadCollect(i.bucketName, i.folderName, OUTPUT_DIR=outDir, ERROR=errMsg, $
    ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken)
  if (errMsg[0] eq '') then begin
    widget_control, cData.statusText, SET_VALUE='Download Complete'
  
    a = dialog_message('Download Complete')
    widget_control, cData.statusText, SET_VALUE='Ready'
  endif else begin
    widget_control, cData.statusText, SET_VALUE = 'Download error'
  endelse
  

END


PRO ENVIS3_ItemDownload, event

compile_opt idl2

  widget_control, event.top, GET_UVALUE = cData
  
  i= cData.contextItemInfo
  outDir = dialog_pickfile(TITLE = 'Select Output Root Directory', /DIR)
  if (outDir eq '') then return
  
  outfile = downloadItem(i.bucketName, i.itemName, OUTPUT_DIR=outDir, ERROR=errMsg, $
    ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken)
  if (errMsg[0] eq '') then begin
    a = dialog_message('Download Complete')
  endif else begin
    a = dialog_message('Error downloading Item')
  endelse
  
END

PRO ENVIS3_ItemOpen, event

compile_opt idl2

  widget_control, event.top, GET_UVALUE = cData
  i= cData.contextItemInfo
  print, 'Opening Item '+i.itemName+' in ENVI'
  Opens3InENVI, i.bucketName, i.itemName, ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken

END


PRO ENVIS3_ItemNode, event

compile_opt idl2

  widget_control, event.top, GET_UVALUE = cData
  widget_control, event.id, GET_UVALUE = i

  if (isa(event,'WIDGET_CONTEXT')) then begin
    
    cData.contextItemInfo = i
    widget_displaycontextmenu, event.id, event.x, event.y, cData.itemContextMenu
    
  endif else begin
    if (event.clicks eq 2) then begin
      widget_control, cData.statusText, SET_VALUE='Getting Data and Opening in ENVI'
      Opens3InENVI, i.bucketName, i.itemName, $
        ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken
      widget_control, cData.statusText, SET_VALUE='Ready'
     endif
  endelse
END

PRO ENVIS3_FolderNode, event

compile_opt idl2

widget_control, event.top, GET_UVALUE = cData
widget_control, event.id, GET_UVALUE = i


if (isa(event,'WIDGET_CONTEXT')) then begin
  
  cData.itemContextInfo = i
  widget_displaycontextmenu, event.id, event.x, event.y, cData.folderContextMenu

endif else begin
  if (event.type eq 0) then begin
    if (event.clicks eq 2) then begin
      
      if (widget_info(event.id, /CHILD) ne 0) then return
      
      ; build the folders first
  
      folderNames = gets3FolderList(i.bucketName, i.folderName, $
         ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, $
         TOKEN=cData.awsToken)
         
      if (folderNames ne !NULL) then begin
  
        nFolders = n_elements(folderNames)
        foreach folder, folderNames, idx do begin
          widget_control, cData.statusText, SET_VALUE='Creating Folder Node ('+strtrim(idx+1,2)+'/'+strtrim(nFolders,2)+')'
          node = widget_tree(event.id, VALUE = file_basename(folder), $
            UVALUE = {type:'folder', bucketName:i.bucketName, folderName:folder, generated:!FALSE}, $
            EVENT_PRO='ENVIS3_FolderNode', $
           ; BITMAP=getBitmap('Storage_AmazonS3_bucketwithobjects'), $
            /FOLDER)
        endforeach
      endif else begin
        widget_control, cData.statusText, SET_VALUE='Error getting folders'
      endelse
  

      fileList = getS3Filelist(i.bucketName, i.folderName, $
          ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken)
      if (fileList ne !NULL) then begin
        foreach file, fileList do begin
          node = widget_tree(event.id, VALUE = file_basename(file), $
            UVALUE = {type:'item',bucketName:i.bucketName, itemName:file}, $\
            BITMAP=getBitmap('Storage_AmazonS3_object', 12), $
            EVENT_PRO='ENVIS3_ItemNode')
        endforeach
      endif
    
      widget_control, event.id, /SET_TREE_EXPANDED
      widget_control, cData.statusText, SET_VALUE='Ready'
    ENDIF  
  ENDIF
  
ENDELSE

END

PRO ENVIS3_Settings, event
widget_control, event.top, GET_UVALUE=cData

ENVIS3_SettingsUI, cData, GROUP_LEADER=event.top

END

PRO ENVIS3_Address, event

compile_opt idl2

widget_control, event.top, GET_UVALUE=cData
widget_control, cData.s3AddressText, GET_VALUE = tmp

widget_control, cData.statusText, SET_VALUE='Opening External S3 bucket '+tmp[0]

s3address = strtrim(tmp[0],2)
s3info = parses3address(s3address)
if (s3info eq !NULL) then return

folderNames = gets3FolderList(s3Info.bucketName, s3Info.folderName, ERROR=errorMsg, $
  ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken)
  
  
if (folderNames ne !NULL) then begin
  
  bucketID = widget_tree(cData.externalTreeNode, VALUE=s3Info.bucketName, $
    BITMAP=getBitmap('Storage_AmazonS3_bucketwithobjects', 24), $
    /FOLDER)
  
  nFolders = n_elements(folderNames)
  foreach folder, folderNames, idx do begin
    widget_control, cData.statusText, SET_VALUE='Creating Folder Node ('+strtrim(idx+1,2)+'/'+strtrim(nFolders,2)+')'
    
    node = widget_tree(bucketID, VALUE = folder, /FOLDER,  $
      UVALUE = {type:'folder',bucketName:s3info.bucketName, folderName:folder}, $
      
      EVENT_PRO='ENVIS3_FolderNode')
    
  endforeach
  widget_control, cData.mainTreeNode, SET_TREE_EXPANDED=0
  widget_control, cData.externalTreeNode, SET_TREE_EXPANDED=1
  widget_control, cData.statusText, SET_VALUE='Ready'
  
ENDIF else begin
   widget_control, cData.statusText, SET_VALUE='Error getting folders'
Endelse

END

PRO ENVIS3_Refresh, event

  compile_opt idl2
  
  widget_control, event.top, GET_UVALUe=cData
  
  ; Rebuild the tree
  widget_control, cData.mainTreeNode, /DESTROY
  widget_control, cData.externalTreeNode, /DESTROY
  
  cData.mainTreeNode = widget_tree(cData.s3Tree, VALUE='Amazon S3 User Account', $
    BITMAP=getBitmap('Storage_AmazonS3', 32), /FOLDER)
  cData.externalTreeNode = widget_tree(cData.s3Tree, VALUE='Amazon S3 External Accounts',$
    BITMAP=getBitmap('Storage_AmazonS3', 32), /FOLDER)

  widget_control, event.top, GET_UVALUE=cData
  bucketNames = getBucketNames(ACCESS_KEY=cData.awsAccess, SECRET_KEY=cData.awsSecret, TOKEN=cData.awsToken)
  if (bucketNames eq !NULL) then begin
    msg = dialog_message('No Available S3 buckets')
    return
  endif


  CreateBucketNodes, cData.mainTreeNode, bucketNames
  widget_control, cData.mainTreeNode, /SET_TREE_EXPANDED

END

PRO ENVIS3Explorer

compile_opt idl2 

;if (~goodAwsEnvironmentVars()) then begin
;   msg = ['Must Set AWS Environment Variables', $
;          'AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY', $
;          'Must be set to valid AWS Keys']
;          
;   msg = dialog_message(msg)
;   return
;   
;endif


e = envi(/current)
if (e eq !NULL) then e = envi()

tlb = widget_base(TITLE = 'ENVI S3 Explorer', /COLUMN, /TLB_SIZE_EVENTS)
topBase = widget_base(tlb, /ROW)
s3AddressLabel = widget_label(topBase, VALUE = 'Additional S3 Location: ')
s3AddressText = widget_text(topBase, /EDITABLE, XSIZE=50, YSIZE=1, VALUE='S3://', $
  EVENT_PRO = 'ENVIS3_Address')
refreshButton = widget_button(topBase, VALUE = getBitmap('refresh',16), EVENT_PRO='ENVIS3_Refresh')
  
treeBase = widget_base(tlb, /COLUMN)
s3Tree = widget_tree(treeBase, EVENT_PRO='ENVIS3_Tree', $
  SCR_XSIZE=450, SCR_YSIZE=600, /CONTEXT_EVENTS)
mainTreeNode = widget_tree(s3Tree, VALUE='Amazon S3 User Account', $
  BITMAP=getBitmap('Storage_AmazonS3', 32), /FOLDER)
externalTreeNode = widget_tree(s3Tree, VALUE='Amazon S3 External Accounts',$ 
  BITMAP=getBitmap('Storage_AmazonS3', 32), /FOLDER) 

statusBase = widget_base(tlb)
statusText = widget_label(statusBase, VALUE = 'Ready', /DYNAMIC_RESIZE)
settingsBase = widget_base(statusBase, /BASE_ALIGN_RIGHT, /ALIGN_RIGHT)
credentialsButton = widget_button(settingsBase, VALUE=filepath('gears.bmp', subdir=['resource','bitmaps']), $
  /BITMAP, EVENT_PRO='ENVIS3_Settings', /FLAT, /ALIGN_RIGHT)
gC = widget_info(settingsBase, /GEOM)
gTop = widget_info(tlb, /GEOM)
widget_control, settingsBase, XOFFSET=gTop.scr_xsize-(2*gTop.margin)-gC.scr_xsize-(2*gC.margin)

; context menus
folderContextMenu = widget_base(tlb, /CONTEXT_MENU)
openCollect = widget_button(folderContextMenu, VALUE='Open As Collect', EVENT_PRO='ENVIS3_OpenCollect')
downloadCollect = widget_button(folderContextMenu, VALUE='Download Collect', EVENT_PRO='ENVIS3_CollectDownload')

itemContextMenu = widget_base(tlb, /CONTEXT_MENU)
openItem = widget_button(itemContextMenu, VALUE='Open Item in ENVI', EVENT_PRO='ENVIS3_ItemOpen')
downloadItem = widget_button(itemContextMenu, VALUE='Download Item', EVENT_PRO='ENVIS3_ItemDownload')
previewItem = widget_button(itemContextMenu, VALUE='Preview Item as Image', EVENT_PRO='ENVIS3_ItemPreviewImage')
previewItem = widget_button(itemContextMenu, VALUE='Preview Item as Text', EVENT_PRO='ENVIS3_ItemPreviewText')

;actionBase = widget_base(tlb, /ROW, /FRAME)
widget_control, tlb, /REALIZE




cData = DICTIONARY()
cData.s3AddressText = s3AddressText
cData.s3Tree = s3Tree
cData.topBase = topBase
cData.mainTreeNode = mainTreeNode
cData.externalTreeNode = externalTreeNode
cData.itemContextMenu = itemContextMenu
cData.folderContextMenu = folderContextMenu
cData.contextItemInfo = !NULL
cData.statusText = statusText
cData.statusBase = statusBase
cData.settingsBase = settingsBase
cData.useEnv=!TRUE
cData.awsAccess=aKey
Cdata.awsSecret=sKey
cData.awsToken=''

widget_control, tlb, SET_UVALUE = cData

goodToCreateBuckets=!TRUE
aKey = getenv('AWS_ACCESS_KEY_ID')
if (aKey eq !NULL OR aKey eq '') then begin
  a = dialog_message('Must set AWS_ACCESS_KEY_ID environment variable')
  goodToCreateBuckets=!FALSE
endif

sKey = getenv('AWS_SECRET_ACCESS_KEY')
if (sKey eq !NULL OR sKey eq '') then begin
  a = dialog_message('Must set AWS_SECRET_ACCESS_KEY environment variable')
  goodToCreateBuckets=!FALSE
endif

if (goodToCreateBuckets) then begin

  bucketNames = getBucketNames(ACCESS_KEY=aKey, SECRET_KEY=sKey)
  if (bucketNames eq !NULL) then begin
    msg = dialog_message('No Available S3 buckets')
    return
  endif


  CreateBucketNodes, mainTreeNode, bucketNames
  widget_control, mainTreeNode, /SET_TREE_EXPANDED
endif else begin
  ENVIS3_SettingsUI, cData, GROUP_LEADER = tlb
endelse


Xmanager, 'ENVIS3Explorer', tlb, /NO_BLOCK, EVENT_HANDLER='ENVIS3_Resize'

END