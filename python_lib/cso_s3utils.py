# CSO_S3Utils
#

from boto.s3.connection import S3Connection
import boto.s3.connection
from boto.s3.key import Key
from boto.sts import STSConnection

import boto3

import os
import fnmatch
import sys
import math


def getCredentials(arn, sname):

    conn = STSConnection()
    c = conn.assume_role(arn, sname)
    return(c.credentials)

def uploadFile(local_file, bucketName, folder,
               accesskey=None,
               secretkey=None,
               token=None,
               region=None):

    if (region == None):
        region='us-east-1'
        
    try:
        conn = boto.s3.connect_to_region(region,
            aws_access_key_id = accesskey,
            aws_secret_access_key = secretkey,
    
            # host = 's3-website-us-east-1.amazonaws.com',
            # is_secure=True,               # uncomment if you are not using ssl
            calling_format = boto.s3.connection.OrdinaryCallingFormat()
            )

        bucket = conn.get_bucket(bucketName)
        key_name = os.path.basename(local_file)
        path = folder #Directory Under which file should get upload
        full_key_name = path + "/" +key_name
        k = bucket.new_key(full_key_name)
        k.set_contents_from_filename(local_file)

    except Exception,e:
        print str(e)
        print "error"

def percent_cb(complete, total):
    sys.stdout.write('.')
    sys.stdout.flush()


def uploadFileBoto3(local_file, bucketName, key_name,
                    accesskey=None, secretkey=None):
    import boto3

    session = boto3.Session(aws_access_key_id=accessKey,
                            aws_secret_access_key=secretkey)
    
    s3_client = session.client( 's3' )

    try:
        print "Uploading file:", local_file

        tc = boto3.s3.transfer.TransferConfig()
        t = boto3.s3.transfer.S3Transfer( client=s3_client, 
                                         config=tc )

        t.upload_file( local_file, bucketName, key_name )

    except Exception as e:
        print "Error uploading: %s" % ( e )
        

def uploadFileMP(local_file, bucketName, key_name, accesskey=None, secretkey=None):

    conn = boto.connect_s3(accesskey, secretkey)
    bucket=conn.get_bucket(bucketName)
    
    #max size in bytes before uploading in parts. between 1 and 5 GB recommended
    MAX_SIZE = 60 * 1e6
    #size of parts when uploading in parts
    PART_SIZE = 1000 * 1024 * 1024

    source_size = os.stat(local_file).st_size
   
    
    if source_size > MAX_SIZE:
        print "mulitpart upload"
        mp = bucket.initiate_multipart_upload(key_name)
        
        bytes_per_chunk = 5000*1024*1024
        chunks_count = int(math.ceil(source_size / float(bytes_per_chunk)))

        for i in range(chunks_count):
                offset = i * bytes_per_chunk
                remaining_bytes = source_size - offset
                bytes = min([bytes_per_chunk, remaining_bytes])
                part_num = i + 1

                print "uploading part " + str(part_num) + " of " + str(chunks_count)

                with open(local_file, 'r') as fp:
                        fp.seek(offset)
                        mp.upload_part_from_file(fp=fp, part_num=part_num, size=bytes)

        if len(mp.get_all_parts()) == chunks_count:
                mp.complete_upload()
                print "upload_file done"
        else:
                mp.cancel_upload()
                print "upload_file failed"

    else:
        print "singlepart upload"
        k = boto.s3.key.Key(bucket)
        k.key = key_name
        k.set_contents_from_filename(local_file,cb=percent_cb, num_cb=10)
            

def getS3FolderList(bucketName, folder,
                    accesskey=None,
                    secretkey=None,
                    token=None,
                    match=None):

# folder must be in the form
# key1/key2/
# must have the leading slash and must be fully qualified

    folderList = []
        
    conn = S3Connection(aws_access_key_id=accesskey,
                        aws_secret_access_key=secretkey,
                        security_token=token)
    
    bucket = conn.get_bucket(bucketName)
    nObj = 0
    for key in bucket.list(prefix=folder, delimiter='/'):
        nObj = nObj+1
        keyName = key.name.encode('utf-8')
        if (keyName.endswith('/')):
            if (keyName != folder):
                if (match == None):
                    folderList.append(keyName)
                else:
                    if (fnmatch.fnmatch(keyName,match)):
                        folderList.append(keyName)
                        #k=bucket.get_key(key.name)
                        #print k.last_modified
        

        

    # print "Number of Objects in "+bucketName+": "+str(nObj)
    return(folderList)

def getS3FileList(bucketName, folder,
                  accesskey=None,
                  secretkey=None,
                  token=None,
                  match=None):

# folder must be in the form
# dir1/dir2/
# must have the leading slash and must be fully qualified

    fileList = []
    
    conn = S3Connection(aws_access_key_id=accesskey,
                        aws_secret_access_key=secretkey,
                        security_token=token)
     
    bucket = conn.get_bucket(bucketName)
    nObj = 0
    for key in bucket.list(prefix=folder, delimiter='/'):
        nObj = nObj+1
        keyName = key.name.encode('utf-8')
        if (not keyName.endswith('/')):
            if (keyName != folder):
                if (match == None):
                    fileList.append(keyName)
                else:
                    if (fnmatch.fnmatch(keyName,match)):
                        fileList.append(keyName)
        

    # print "Number of Objects in "+bucketName+": "+str(nObj)
    return(fileList)


def getKeyToFile(bucketName, keyName, fileName,
                 accesskey=None,
                 secretkey=None,
                 token=None):
    
    
    conn = S3Connection(aws_access_key_id=accesskey,
                        aws_secret_access_key=secretkey,
                        security_token=token)
     
    bucket = conn.get_bucket(bucketName)
    key = bucket.get_key(keyName)
    key.get_contents_to_filename(fileName)

def getS3Folder(bucketName, folderName, rootDir,
                accesskey=None,
                secretkey=None,
                token=None ):

     
    # connect to the bucket
    conn = boto.connect_s3(aws_access_key_id=accesskey,
                        aws_secret_access_key=secretkey,
                        security_token=token)
    bucket = conn.get_bucket(bucketName)

    nfiles=0
    ndir=0
    
    # go through the list of files
    bucket_list = bucket.list(prefix=folderName)
    for l in bucket_list:
        keyString = l.name.encode('utf-8')
        d = os.path.abspath(rootDir+os.sep+keyString)

        mkDirUntilDone(d, keyIsFolder(keyString))
        
        if (keyIsFolder(keyString)):
            ndir=ndir+1                        
        else:
            if (not os.path.isfile(d)):
                l.get_contents_to_filename(d)
            nfiles=nfiles+1
            

def getBucketNames(accesskey=None,
                   secretkey=None,
                   token=None):
   
    s3 = boto.connect_s3(aws_access_key_id=accesskey,
                        aws_secret_access_key=secretkey,
                        security_token=token)  
    buckets = s3.get_all_buckets()
    bucketList=[]
    for key in buckets:
        bucketList.append(key.name)
    return(bucketList)
  
   
def keyIsFolder(key):

    if (key.endswith("/")):
        return True
    else:
        return False
        
def mkDirUntilDone(path,isDir):


    if (isDir):
        p=path
    else:
        p = os.path.dirname(path)

    dirList = []
        
    while not os.path.isdir(p):
        dirList.append(p)
        p = os.path.dirname(p)

    for m in reversed(dirList):
        os.mkdir(m)

def role_arn_to_session(**args):
    """
    Usage :
        session = role_arn_to_session(
            RoleArn='arn:aws:iam::012345678901:role/example-role',
            RoleSessionName='ExampleSessionName')
        client = session.client('sqs')
    """
    client = boto3.client('sts')
    response = client.assume_role(**args)
    return boto3.Session(
        aws_access_key_id=response['Credentials']['AccessKeyId'],
        aws_secret_access_key=response['Credentials']['SecretAccessKey'],
        aws_session_token=response['Credentials']['SessionToken'])
 
    
    
