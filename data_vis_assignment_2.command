#!/Library/Frameworks/Python.framework/Versions/3.8/bin/python3

import os
import sys
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import datetime

# Set file directory
os.chdir(os.path.dirname(sys.argv[0]))


df = pd.read_csv(
    'fb441e62df2d58994928907a91895ec62c2c42e6cd075c2700843b89.csv')

# Memory management/dtype assignment
df['ID'] = df['ID'].astype('category')
df['Date'] = df['Date'].astype('datetime64')

# Remaking Element column to be binary
df.rename(columns = {'Element': 'is_max'},inplace = True)
df['is_max'] = np.where(df['is_max'] == 'TMAX',1,0)
df['is_max'] = df['is_max'].astype('bool')

# Now simplify to only month and year data
df['mon-day'] = [int(x.month)*100 + int(x.day) for x in df['Date']]

# Remove leap year data
test = []
for x in set([x for x in df['Date'] if x.month ==2 and x.day ==29]):
    test.extend(list(df[df['Date'] == x].index))
df.drop(test,inplace = True)

## Get highs and lows for every day, shade in-between

# Eliminate 2015 dates
df2 = df.drop(df[df['Date']> '2014-12-31'].index)

df_max = df2[df2['is_max'] == True]
df_min = df2[df2['is_max'] == False]
# df_max = df_max.groupby('mon-day').Data_Value.agg(max)
df_max = df_max.groupby('mon-day').agg({'Data_Value': max,'Date': lambda x: list(x)[0]})
df_min = df_min.groupby('mon-day').Data_Value.agg(min)
df2 = pd.merge(df_max,df_min,how = 'outer',left_index = True, right_index = True)
#Create new column to serve as the axis labels
df2['axis_label'] = [str(x.month) + '/' + str(x.day) + '/2000'  for x in df2['Date']]
df2['axis_label'] = df2['axis_label'].astype('datetime64')

del df_min, df_max
df2.rename(columns = {'Data_Value_x': 'max','Data_Value_y':'min'},inplace = True)
df2.set_index('axis_label',inplace = True)

## Now to plot

# plt.plot(df2['max']/10,'-',color = 'r', label = 'Record High')
# plt.plot(df2['min']/10,'-',color = 'b', label = 'Record Low')
# plt.legend()
# plt.ylabel(r'$\degree$Celsius')
# plt.title('10 Year Record High and Low Temperatures\n by Day of Year (Data From 2005-2014)')
# ax = plt.gca()
# ax.set_xticklabels(['Jan','Mar','May','Jul','Sep','Nov','Jan'])
# for line in ax.lines:
#     line.set_linewidth(.3)
# ax.fill_between(list(df2.index),df2['max']/10,df2['min']/10,facecolor = 'lightgrey')

## Overlay on the previous graph a scatter plot of record highs and lows
df_max = df[df['is_max'] == True]
df_min = df[df['is_max'] == False]
df_max = df_max.groupby('mon-day').agg({'Data_Value': max,'Date': max})
df_min = df_min.groupby('mon-day').Data_Value.agg(min)

df3 = pd.merge(df_max,df_min,how = 'outer',left_index = True, right_index = True)
# #Create new column to serve as the axis labels
# df3['axis_label'] = [str(x.month) + '/' + str(x.day) + '/2000'  for x in df3['Date']]
# df3['axis_label'] = df3['axis_label'].astype('datetime64')
#
# del df_min, df_max
# df3.rename(columns = {'Data_Value_x': 'max','Data_Value_y':'min'},inplace = True)
# df3.set_index('axis_label',inplace = True)

## Take a dataset of 2015 dates and use it to compare with the other dataset
# By merging the datasets on 'str' dates
# First we select only the 2015 dates
df3 = df[df['Date']> '2014-12-31']

# Then we find the daily extremes for these groups
df_max = df3[df3['is_max'] == True]
df_min = df3[df3['is_max'] == False]
# df_max = df_max.groupby('mon-day').Data_Value.agg(max)
df_max = df_max.groupby('mon-day').agg({'Data_Value': max,'Date': lambda x: list(x)[0]})
df_min = df_min.groupby('mon-day').Data_Value.agg(min)
# Merge min and max
df3 = pd.merge(df_max,df_min,how = 'outer',left_index = True, right_index = True)

#Create new column to serve as the axis labels
df3['axis_label'] = [str(x.month) + '/' + str(x.day) + '/2000'  for x in df3['Date']]
df3['axis_label'] = df3['axis_label'].astype('datetime64')

del df_min, df_max
df3.rename(columns = {'Data_Value_x': 'max','Data_Value_y':'min'},inplace = True)
df3.set_index('axis_label',inplace = True)

# Now merge this dataset with the previous decade data
df3 = pd.merge(df2,df3, how = 'left', left_index = True, right_index = True)

# Then we create a new column for all the places where 2015 data is more than the previous ten years
# Max
max_greater = df3[df3['max_y'] > df3['max_x']]

# Min
min_greater = df3[df3['min_y'] < df3['min_x']]

# Plotting 2005-2014 data
plt.plot(df2['max']/10,'-',color = 'r', alpha = .5, label = '10-yr Record High')
plt.plot(df2['min']/10,'-',color = 'b', alpha = .5, label = '10-yr Record Low')

plt.ylabel(r'$\degree$Celsius')
plt.title('Record Lows and Lows (2005-2014)\n vs Record Breaking Days (2015)')
ax = plt.gca()
ax.set_xticklabels(['Jan','Mar','May','Jul','Sep','Nov','Jan'])
for line in ax.lines:
    line.set_linewidth(.3)
ax.fill_between(list(df2.index),df2['max']/10,df2['min']/10,facecolor = 'lightgrey')

# Plotting 2015 data
plt.plot(max_greater['max_y']/10,'.',color = 'r', label = 'Record High Broken')
plt.plot(min_greater['min_y']/10,'.',color = 'b', label = 'Record Low Broken')
plt.legend()

plt.savefig('data_viz_assignment_2.png')
