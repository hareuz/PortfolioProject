#real time  stock data and a moving average to each row of the csv file sells.csv
import Sells
import pandas as pd
import pandas_datareader as dr
from datetime import datetime,date,timedelta
startTime = datetime.now()

#calling the function from the Sell.py file we created. Imported it above
Sells.getSells() 
df = pd.read_csv('Insider1.csv',index_col = 0)

#when we run the script and then print info_dict, we can see that the dictionary is created. It has price and moving avg both. We added both in the 
# getPrice function so we dont have to do it again in the getMovingAverage func below
infoDict = {}
numperiods = 180

#here is an example of previous 300 days of data for apple using pandas datareader 
#this function getinfo will get all the info of the company. We will be calling it from getprice.
def getinfo(ticker,n):
    try:
        tickerdf = dr.data.get_data_yahoo(ticker,start = date.today() - timedelta(300) , end = date.today())
        #print(tickerdf)
        #to get the 'closing value from the very last row for the ticker"
        currentprice = tickerdf.iloc[-1]['Close']
         #for moving average (avg change in a data series over time. Used to keep track of price trends)
        #rolling function starts the min period of 0 days and gives upto n (180) days of data
        MA = pd.Series(tickerdf['Close'].rolling(n, min_periods=0).mean(), name='MA')
        currentma = MA[-1]
        print(f"data gathered for {ticker}")
        return (currentprice,currentma)
     #here a new column is created current price. getprice func takes every single row and gets price and adds in the dataframe. Same for moving avg code below
   
    except:
        return ('na','na')
    
# a function to get the price, and to make a dict to put the repeating tickers
def getPrice(row):
    ticker = row['Symbol']
    if ticker not in infoDict.keys():
        tickerinfo = getinfo(ticker,numperiods)#here the ticker is added in the dict created above. for both price and moving avg
        infoDict[ticker] = {}
        infoDict[ticker]["price"] = tickerinfo[0]
        infoDict[ticker]["ma"] = tickerinfo[1]
        return infoDict[ticker]["price"]
    else: #now if the ticker is in the dict the the function just gives the price
        return infoDict[ticker]["price"]

def getMovingAverage(row):
    ticker = row['Symbol']
    return infoDict[ticker]["ma"]

#These are the functions created using lambda that do the work. Here getPrice is called which calls getinfo to get info and then fills the rows and cols
df['currentprice'] = df.apply (lambda row: getPrice(row), axis=1)
print("Prices gathered")
df['movingaverage'] = df.apply (lambda row: getMovingAverage(row), axis=1) #moving avg here does the same. 
print("movingaverages gathered")
df.to_csv('InsiderPrices1.csv')

print(f'Execution Time: {datetime.now() - startTime}')