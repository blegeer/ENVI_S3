# ENVI_S3
ENVI plugin to explore AWS S3 buckets and open contents in ENVI 5.x

Displays AWS S3 buckets that are accessible via account credentials

## Requirements
ENVI 5.3.1 (tested) not testing on ENVI 5.4 or 5.5
Python 2.7
boto and boto3 modules

## Installation
1. be sure that python 2.7 is installed with boto and boto3

  c:\> python --version
  
  -or-
  
  /home/ec2-user$ python --version
  
 python
 >>> import boto
 >>> import boto3
 
   if either import fails, install using pip
   pip install boto
   pip install boto3

2. Set your AWS envirnonment variables to the values specific for your account

AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY

These keys determine the buckets that you can access

3. Extract the envis3explorer.zip to your ENVI extensions directory
   Windows 
   c:\users\<your_id>\.idl\envi\extensions5_3
   
   Linux (AWS)
   /home/ec2-user/.idl/envi/extensions5_3
   
4. Verify the extensions directory has a new folder named envi_s3 with three subfolders
    envi_s3
      |
      - bitmaps
      - python_lib
      - save
      
5. Restart ENVI
6. Click on the ENVI AWS Explorer tool in extensions



   


