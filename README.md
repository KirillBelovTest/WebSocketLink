# WebSocketJLink

## About 

Adds the ability to work with web sockets in Wolfram using [Java-WebSocket](https://github.com/TooTallNate/Java-WebSocket)

## Building

First compile java binary files using maven:

```bash
mvn package -f ./pom.xml
```



## Installation

```wolfram
PacletInstall["https://github.com/CryptoLabExperiments/WebSocketJLink/releases/download/v0.1.2/WebSocketLink-0.1.2.paclet"]
```

## Using

Import the package

```wolfram
Get["KirillBelov`WebSocketLink`"]
```

Create a new connection

```wolfram
connection1 = WebSocketConnect["wss://stream.binance.com:9443/ws/btcusdt@miniTicker"]
```
>```wolfram
> WebSocketConnectionObject[<>]
> ```

After serveral seconds you can view received data

```wolfram
Normal[connection1["Data"]]
```

Get list of subscribtions by sending a message

```wolfram
WebSocketSend[connection1, "{\"method\": \"LIST_SUBSCRIPTIONS\",\"id\": 3}"]
```

Association of all connections

```wolfram
WebSocketConnections[]
```

Close the connection

```wolfram
WebSocketClose[connection1]
```
