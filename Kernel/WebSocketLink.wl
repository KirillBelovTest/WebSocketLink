(* ::Package:: *)

(* ::Title:: *)
(*WebSocketLink*)


(* ::Section::Closed:: *)
(*Begin package*)


BeginPackage["KirillBelov`WebSocketLink`", {"JLink`", "KirillBelov`Objects`"}]


(* ::Section::Closed:: *)
(*Clear all names*)


ClearAll["`*"]


(* ::Section::Closed:: *)
(*Names*)


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


(* ::Section::Closed:: *)
(*Begin private context*)


Begin["`Private`"]


(* ::Section::Closed:: *)
(*Internal*)


$directory = ParentDirectory[DirectoryName[$InputFileName]]


javaInit[] := javaInit[] = 
Module[{$jlink}, 
	InstallJava[]; 
	$jlink = ReinstallJava[]; 
	Apply[AddToClassPath] @ FileNames["*.jar", {FileNameJoin[{$directory, "Java"}]}]; 
	$jlink
]


connectionQ[___] := 
False


connectionQ[connection_WebSocketConnectionObject?ObjectQ] := 
True


(* ::Section::Closed:: *)
(*Connection object*)


SyntaxInformation[WebSocketConnectionObject] = {
	"ArgumentsPattern" -> {_., OptionsPattern[]}, 
	"OptionNames" -> {
		"\"Icon\"", 
		"\"Init\"", 
		"\"UUID\"", 
		"\"Socket\"", 
		"\"Listener\"", 
		"\"Client\"", 
		"\"Buffer\"", 
		"\"Data\"", 
		"\"EventHandler\"", 
		"\"Deserializer\"", 
		"\"Serializer\""
	}
}


CreateType[WebSocketConnectionObject, {
	"Icon" -> Import[FileNameJoin[{$directory, "Images", "WebSocketConnectionIcon.png"}]], 
	"Init" -> Function[connection, AppendTo[$connections, connection["UUID"] -> connection]; connection], 
	"UUID", "Socket", "Listener", "Client", "Buffer", "Data", 
	"EventHandler", "Deserializer", "Serializer"
}]


(* ::Section::Closed:: *)
(*Connections store*)


$connections = <||>


SyntaxInformation[WebSocketConnections] = {
	"ArgumentsPattern" -> {}
}


WebSocketConnections[] := 
Values[$connections]


(* ::Section::Closed:: *)
(*Message listener*)


messageListener[uuid_String][assoc_?AssociationQ] := 
Module[{
	$bytes = assoc["DataByteArray"], 
	$currentBufferLength, 
	$frameLength, 
	$data, 
	$frame, 
	$rest, 
	$message, 
	$buffer = $connections[uuid]["Buffer"], 
	$deserializer = $connections[uuid]["Deserializer"], 
	$eventHandler = $connections[uuid]["EventHandler"]
}, 
	$buffer["Append", $bytes]; 
	$currentBufferLength = $buffer["Fold", #1 + Length[#2]&, 0]; 
	$frameLength = FromDigits[Normal[$buffer["Part", 1][[1 ;; 4]]], 256]; 
	If[
		$frameLength <= $currentBufferLength - 4, 
			$data = $buffer["Fold", Join, {}]; 
			$frame = ByteArrayToString[ByteArray[$data[[5 ;; $frameLength + 4]]]]; 
			$buffer["DropAll"]; 
			If[$frameLength < $currentBufferLength - 4, 
				$rest = $data[[$frameLength + 5 ;; ]]; 
				$buffer["Append", $rest]; 
			]; 
			$message = $deserializer[$frame]; 
			Which[
				ListQ[$eventHandler] || AssociationQ[$eventHandler], 
					Map[#[$connections[uuid], $message]&, $eventHandler], 
				True, 
					$eventHandler[$connections[uuid], $message]
			]; 
	]; 
]


(* ::Section::Closed:: *)
(*Override += and -= for EventHandler*)


Unprotect[AddTo, SubtractFrom]


AddTo[(connection_?connectionQ)["EventHandler"], eventHandlerKey_ -> eventHandler_] /; 
AssociationQ[connection["EventHandler"]] := 
connection["EventHandler"] = Append[connection["EventHandler"], eventHandlerKey -> eventHandler]


AddTo[(connection_?connectionQ)["EventHandler"], eventHandler: Except[_Rule]] /; 
AssociationQ[connection["EventHandler"]] := 
AddTo[connection["EventHandler"], Length[connection["EventHandler"]] + 1 -> eventHandler]


AddTo[(connection_?connectionQ)["EventHandler"], eventHandler_] /; 
Not[AssociationQ[connection["EventHandler"]]] := (
	connection["EventHandler"] = <|"Default" -> connection["EventHandler"]|>; 
	AddTo[connection["EventHandler"], eventHandler]
)


SubtractFrom[(connection_?connectionQ)["EventHandler"], eventHandlerKey_] /; 
AssociationQ[connection["EventHandler"]] && KeyExistsQ[connection["EventHandler"], eventHandlerKey] := 
connection["EventHandler"] = Delete[connection["EventHandler"], eventHandlerKey]


Protect[AddTo, SubtractFrom]


(* ::Section::Closed:: *)
(*Connect*)


SyntaxInformation[WebSocketConnect] = {
	"ArgumentsPattern" -> {_, OptionsPattern[]}, 
	"OptionNames" -> {"\"Data\"", "\"EventHandler\"", "\"Deserializer\"", "\"Serializer\""}
}


Options[WebSocketConnect] = {
	"Data" :> CreateDataStructure["DynamicArray"], 
	"EventHandler" -> Function[{connection, message}, connection["Data"]["Append", message]], 
	"Deserializer" -> Function[message, message], 
	"Serializer" -> Function[message, message]
}


WebSocketConnect::notopened = 
"Connection not opened"


WebSocketConnect[url_String, OptionsPattern[]] := 
Module[{connection}, 
	javaInit[]; 
	connection = WebSocketConnectionObject[
		"UUID" -> CreateUUID["WebSocketConnection-"], 
		"Serializer" -> OptionValue["Serializer"], 
		"Deserializer" -> OptionValue["Deserializer"], 
		"EventHandler" -> OptionValue["EventHandler"], 
		"Buffer" -> CreateDataStructure["DynamicArray"], 
		"Data" -> OptionValue["Data"]
	]; 
	
	connection["Listener"] = SocketListen[Automatic, messageListener[connection["UUID"]]]; 
	connection["Socket"] = connection["Listener"]["Socket"];
	connection["Port"] = connection["Socket"]["DestinationPort"];
	connection["Client"] = JavaNew["kirillbelov.websocketlink.WebSocketLinkClient", url, connection["Port"]]; 
	Block[{connect}, connection["Client"]@connect[]]; 
	Block[{isOpen}, TimeConstrained[While[!connection["Client"]@isOpen[], Pause[0.001]], 5, 
		Message[WebSocketConnect::notopened]]
	]; 
	
	Return[connection]
]


(* ::Section::Closed:: *)
(*Ping*)


SyntaxInformation[WebSocketPing] = {
	"ArgumentsPattern" -> {_}
}


WebSocketPing[connection_WebSocketConnectionObject] := 
Module[{jclient = connection["Client"]}, 
	Block[{sendPing}, jclient@sendPing[]]; 
	Return[connection]
]


(* ::Section::Closed:: *)
(*Close*)


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


(* ::Section::Closed:: *)
(*Overrire close*)


WebSocketConnectionObject /: Close[connection_WebSocketConnectionObject] := 
WebSocketClose[connection]


(* ::Section::Closed:: *)
(*Send*)


Options[WebSocketSend] = {
	"Serializer" -> Automatic
}


SyntaxInformation[WebSocketSend] = {
	"ArgumentsPattern" -> {_, _, OptionsPattern[]}, 
	"OptionNames" -> {"\"Serializer\""}
}


WebSocketSend[connection_WebSocketConnectionObject, frame_, OptionsPattern[]] := 
Module[{serializer, jclient = connection["Client"], frameString}, 
	serializer = OptionValue["Serializer"]; 
	If[serializer == Automatic, serializer = connection["Serializer"]]; 
	frameString = serializer[frame];  
	Block[{send}, jclient@send[frameString]]; 
	Return[connection]
]


(* ::Section::Closed:: *)
(*End private context*)


End[]


(* ::Section::Closed:: *)
(*End package*)


EndPackage[]
