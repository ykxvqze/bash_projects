#!/usr/bin/python3
'''
Delete docx (Word) file metadata

Usage:  ./del_metadata.py -m file1.docx file2.docx file3.docx ... fileN.docx

ARGS:
        -m: mask option; if specified, timestamps in comments will be modified (with randomization), else erased 
        filenames (with docx): Word documents of form [file_basename].docx

OUTPUT:

        files ([file_basename]_cleared.docx) with metadata removed, in current directory

DESCRIPTION:

Deletes metadata (author name and date timestamps) from docx (Word) 
document, which is basically a zip file of xml documents. 
The script modifies document.xml and comments.xml (if latter is present). 
If mask option is unspecified, metadata in the output file will appear 
empty (no author), (no date), including comments in the margin which 
will have no author and no timestamps. If mask option is specified, then 
timestamps in the comments will be changed through randomization: the first
will be the current OS datetime, and remaining comments will be assigned 
timestamps with an incremental component drawn from a uniform distribution
so that consecutive comments appear as if anywhere between 1 to 2 minutes apart.

J.A., xrzfyvqk_k1jw@pm.me
'''

import sys, os, zipfile, re, shutil, datetime
import numpy as np
import pandas as pd

offset=1  if (sys.argv[1]=='-m')  else  0

for ind, file_path in enumerate(sys.argv[offset+1:]):

    file_path = shutil.copy(file_path, file_path.replace('.docx','.zip'))
    directory_path, base_name = os.path.split(file_path)
    root, ext = os.path.splitext(base_name)
    new_name = f'{root}_cleared{ext}' 
    out_path = os.path.join(directory_path, new_name)
    zin = zipfile.ZipFile(file_path, 'r')
    zout = zipfile.ZipFile(out_path, 'w')

    #clear 'document.xml' from author and timestamps
    boolean_list = [item.filename.endswith('document.xml') for item in zin.infolist()]
    ind_doc = boolean_list.index(True)
    data = zin.read(zin.infolist()[ind_doc].filename)
    data = re.sub(b'w:author="(.*?)"', b'w:author=""', data) 
    data = re.sub(b'w:date="(.*?)"', b'w:date=""', data) 
    zout.writestr(zin.infolist()[ind_doc], data) 

    #clear 'comments.xml' if it exists
    boolean_list = [item.filename.endswith('comments.xml') for item in zin.infolist()]
    ind_comments = []

    if (sum(boolean_list)!=0):
        ind_comments = boolean_list.index(True)
        data = zin.read(zin.infolist()[ind_comments].filename)
        data = re.sub(b'w:author="(.*?)"', b'w:author=""', data)

        if (offset==1):
            n_dates = len(re.findall(b'w:date=', data)) 
            time_now = datetime.datetime.now()
            seconds = np.random.uniform(low=60, high=120, size=n_dates)  # 1-2 minutes apart
            new_times = [time_now + datetime.timedelta(seconds = i) for i in seconds.cumsum()]
            q = pd.to_datetime(new_times).strftime("%Y-%m-%d %H:%M:%S")
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
