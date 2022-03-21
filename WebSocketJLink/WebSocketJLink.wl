(* ::Package:: *)


BeginPackage["WebSocketJLink`", {"JLink`"}]


ClearAll["`*"]


WebSocketConnect::usage = 
"WebSocketConnect[\"wss://host:port/query\"]"


WebSocketClose::usage = 
"WebSocketClose[connection]"


WebSocketSend::usage = 
"WebSocketSend[connection, frame]"


WebSocketPing::usage = 
"WebSocketPing[connection]"


WebSocketConnections::usage = 
"WebSocketConnections[]"


Begin["`Private`"]


$connections = <||>


$directory = DirectoryName[$InputFileName]


javaInit[] := (
	InstallJava[]; 
	ReinstallJava[]; 
	AddToClasspath[FileNameJoin[{$directory, "Java"}]]; 
	Apply[AddToClasspath] @ FileNames["*.jar", {FileNameJoin[{$directory, "Java"}]}]; 
)


defaultEventHandler[message_] := (
	Print[Now]; 
	Print[message]; 
)


defaultDeserializer[data_] := 
data


defaultSerializer[expr_] := 
expr


connectionPattern[] := <|
	"UUID" -> _, 
	"Socket" -> _, 
	"Listener" -> _, 
	"Client" -> _, 
	"Buffer" -> _, 
	"Data" -> _
|>


messageListener[buffer_, data_, deserializer_, eventHandler_][assoc_?AssociationQ] := 
Module[{$bytes = assoc["DataByteArray"], $length, $currentLength, $completedData, $message, $messageString}, 
	If[buffer["Length"] == 0, 
		$length = FromDigits[Normal[$bytes[[1 ;; 4]]], 256]; 
		If[$length === Length[$bytes] + 1, 
			data["Append", eventHandler[$bytes[[5 ;; ]]]], 
			buffer["Append", $bytes]
		], 
		buffer["Append", $bytes]; 
		$length = FromDigits[Normal[buffer["Part", 1][[1 ;; 4]]], 256]; 
		$currentLength = buffer["Fold", #1 + Length[#2]&, -4]; 
		If[$currentLength >= $length, 
			$completedData = Apply[Join, buffer["Elements"]][[5 ;; $length + 4]]; 
			$messageString = ByteArrayToString[$completedData];
			$message = deserializer[$messageString]; 
			data["Append", $message]; 
			eventHandler[$message]; 
			buffer["DropAll"]; 
			If[$currentLength > $length, 
				buffer["Append", $bytes[[$length - $currentLength ;; ]]]
			]
		]; 
	]; 
]


SyntaxInformation[WebSocketConnections] = {
	"ArgumentsPattern" -> {}
}


WebSocketConnections[] := 
Values[$connections]


Options[WebSocketConnect] = {
	"EventHandler" -> defaultEventHandler, 
	"Deserializer" -> defaultDeserializer
}


SyntaxInformation[WebSocketConnect] = {
	"ArgumentsPattern" -> {_, OptionsPattern[]}, 
	"OptionNames" -> {"\"EventHandler\"", "\"Deserializer\""}
}


WebSocketConnect[url_String, OptionsPattern[]] := 
Module[{uuid, socket, listener, client, buffer, data, port, deserializer, eventHandler}, 
	javaInit[]; 
	uuid = CreateUUID["WebSocketConnection-"]; 
	data = CreateDataStructure["DynamicArray"]; 
	buffer = CreateDataStructure["DynamicArray"]; 
	deserializer = OptionValue["Deserializer"]; 
	eventHandler = OptionValue["EventHandler"]; 
	listener = SocketListen[Automatic, messageListener[buffer, data, deserializer, eventHandler]]; 
	socket = listener["Socket"];
	port = socket["DestinationPort"];
	client = JavaNew["websocketjlink.WebSocketJLinkClient", url, port]; 
	Block[{connect}, client@connect[]]; 
	
	$connections[uuid] = <|
		"UUID" -> uuid, 
		"Socket" -> socket, 
		"Listener" -> listener, 
		"Client" -> client, 
		"Buffer" -> buffer, 
		"Data" -> data
	|>
]


Options[WebSocketSend] = {
	"Serializer" -> defaultSerializer
}


SyntaxInformation[WebSocketSend] = {
	"ArgumentsPattern" -> {_, _, OptionsPattern[]}, 
	"OptionNames" -> {"\"Serializer\""}
}


WebSocketSend[connection: connectionPattern[], frame_, OptionsPattern[]] := 
Module[{serializer,jclient = connection["Client"], frameString}, 
	serializer = OptionValue["Serializer"];
	frameString = serializer[frame];  
	Block[{send}, jclient@send[frameString]]; 
	Return[connection]
]


SyntaxInformation[WebSocketClose] = {
	"ArgumentsPattern" -> {_}
}


WebSocketClose[connection: connectionPattern[]] := 
Module[{jclient, jsocket}, 
	KeyDropFrom[$connections, connection["UUID"]]; 
	DeleteObject[connection["Listener"]]; 
	Close[connection["Socket"]]; 
	Block[{redirectSocket}, jsocket = jclient@redirectSocket]; 
	Block[{close}, jsocket@close[]]; 
	Block[{close}, jclient@close[]]; 
	Return[connection]
]


SyntaxInformation[WebSocketPing] = {
	"ArgumentsPattern" -> {_}
}


WebSocketPing[connection: connectionPattern[]] := 
Module[{jclient = connection["Client"]}, 
	Block[{sendPing}, jclient@sendPing[]]; 
	Return[connection]
]


End[]


EndPackage[]