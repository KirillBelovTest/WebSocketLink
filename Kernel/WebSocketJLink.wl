(* ::Package:: *)

BeginPackage["KirillBelov`WebSocketJLink`", {"JLink`"}]


ClearAll["`*"]


WebSocketConnectionObject::usage = 
"WebSocketConnectionObject[assoc]"


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


$directory = ParentDirectory[DirectoryName[$InputFileName]]


javaInit[] := javaInit[] = 
Module[{$jlink}, 
	InstallJava[]; 
	$jlink = ReinstallJava[]; 
	Apply[AddToClassPath] @ FileNames["*.jar", {FileNameJoin[{$directory, "Java"}]}]; 
	$jlink
]


defaultEventHandler[connection_WebSocketConnection, message_] := (
	Print[Now]; 
	Print[message]; 
	connection["Data"]["Append", message]
)


defaultDeserializer[data_] := 
data


defaultSerializer[expr_] := 
expr


messageListener[buffer_, data_, deserializer_, eventHandler_][assoc_?AssociationQ] := 
Module[{$bytes = assoc["DataByteArray"], $currentBufferLength, $frameLength, $data, $frame, $rest, $message}, 
	 buffer["Append", $bytes]; 
	 $currentBufferLength = buffer["Fold", #1 + Length[#2]&, 0]; 
	 $frameLength = FromDigits[Normal[buffer["Part", 1][[1 ;; 4]]], 256]; 
	 If[
	 	$frameLength <= $currentBufferLength - 4, 
	 		$data = buffer["Fold", Join, {}]; 
	 		$frame = ByteArrayToString[ByteArray[$data[[5 ;; $frameLength + 4]]]]; 
	 		buffer["DropAll"]; 
	 		If[$frameLength < $currentBufferLength - 4, 
	 			$rest = $data[[$frameLength + 5 ;; ]]; 
	 			buffer["Append", $rest]; 
	 		]; 
	 		$message = deserializer[$frame]; 
	 		eventHandler[$message]; 
	 ]; 
]


messageListener[buffer_, data_, connection_WebSocketConnectionObject][assoc_?AssociationQ] := 
Module[{$bytes = assoc["DataByteArray"], $currentBufferLength, $frameLength, $data, $frame, $rest, $message}, 
	 buffer["Append", $bytes]; 
	 $currentBufferLength = buffer["Fold", #1 + Length[#2]&, 0]; 
	 $frameLength = FromDigits[Normal[buffer["Part", 1][[1 ;; 4]]], 256]; 
	 If[
	 	$frameLength <= $currentBufferLength - 4, 
	 		$data = buffer["Fold", Join, {}]; 
	 		$frame = ByteArrayToString[ByteArray[$data[[5 ;; $frameLength + 4]]]]; 
	 		buffer["DropAll"]; 
	 		If[$frameLength < $currentBufferLength - 4, 
	 			$rest = $data[[$frameLength + 5 ;; ]]; 
	 			buffer["Append", $rest]; 
	 		]; 
	 		$message = connection["Deserializer"][$frame]; 
	 		data["Append", $message]; 
	 		Through[Values[Normal[connection["EventHandler"]]][$message]]; 
	 ]; 
]


SyntaxInformation[WebSocketConnectionObject] = {
	"ArgumentsPattern" -> {_}
}


WebSocketConnectionObject[assoc_?AssociationQ][] := 
assoc


WebSocketConnectionObject[assoc_?AssociationQ][key_String] /; 
KeyExistsQ[assoc, key] := 
assoc[key]


WebSocketConnectionObject /: 
MakeBoxes[connection_WebSocketConnectionObject, form: StandardForm | OutputForm] := (
	BoxForm`ArrangeSummaryBox[
		WebSocketConnectionObject, 
		connection, 
		Null, 
		{
			{BoxForm`SummaryItem[{"UUID:    ", connection["UUID"]}], SpanFromLeft}, 
			{BoxForm`SummaryItem[{"Data:    ", ToString[connection["Data"]["Length"]] <> " messages received"}], SpanFromLeft}
		}, {
			{BoxForm`SummaryItem[{"Socket:  ", connection["Socket"]}], SpanFromLeft}, 
			{BoxForm`SummaryItem[{"Listener:", connection["Listener"]}], SpanFromLeft}, 
			{BoxForm`SummaryItem[{"Client:  ", connection["Client"]}], SpanFromLeft}, 
			{BoxForm`SummaryItem[{"Buffer:  ", connection["Buffer"]}], SpanFromLeft}, 
			{BoxForm`SummaryItem[{"Data:    ", connection["Data"]}], SpanFromLeft}
		}, 
		form
	]
)


SyntaxInformation[WebSocketConnections] = {
	"ArgumentsPattern" -> {}
}


WebSocketConnections[] := 
Values[$connections]


Options[WebSocketConnect] = {
	"EventHandler" -> defaultEventHandler, 
	"Deserializer" -> defaultDeserializer, 
	"Serializer" -> defaultSerializer
}


SyntaxInformation[WebSocketConnect] = {
	"ArgumentsPattern" -> {_, OptionsPattern[]}, 
	"OptionNames" -> {"\"EventHandler\"", "\"Deserializer\"", "\"Serializer\""}
}


WebSocketConnect[url_String, OptionsPattern[]] := 
Module[{uuid, socket, listener, client, buffer, data, port, deserializer, eventHandler}, 
	javaInit[]; 
	uuid = CreateUUID["WebSocketConnection-"]; 
	data = CreateDataStructure["DynamicArray"]; 
	buffer = CreateDataStructure["DynamicArray"]; 
	deserializer = OptionValue["Deserializer"]; 
	eventHandler = CreateDataStructure["HashTable"]; 
	OptionValue["EventHandler"]; 
	listener = SocketListen[Automatic, messageListener[buffer, data, deserializer, eventHandler]]; 
	socket = listener["Socket"];
	port = socket["DestinationPort"];
	client = JavaNew["websocketjlink.WebSocketJLinkClient", url, port]; 
	Block[{connect}, client@connect[]]; 
	Block[{isOpen}, While[!client@isOpen[], Pause[0.001]]]; 
	
	$connections[uuid] = WebSocketConnectionObject[<|
		"UUID" -> uuid, 
		"Socket" -> socket, 
		"Listener" -> listener, 
		"Client" -> client, 
		"Buffer" -> buffer, 
		"Data" -> data, 
		"Serializer" -> serializer, 
		"Deserializer" -> deserializer, 
		"EventHandler" -> eventHandlers
	|>]
]


Options[WebSocketSend] = {
	"Serializer" -> defaultSerializer
}


SyntaxInformation[WebSocketSend] = {
	"ArgumentsPattern" -> {_, _, OptionsPattern[]}, 
	"OptionNames" -> {"\"Serializer\""}
}


WebSocketSend[connection_WebSocketConnectionObject, frame_, OptionsPattern[]] := 
Module[{serializer, jclient = connection["Client"], frameString}, 
	serializer = OptionValue["Serializer"];
	frameString = serializer[frame];  
	Block[{send}, jclient@send[frameString]]; 
	Return[connection]
]


SyntaxInformation[WebSocketClose] = {
	"ArgumentsPattern" -> {_}
}


WebSocketClose[connection_WebSocketConnectionObject] := 
Module[{jclient = connection["Client"]}, 
	Block[{close}, jclient@close[]]; 
	Close[connection["Socket"]]; 
	DeleteObject[connection["Listener"]];
	KeyDropFrom[$connections, connection["UUID"]]; 
	Return[connection]
]


SyntaxInformation[WebSocketPing] = {
	"ArgumentsPattern" -> {_}
}


WebSocketConnectionObject /: 
Close[connection_WebSocketConnectionObject] := 
WebSocketClose[connection]


WebSocketPing[connection_WebSocketConnectionObject] := 
Module[{jclient = connection["Client"]}, 
	Block[{sendPing}, jclient@sendPing[]]; 
	Return[connection]
]


End[]


EndPackage[]
