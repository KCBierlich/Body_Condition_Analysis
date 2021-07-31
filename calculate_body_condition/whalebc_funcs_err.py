import os, sys
import scipy
import pandas as pd
import numpy as np
import math
from scipy.integrate import quad
from functools import reduce
import pymc3 as pm
from pymc3 import stats


#body condition functions

#BODY VOLUME
def body_vol(df_all,tl_name,interval,lower,upper,vname):
    body_name = "BV_{0}".format(vname) #name of body volume column will use interval amount
    mean_name = "BV.{0}.mean".format(vname); hpd_l_name = 'BV.{0}.lower'.format(vname); hpd_u_name = 'BV.{0}.upper'.format(vname)
    volm = [] #make empty list of widths
    #now fill list with the names of the width columns we want
    volm += ["{0}.{1}.00..Width".format(tl_name,str(x)) for x in range(lower,(upper + interval), interval)]
    #check that those columns are in the dataframe
    colarr = np.array(df_all.columns)
    mask = np.isin(colarr,volm)
    cc = list(colarr[mask])
    vlist = ['index',tl_name]
    vlist.extend(cc)
    ##calculate body col
    df1 = df_all[vlist] #subset dataframe to just columns we want to use
    df1['spacer'] = np.NaN #add row of nans, we need this for the roll
    dfnp = np.array(df1) #convert dataframe to a numpy array
    ids = dfnp[:,0] #isolate array of just IDs
    tl = dfnp[:,1] #isolate array of just TLs
    r = (dfnp[:,2:])/2 #isolate array of just widths and divide each val by 2 (calculate radius)
    R = (np.roll(r,1,axis=1)) #make second array that's shifted over 1
    p2 = ((r**2)+(r*R)+(R**2)) #calculate the part of the equation that invovles the widths
    p1 = (tl*(interval/100))*(1/3)*math.pi #calculate the part of the equation that invovles TL
    v = p1[:,None]*p2 #calculate the volume of each frustrum
    vsum = np.nansum(v,axis=1) #sum all frustrums per ID
    vol_arr = np.column_stack((ids,vsum)) #make 2D array (df) of IDs and volumes
    dfv = pd.DataFrame(data=vol_arr,columns=["index",body_name]) #convert array to dataframe
    dfvx = df_all.merge(dfv,on='index') #merge back with original dataframe
    #check for duplicates and group
    cls = dfvx.columns.tolist() #get list of column headers
    grBy = ['index'] #list of columns to group by
    groups = [x for x in cls if x not in grBy] #get list of columns to be grouped
    df1 = dfvx.groupby(['index'])[groups].apply(lambda x: x.astype(float).sum()).reset_index() #group to make sure no duplicates
    #set up for summary stat dataframe
    mean = []
    mean += [np.mean(df1[body_name])]
    HPD = pm.stats.hpd(df1[body_name],hdi_prob = .95)
    HPD_l = HPD[0]; HPD_u = HPD[1]
    d = {mean_name:mean, hpd_l_name:HPD_l, hpd_u_name:HPD_u}
    df_sum = pd.DataFrame(data=d)
    return df1, df_sum


#BAI PARABOLA
def bai_parabola(df_all,tl_name,b_interval,b_lower,b_upper,vname):
    df_all = df_all.dropna(how="all",axis='rows').reset_index()
    bai_name = "BAIpar_{0}".format(vname) #create BAI column header using interval
    sa_name = 'SA_{0}'.format(vname)
    mean_name = "BAIpar.{0}.mean".format(vname); hpd_l_name = 'BAIpar.{0}.lower'.format(vname); hpd_u_name = 'BAIpar.{0}.upper'.format(vname)
    mean_nameSA = "SA.{0}.mean".format(vname); hpd_l_nameSA = "SA.{0}.lower".format(vname); hpd_u_nameSA = "SA.{0}.upper".format(vname)
    bai = [] #list of columns containing the width data we want to use to calculate BAI
    perc_l = []
    for x in range(b_lower,(b_upper + b_interval), b_interval): # loop through columns w/in range we want
        xx = "{0}.{1}.00..Width".format(tl_name,str(x)).format(str(x)) #set up column name
        bai += [xx]
        perc_l += [x/100]
    #here we check that the widths are actually in the column headers
    colarr = np.array(df_all.columns)
    mask = np.isin(colarr,bai)
    cc = list(colarr[mask])
    blist = []
    blist.extend(cc)
    #calculate BAI
    npy = np.array(df_all[bai]) #make array out of width values to be used
    ids = np.array(df_all['index'])
    plist = np.array(perc_l) #make array of the percents
    npTL = np.array(df_all['TL']) #make array of the total lengths
    x = np.tile(npTL.reshape(npTL.shape[0],-1), (1,plist.size)) #make a 2D array of TL's repeating to be multiplied with the percs
    npx = x * plist #make 2D array of the x values for the regression
    min_tl = npTL*(b_lower/100)
    max_tl = npTL*(b_upper/100)
    newx = np.linspace(min_tl,max_tl,500)
    sas = []
    for i in range(npx.shape[0]):
        xx = npx[i,:]; yy = npy[i,:]; newxx = newx[:,i]
        lm = np.polyfit(xx,yy,2)
        fit = np.poly1d(lm)
        pred = fit(newxx)
        I = quad(fit, min_tl[i], max_tl[i])
        sas.append(I[0])
    bais = (sas/((npTL*((b_upper-b_lower)/float(100)))**2))*100
    bai_arr = np.column_stack((ids,bais,sas))
    dfb = pd.DataFrame(data = bai_arr,columns= ['index',bai_name,sa_name])
    cls = dfb.columns.tolist()
    grBy = ['index']
    groups = [x for x in cls if x not in grBy]
    dfp = dfb.groupby(['index'])[groups].apply(lambda x: x.astype(float).sum()).reset_index()
    #set up for summary stat dataframe
    ##BAI
    mean = []
    mean += [np.mean(dfp[bai_name])]
    HPD = pm.stats.hpd(dfp[bai_name],hdi_prob=.95)
    HPD_l = HPD[0]; HPD_u = HPD[1]
    ##SA
    meanSA = []
    meanSA += [np.mean(dfp[sa_name])]
    HPDSA = pm.stats.hpd(dfp[sa_name],hdi_prob=.95)
    HPD_lSA = HPD[0]; HPD_uSA = HPD[1]
    d = {mean_name:mean, hpd_l_name:HPD_l, hpd_u_name:HPD_u, mean_nameSA:meanSA, hpd_l_nameSA:HPD_lSA, hpd_u_nameSA:HPD_uSA}
    df_sum = pd.DataFrame(data=d)
    return dfp,df_sum
