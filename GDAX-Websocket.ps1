# Connection URI and GDAX subscription message.
$uri = 'wss://ws-feed.gdax.com'
$js = @" 
{
    "type": "subscribe",
    "product_ids": [
        "BTC-GBP",
        "BTC-EUR",
        "ETH-BTC",
        "ETH-EUR",
        "LTC-BTC",
        "LTC-EUR",
        "LTC-USD",
        "ETH-USD",
        "BTC-USD",
        "BCH-USD",
        "BCH-EUR",
        "BCH-BTC"
    ],
    "channels": [
        {
            "name": "ticker",
            "product_ids": [
                "BTC-GBP",
                "BTC-EUR",
                "ETH-BTC",
                "ETH-EUR",
                "LTC-BTC",
                "LTC-EUR",
                "LTC-USD",
                "ETH-USD",
                "BTC-USD",
                "BCH-USD",
                "BCH-EUR",
                "BCH-BTC"
            ]
        }
    ]
}
"@
    # Create a byte array with the subscription message
    $Array = @()
    $Encoding = [System.Text.Encoding]::UTF8
    $Array = $Encoding.GetBytes($js)
    $Msg = New-Object System.ArraySegment[byte]  -ArgumentList @(,$Array)

    # Create Websocket and cancellation token
    $w = new-object System.Net.WebSockets.ClientWebSocket                                                
    $c = New-Object System.Threading.CancellationToken 
    # Connect to websocket
    $t = $W.ConnectAsync($uri, $c)
    # Todo: Replace this sleep command with something more dependable
    Start-Sleep 3
    # Send subscription message
    $send = $W.SendAsync($Msg,[System.Net.WebSockets.WebSocketMessageType]::Text, [System.Boolean]::TrueString, $C)


    # Create new powershell session to handle requests for data. 
    $Session = [powershell]::Create()
    $Session.AddScript({
        Set-Location Env:
        # Create a HTTP listener   
        $listen = New-Object System.Net.HttpListener
        $listen.Prefixes.Add('http://+:8000/') 
        $listen.Start()
        While ($true) {
        # Listen for incoming requests
        $Context = $listen.GetContext()
        $request = $context.Request
        $response = $context.Response

        # Generate response based on the requested info. 
        if ($request.Url -match '/end$') {
            Break
        } else {
            $requestq = $request.url.AbsolutePath -split "/",""
            # Ticker Requests
            if ($requestq[1] -eq 'ticker') {
                $selectedp = $requestq[2]
                $selectedp = $selectedp -replace "-",""
                $results = Get-Item $selectedp | Select-Object -ExpandProperty "Value"
                # Convert the returned data to JSON and set the HTTP content type to JSON
                $message = $results
                $response.ContentType = 'application/json'
            } Else {
                $message = 'Item not found'
                $response.ContentType = 'text/html'
            }
        }

    # Convert the data to UTF8 bytes
    [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    # Set length of response
    $response.ContentLength64 = $buffer.length
    # Write response out and close
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
    }
    })
    # Start powershell session. 
    $Session.BeginInvoke()

    # Create empty byte array. 
    $R = ""
    $Size = 1024
    $Array = [byte[]] @(,0) * $Size
    $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$Array)

        while ($w.State -eq 'open') {
        # Receive data from websocket
        $t = $W.ReceiveAsync($Recv, $C)

        $Recv.Array[0..($t.Result.Count - 1)] | ForEach-Object { $R = $R + [char]$_ }
        $result = $R | ConvertFrom-Json -ErrorAction SilentlyContinue
        $resultstring = $R.ToString()

        # Sort results and create env variables. 
        if ($result.type -eq 'ticker') {
            Set-Location Env:
            $product = $result.product_id -replace "-",""
            New-Item $product -Value $resultstring -Force
        }

        Clear-Variable "R","Result" -Force
    } 



