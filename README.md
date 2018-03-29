# ENVI_S3
ENVI plugin to explore AWS S3 buckets and open contents in ENVI 5.x

## Capabilities
- Displays AWS S3 buckets that are accessible via account credentials
- Allows access to public S3 buckets such as the Landsat public dataset (s3://landsat-pds)
- Open any single image file that is supported by ENVI 
- Open a "collect" into ENVI
- Preview small image files 
- Preview text files
- Download collects or single images

![Alt text](https://github.com/blegeer/ENVI_S3/blob/master/screenshots/ENVIS3ExplorerScreenshot.png "Explorer Screenshot")

## Ideal Install
This plugin will works best when run on an AWS EC2 instance in the same region as the buckets being searched. Browsing collects will work fine on non-AWS instances. Downloading large datasets when not on an AWS EC2 instance is slower and could incur costs to your account.  

## Requirements
- ENVI 5.3.1 (tested) not testing on ENVI 5.4 or 5.5
- A working IDL->Python bridge - see the Harris Geospatial Documentation for instructions (http://www.harrisgeospatial.com/docs/Python.html)
- Python 2.7
- boto and boto3 modules
- An AWS account with a key/pair

## Installation
1. be sure that python 2.7 is installed with boto and boto3

  c:\> python --version
  
  -or-
  
  /home/ec2-user$ python --version
  
 python
 
 ```python
 import boto
 import boto3
 ```
 
   if either import fails, install using pip
   ```
   pip install boto
   pip install boto3
   ```
   
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
      bitmaps
      python_lib
      save
      
5. Restart ENVI
6. Click on the ENVI AWS Explorer tool in extensions

## Build from source
To build from source. 
1. Start IDL 
2. edit the file locations in src\buildsave.pro
3. execute the IDL commands
```python
cd, 'c:\<yourdir>\envi_s3\src'
@buildsave
```

This will create the IDL save file in envi_s3\src and the zip file at the envi_s3 root location




   


