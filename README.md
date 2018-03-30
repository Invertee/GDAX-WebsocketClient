
# GDAX-WebsocketClient

Experimental Websocket client that serves up GDAX JSON data to local clients over HTTP.

Only ticker requests work currently, you can allow the port to be bound by a non admin account with this command:
>netsh http add urlacl url=http://+:8000/ user=everyone

### Usage
Once running requests you can access data via HTTP as so:

  
> PS C:\Users\Admin> Invoke-RestMethod http://localhost:8000/ticker/ltc-btc
type : ticker\
sequence : 472597590\
product_id : LTC-BTC\
price : 0.01683000\
open_24h : 0.01570000\
volume_24h : 35794.615363\
low_24h : 0.01570000\
high_24h : 0.01683000\
volume_30d : 662843.88341736\
best_bid : 0.01682\
best_ask : 0.01683\
side : buy\
time : 2018-03-30T11:35:04.827000Z\
trade_id : 3935304\
last_size : 0.22153713\