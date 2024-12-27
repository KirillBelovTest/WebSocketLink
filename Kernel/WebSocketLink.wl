(* ::Package:: *)

(* ::Title:: *)
(*WebSocketLink*)


(* ::Section::Closed:: *)
(*Begin package*)


BeginPackage["KirillBelov`WebSocketLink`", {
	"JLink`", 
	"KirillBelov`Objects`", 
	"KirillBelov`CSockets`TCP`", 
	"KirillBelov`CSockets`Handler`"
}]; 


(* ::Section::Closed:: *)
(*Clear all names*)


ClearAll["`*"]; 


(* ::Section::Closed:: *)
(*Names*)


WebSocketConnectionObject::usage = 
"WebSocketConnectionObject[assoc]"; 


WebSocketConnect::usage = 
"WebSocketConnect[\"wss://host:port/query\"]"; 


WebSocketClose::usage = 
"WebSocketClose[connection]"; 


WebSocketSend::usage = 
"WebSocketSend[connection, frame]"; 


WebSocketPing::usage = 
"WebSocketPing[connection]"; 


WebSocketConnections::usage = 
"WebSocketConnections[]"; 


(* ::Section::Closed:: *)
(*Begin private context*)


Begin["`Private`"]; 


(* ::Section:: *)
(*Implementation*)


(* ::Section::Closed:: *)
(*Connection object*)


CreateType[WebSocketConnectionObject, 
	Function[connection, AppendTo[$connections, connection["UUID"] -> connection]], 
	{
		"UUID", 
		"Socket", 
		"Port", 
		"Listener", 
		"Client", 
		"Data", 
		"Handler", 
		"HTTPHeaders"
	}
]; 


(* ::Section::Closed:: *)
(*Connections store*)


SyntaxInformation[WebSocketConnections] = {
	"ArgumentsPattern" -> {}
}; 


WebSocketConnections[] := 
Values[$connections]; 


(* ::Section:: *)
(*Connect*)


WebSocketConnect::notopened = 
"Connection not opened on url = `1`"; 


WebSocketConnect[url_String, opts: OptionsPattern[{WebSocketConnectionObject}]] := 
Module[{connection, httpHeaders}, 
	javaInit[];
	connection = WebSocketConnectionObject[opts]; 
	handler = CSocketHandler[]; 
	handler["DefaultAccumulator"] = getLength; 
	handler["DefaultHandler"] = onMessage[connection]; 
	handler["Deserializer"] = Function[#[[9 ;; ]]]; 

	connection["Socket"] = CSocketOpen["localhost", RandomInteger[{20000, 60000}]]; 
	connection["Port"] = connection["Socket"]["DestinationPort"]; 
	connection["Listener"] = SocketListen[connection["Socket"], handler]; 
	
	If[AssociationQ[OptionValue["HTTPHeaders"]], 
		httpHeaders = JavaNew["java.util.HashMap"]; 
		Block[{put}, KeyValueMap[httpHeaders@put[MakeJavaObject@ToString[#1], MakeJavaObject@ToString[#2]]&, OptionValue["HTTPHeaders"]]]; 
		connection["Client"] = JavaNew["kirillbelov.websocketlink.WebSocketLinkClient", url, "localhost", connection["Port"], httpHeaders]; , 
	(*Else*)
		connection["Client"] = JavaNew["kirillbelov.websocketlink.WebSocketLinkClient", url, "localhost", connection["Port"]]
	];
	
	connection["Deserializer"] = Function[ImportByteArray[#, "RawJSON"]]; 
	connection["Data"] = CreateDataStructure["DynamicArray"]; 
	connection["Handler"] = <|
		"Echo" -> Function[{c, m}, Echo[m, "Message: "]], 
		"Save" -> Function[{c, m}, c["Data"]["Append", m]]
	|>; 

	Block[{connect}, connection["Client"]@connect[]]; 
	Block[{isOpen}, TimeConstrained[While[!connection["Client"]@isOpen[], Pause[0.001]], 15, 
		Message[WebSocketConnect::notopened, url]]; 
	]; 

	Return[connection]
]; 


getLength[packet_Association] := 
ImportByteArray[packet["DataByteArray"][[5 ;; 8]], "Integer32", ByteOrdering -> 1][[1]] + 8; 


onMessage[connection_WebSocketConnectionObject][packet_Association] := 
(Map[#[connection, connection["Deserializer"] @ packet["Message"]]&] @ connection["Handler"];); 


(* ::Section::Closed:: *)
(*Ping*)


SyntaxInformation[WebSocketPing] = {
	"ArgumentsPattern" -> {_}
}; 


WebSocketPing[connection_WebSocketConnectionObject] := 
Module[{jclient = connection["Client"]}, 
	Block[{sendPing}, jclient@sendPing[]]; 
	Return[connection]
]; 


(* ::Section::Closed:: *)
(*Close*)


SyntaxInformation[WebSocketClose] = {
	"ArgumentsPattern" -> {_}
}; 


WebSocketClose[connection_WebSocketConnectionObject] := 
Module[{jclient = connection["Client"]}, 
	Block[{close}, jclient@close[]]; 
	Close[connection["Socket"]]; 
	DeleteObject[connection["Listener"]];
	KeyDropFrom[$connections, connection["UUID"]]; 
	Return[connection]
]; 


(* ::Section::Closed:: *)
(*Overrire close*)


WebSocketConnectionObject /: Close[connection_WebSocketConnectionObject] := 
WebSocketClose[connection]; 


(* ::Section::Closed:: *)
(*Send*)


Options[WebSocketSend] = {
	"Serializer" -> Automatic
}


SyntaxInformation[WebSocketSend] = {
	"ArgumentsPattern" -> {_, _, OptionsPattern[]}, 
	"OptionNames" -> {"\"Serializer\""}
}; 


WebSocketSend::senderr = 
"Can't send expression `1` as string to websocket connection."; 


WebSocketSend[connection_WebSocketConnectionObject, frame_, OptionsPattern[]] := 
Module[{serializer, frameString, jclient = connection["Client"]}, 
	serializer = OptionValue["Serializer"]; 
	If[serializer === Automatic, serializer = connection["Serializer"]]; 
	
	frameString = serializer[frame]; (*_String*) 

	If[!StringQ[frameString], 
		Message[WebSocketSend::senderr, frameString]; 
		Return[Null]
	]; 

	Block[{send}, jclient@send[frameString]]; 
	Return[connection]
]; 


(* ::Section::Closed:: *)
(*Internal*)


$directory = ParentDirectory[DirectoryName[$InputFileName]]; 


If[!AssociationQ[$connections], $connections = <||>]; 


javaInit[] := javaInit[] = 
Module[{$jlink}, 
	InstallJava[]; 
	$jlink = ReinstallJava[]; 
	Apply[AddToClassPath] @ FileNames["*.jar", {FileNameJoin[{$directory, "Java"}]}]; 
	$jlink
]; 


connectionQ[___] := 
False; 


connectionQ[connection_WebSocketConnectionObject?ObjectQ] := 
True; 


(* ::Section::Closed:: *)
(*End private context*)


End[(*`Private`*)]; 


(* ::Section::Closed:: *)
(*End package*)


EndPackage[(*KirillBelov`WebSocketLink`*)]; 