import pandas as pd
from datetime import datetime
#For reading html through pandas
import ssl
ssl._create_default_https_context = ssl._create_unverified_context


#this function is to get the data from the url. there are different pages and we are using both buy AND sell transcaction types 
#Three pages for each.

def getSells():

    startTime = datetime.now()
    NumPages = 3
    finaldf = pd.DataFrame() #empty frame to concat later.
    transactiontypes = ['buying','sales']
    pagesscraped = 0
    for t in transactiontypes:
        for i in range(NumPages):
            url = f"https://www.insidearbitrage.com/insider-{t}/?desk=yes&pagenum={i+1}"
            df = pd.read_html(url) #REad data and saved for dataframe later.
            df = df[0] #from the output, the first column has all our data so we keep that.
            columns = df.iloc[0] #first row is the column so putting that in a variable and just renaming columns.
            df.columns = columns
            df = df[1:] #first col is just numbering so we start from the 2nd one. (index 1)
            if t == 'buying': #depending of the type of transaction, we create byt and sell columns for our df
                df['Type'] = "buy"
            else:
                df['Type'] = "sell"
            frames = [finaldf,df]
            finaldf = pd.concat(frames) #concating df into the empty df created above.
            pagesscraped+=1
            print(f'{pagesscraped} Pages Scraped : Total Elapsed time = {datetime.now() - startTime}')

    finaldf.to_csv('Insider1.csv') 
    print(f'CSV File Created - Execution Time: {datetime.now() - startTime}') #gives to time took to scrape the data
 
