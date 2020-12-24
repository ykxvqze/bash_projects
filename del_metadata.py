#!/usr/bin/python3
'''
Delete docx (Word) file metadata

Usage: python3 del_metadata.py -m [file_basename].docx

ARGS:
		-m: mask option; if specified, timestamps in comments will be faked (with randomization), else erased. 
		filename (with docx): Word document , i.e. [file_basename].docx 

OUTPUT:   
       
		file ([file_basename]_cleared.docx) with metadata removed

DESCRIPTION:

Deletes metadata (author name and date timestamps) from docx (Word) 
document, which is basically a zip file of xml documents. 
The script modifies document.xml and comments.xml (if present). 
If mask option is unspecified, metadata in the output file will appear 
empty (Unknown Author), (no date), including comments in the margin which 
will have no author and no timestamps. If mask option is specified, then 
timestamps in the comments will be faked through randomization: the first
will be the current OS datetime, and remaining comments will be assigned 
timestamps with an incremental component drawn from a uniform distribution
so that consecutive comments appear as if anywhere between 1 to 2 minutes apart.      

J.A., xvnyjlq@yandex.com
'''

import sys, os, zipfile, re, shutil, datetime
import numpy as np
import pandas as pd

mask = sys.argv[1]       #sys.argv[0]: script filename
file_path = sys.argv[-1] #last arg

file_path = shutil.copy(file_path, file_path.replace('.docx','.zip')) #copy file and rename extension
directory_path, base_name = os.path.split(file_path)
root, ext = os.path.splitext(base_name)
new_name = f'{root}_cleared{ext}' 
out_path = os.path.join(directory_path, new_name)
zin = zipfile.ZipFile(file_path, 'r')
zout = zipfile.ZipFile(out_path, 'w')

#clear 'document.xml' from author and date keys
boolean_list = [item.filename.endswith('document.xml') for item in zin.infolist()]
ind_doc = boolean_list.index(True)
data = zin.read(zin.infolist()[ind_doc].filename)
data = re.sub(b'w:author="(.*?)"', b'w:author="Unknown Author"', data) 
data = re.sub(b'w:date="(.*?)"', b'w:date=""', data) 
zout.writestr(zin.infolist()[ind_doc], data) 

#clear 'comments.xml' if it exists
boolean_list = [item.filename.endswith('comments.xml') for item in zin.infolist()]
ind_comments = []

if (sum(boolean_list)!=0):

	ind_comments = boolean_list.index(True)
	data = zin.read(zin.infolist()[ind_comments].filename)
	data = re.sub(b'w:author="(.*?)"', b'w:author="Unknown Author"', data)

	if (mask=='-m'):
		n_dates = len(re.findall(b'w:date=', data)) 
		time_now = datetime.datetime.now()
		seconds = np.random.uniform(low=60, high=120, size=n_dates) #1-2 min per comment
		new_times = [time_now + datetime.timedelta(seconds = i) for i in seconds.cumsum()]
		q = pd.to_datetime(new_times).strftime("%Y-%m-%d %H:%M:%S") #this is the format used in xml (with dashes)
		current_dates = re.findall(b'w:date="(.*?)"', data) 
		for i in range(n_dates):
			t = q[i].replace(' ','T') + 'Z'  
			data = re.sub(current_dates[i], bytes(f'{t}','utf-8'), data) 
	else:
		data = re.sub(b'w:date="(.*?)"', b'w:date=""', data) 

	zout.writestr(zin.infolist()[boolean_list.index(True)], data)

[zout.writestr(item, zin.read(item.filename)) for i, item in enumerate(zin.infolist()) if i not in [ind_doc, ind_comments]]

zout.close()
zin.close()

file_cleared = shutil.copy(out_path, out_path.replace('.zip','.docx')) 

#delete intermediate zip files
os.remove(file_path) 
os.remove(out_path)
