import scipy
import pandas as pd
import numpy as np
import os, sys
import math
from scipy.integrate import quad


#body condition functions

#BODY VOLUME
def body_vol(df_all,tl_name,interval,lower,upper,vname):
    body_name = "BV_{0}".format(vname) #name of body volume column will use interval amount
    volm = [] #make empty list of widths
    for x in range(lower,(upper + interval), interval): #loop through range of widths
        xx = "{0}-{1}.00%".format(tl_name,str(x)) #create the name of the headers to pull measurements from
        volm += [xx] #add to list
    vlist = []
    for i in volm: #loop through column headers
        for ii in df_all.columns:
            if i in ii:
                vlist += [ii]
    ids = []; vs = []; imgs = []
    for i,j in enumerate(vlist[:-1]):
        jj = vlist[i+1]
        #calculate volume by looping through two columns at a time
        for rr, RR, hh,anid,img in zip(df_all[j],df_all[jj], df_all[tl_name],df_all['Animal_ID'],df_all['Image']):
            ph = float(interval)/float(100); h = float(hh)*ph
            r = float(rr)/float(2); R = float(RR)/float(2)
            v1 = (float(1)/float(3))*(math.pi)*h*((r**2)+(r*R)+(R**2))
            ids += [anid]; vs += [v1]; imgs += [img]
    d = {'Animal_ID':ids, body_name:vs, 'Image':imgs} #make dataframe of id and body volume
    df = pd.DataFrame(data = d) #make dataframe
    cls = df.columns.tolist() #get list of column headers
    grBy = ['Animal_ID','Image'] #list of columns to group by
    groups = [x for x in cls if x not in grBy] #get list of columns to be grouped
    df1 = df.groupby(['Animal_ID','Image'])[groups].apply(lambda x: x.astype(float).sum()).reset_index() #group to make sure no duplicates
    df2 = df1.merge(df_all[['Animal_ID','Species','Reproductive_Class','TL','Image']],on=['Animal_ID','Image'],how='inner')
    return df2

#BAI TRAP
def bai_trapezoid(df_all,tl_name,b_interval,b_lower,b_upper,vname):
    bai_name = "BAItrap_{0}".format(vname) #create BAI column header using interval
    sa_name = 'SA_{0}'.format(vname)
    bai = [] #list of columns containing the width data we want to use to calculate BAI
    for x in range(b_lower,(b_upper + b_interval), b_interval): # loop through columns w/in range we want
        xx = "{0}-{1}.00%".format(tl_name,str(x)) #set up column name
        bai += [xx]
    blist = []
    for i in bai:
        for ii in df_all.columns:
            if i in ii:
                blist += [ii]
    ids = []
    sas = []
    imgs = []
    for i,j in enumerate(blist[:-1]):
        jj = blist[i+1]
        for w, W, hh,anid,img in zip(df_all[j],df_all[jj], df_all[tl_name],df_all['Animal_ID'],df_all['Image']):
            ph = float(b_interval)/float(100)
            h = float(hh)*ph
            sa1 = (float(1)/float(2))*(w+W)*h
            ids += [anid]
            sas += [sa1]
            imgs += [img]
    d = {'Animal_ID':ids, sa_name:sas, 'Image':imgs}
    df = pd.DataFrame(data = d)

    cls = df.columns.tolist()
    grBy = ['Animal_ID','Image']
    groups = [x for x in cls if x not in grBy]
    df1 = df.groupby(['Animal_ID','Image'])[groups].apply(lambda x: x.astype(float).sum()).reset_index()
    dft = pd.merge(df_all[['Animal_ID','Image',tl_name]],df1,on = ['Animal_ID','Image'],how = "inner")
    dft[bai_name] = (dft[sa_name]/((dft[tl_name]*((b_upper-b_lower)/float(100)))**2))*100
    dft = dft.drop([tl_name],axis=1)
    return dft
    
#BAI PARABOLA
def bai_parabola(df_all,tl_name,b_interval,b_lower,b_upper,vname):
    df_all = df_all.dropna(how="all",axis='rows').reset_index()
    bai_name = "BAIpar_{0}".format(vname) #create BAI column header using interval
    sa_name = 'SA_{0}'.format(vname)
    bai = [] #list of columns containing the width data we want to use to calculate BAI
    perc_l = []
    for x in range(b_lower,(b_upper + b_interval), b_interval): # loop through columns w/in range we want
        xx = "{0}-{1}.00%".format(tl_name,str(x)) #set up column name
        bai += [xx]
        perc_l += [x/100]
    #here we check that the widths are actually in the column headers
    blist = []
    for i in bai:
        for ii in df_all.columns:
            if i in ii:
                blist += [ii]
    #make empty lists to be filled
    ids = []
    bais = []
    imgs = []
    sas = []
    #loop through the dataframe by image/ID
    for img,anid in zip(df_all['Image'],df_all['Animal_ID']):
        idx = df_all.loc[df_all['Image'] == img].index[0]
        ids += [anid]
        imgs += [img]
        #fill list of y values (y = width)
        ylist = []
        for b in blist:
            ylist += [(df_all[b].tolist()[idx])] #populate y values withwidth at each incr.
        ylist = np.array(ylist)

        tl = df_all[tl_name].tolist()[idx]
        min_tl = tl*(b_lower/100)
        max_tl = tl*(b_upper/100)

        xlist = [x*tl for x in perc_l] #populate x vlaues with x of TL at each incr.
        xlist = np.array(xlist)

        #make list of 500 x values along TL between bounds
        newx = np.linspace(min_tl,max_tl,500)

        #fit quadratric linear model using original x and y lists. then fit to big list of x values
        lm = np.polyfit(xlist,ylist,2)
        fit = np.poly1d(lm)
        pred = fit(newx)

        #integrate using linear model to get surface area
        I = quad(fit,min_tl,max_tl)
        sa = I[0]
        sas += [sa]

        #calculate BAI
        bai = (sa/((tl*((b_upper-b_lower)/float(100)))**2))*100

        bais += [bai]

    d = {'Animal_ID':ids, bai_name:bais, 'Image':imgs, sa_name: sas}
    df = pd.DataFrame(data = d)

    cls = df.columns.tolist()
    grBy = ['Animal_ID','Image']
    groups = [x for x in cls if x not in grBy]
    dfp = df.groupby(['Animal_ID','Image'])[groups].apply(lambda x: x.astype(float).sum()).reset_index()
    return dfp
