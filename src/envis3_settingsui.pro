PRO ENVIS3_SettingsUI_Event, event

; catch text events only 

END


PRO ENVIS3_SettingsUI_Done, event

widget_control, event.top, GET_UVALUE = cdata
if (not cdata.mainData.useEnv) then begin
  widget_control, cData.accessKeyText, GET_VALUE=accessKey
  cData.mainData.awsAccess = strtrim(accessKey[0],2)
  widget_control, cData.secretKeyText, GET_VALUE=secretKey
  cData.mainData.awsSecret = strtrim(secretKey[0],2)
endif

widget_control, event.top, /DESTROY
END

PRO ENVIS3_SettingsUI_Cancel, event
widget_control, event.top, /DESTROY
END

PRO ENVIS3_SettingsUI_UseEnv, event
  
  widget_control, event.top, GET_UVALUE = cData
  widget_control, cData.settingsBase, SENSITIVE = event.select ? 0 : 1
  cData.mainData.useEnv=event.select ? !TRUE : !FALSE
  if (event.select) then begin
    aKey = getenv('AWS_ACCESS_KEY_ID')
    if (aKey eq !NULL OR aKey eq '') then begin
      a = dialog_message('Must set AWS_ACCESS_KEY_ID environment variable')      
    endif else begin
      cData.mainData.awsAccess = aKey
    endelse

    sKey = getenv('AWS_SECRET_ACCESS_KEY')
    if (sKey eq !NULL OR sKey eq '') then begin
      a = dialog_message('Must set AWS_SECRET_ACCESS_KEY environment variable')      
    endif else begin
      cData.mainData.awsSecret = sKey
    endelse
  endif
  
  
END

PRO ENVIS3_SettingsUI_AssumeRole, event
widget_control, event.top, GET_UVALUE = cData
widget_control, cData.arnText, GET_VALUE = arn
if (arn[0] eq '') then begin
  a = dialog_message('ERROR must supply a valid Role ARN')
  return
endif else arn = strtrim(arn[0],2)

widget_control, cData.snameText, GET_VALUE = sname
if (sname[0] eq '') then begin
  a = dialog_message('ERROR must supply a valid Role Session Name')
  return
endif else sname = strtrim(sname[0],2)
print, arn
print, sname
cso = loadpythonlib('cso_s3utils')
cred = cso.getCredentials(arn, sname)
cData.mainData.awsAccess = cred.access_key
cData.mainData.awsSecret = cred.secret_key
cData.mainData.awsToken = cred.session_token
widget_control, cData.accessKeyText, SET_VALUE = cred.access_key
widget_control, cData.secretKeyText, SET_VALUE = cred.secret_key
widget_control, cData.tokenText, SET_VALUE = cred.session_token



END


PRO ENVIS3_SettingsUI, mainData, GROUP_LEADER=gl

  ;cData.useEnv=!TRUE
  ;cData.awsAccess=''
  ;Cdata.awsSecret=''
  
tlb = widget_base(TITLE = 'AWS Settings', /MODAL, GROUP_LEADER=gl, /COLUMN, TLB_FRAME_ATTR=10)
row1 = widget_base(tlb, /NONEXCLUSIVE, /ROW)
useAwsEnvButton = widget_button(row1, VALUE = 'Use AWS Environment Variables', EVENT_PRO='ENVIS3_SettingsUI_UseEnv')
settingsBase = widget_base(tlb, /COLUMN)

settingsFrameRow = widget_base(settingsBase, /COLUMN, /FRAME)
assumeRoleLabel = widget_label(settingsFrameRow, /ALIGN_CENTER, VALUE = 'Assume Role')
settingsRow1 = widget_base(settingsFrameRow, /ROW)
arnLabel = widget_label(settingsRow1, VALUE='ARN: ')
arnText = widget_text(settingsRow1, XSIZE=60, YSIZE=1, /EDITABLE)
settingsRow1a = widget_base(settingsFrameRow, /ROW)
snameLabel = widget_label(settingsRow1a, VALUE='Session Name: ')
snameText = widget_text(settingsRow1a, XSIZE=20, YSIZE=1, /EDITABLE)
settingsRow1b = widget_base(settingsFrameRow, /ROW)
assumeRoleButton = widget_button(settingsRow1b, /ALIGN_CENTER, VALUe = 'Assume Role', EVENT_PRO='ENVIS3_SettingsUI_AssumeRole')

settingsRow2 = widget_base(settingsBase, /ROW)
accessKeyLabel = widget_label(settingsRow2, VALUE = 'AWS Access Key: ')
accessKeyText = widget_text(settingsRow2, XSIZE=60, YSIZE=1, /EDITABLE, VALUE=mainData.awsAccess)
settingsRow3 = widget_base(settingsBase, /ROW)
secretKeyLabel = widget_label(settingsRow3, VALUE = 'AWS Secret Key: ')
secretKeyText = widget_text(settingsRow3, XSIZE=60, YSIZE=1, /EDITABLE, VALUE=mainData.awsSecret)
settingsRow4 = widget_base(settingsBase, /ROW)
tokenLabel = widget_label(settingsRow4, VALUE = 'Security Token: ')
tokenText = widget_text(settingsRow4, XSIZE=60, YSIZE=1, /EDITABLE, VALUE=mainData.awsToken)

bottomRow = widget_base(tlb, /ROW, /BASE_ALIGN_CENTER)
closeButton = widget_button(bottomRow, VALUE = 'Done', EVENT_PRO='ENVIS3_SettingsUI_Done')
closeButton = widget_button(bottomRow, VALUE = 'Cancel', EVENT_PRO='ENVIS3_SettingsUI_Cancel')
 
widget_control, tlb, /REALIZE

cData = Dictionary()
cData.accessKeyText = accessKeyText
cData.secretKeyText = secretKeyText
cData.tokenText = tokenText
cData.arnText = arnText
cData.snameText = snameText
cData.maindata = maindata
Cdata.settingsbase = settingsbase

widget_control, tlb, SET_UVALUE = cData

widget_control, useAwsEnvButton, SET_BUTTON=mainData.useEnv ? 1 : 0
widget_control, settingsBase, SENSITIVE=mainData.useEnv ? 0 : 1

Xmanager, 'ENVIS3_SettingsUI', tlb

END