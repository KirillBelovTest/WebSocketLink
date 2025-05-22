(* ::Package:: *)

(* ::Title:: *)
(*WebSocketLink*)


(* ::Section::Closed:: *)
(*Begin package*)


BeginPackage["KirillBelov`WebSocketLink`", {
    "JLink`", 
    "KirillBelov`Objects`", 
    "KirillBelov`CSockets`TCP`", 
    "KirillBelov`CSockets`Handler`", 
    "KirillBelov`LTP`"
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

        "ListenSocket", 
        "ListenPort", 
        "Listener", 
        "ListenHandler", 
        
        "JavaWebSocketClient", 
        "Data", 
        "DataStore", 
        "EventHandler"
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
With[{connection = WebSocketConnectionObject[opts]}, 
    javaInit[];

    Module[{ltp, listenPort, javaLTPClient, javaWSClient}, 
        ltp = LTPListen[onMessage[connection], 
            "Responsible" -> False, 
            "Deserializer" -> Function[ImportByteArray[#, "RawJSON"]], 
            "Serializer" -> Function[ExportByteArray[#, "RawJSON"]]
        ]; 

        KeyValueMap[(connection[#] = #2)&, ltp];

        listenPort = ltp["ListenPort"];

        javaLTPClient = JavaNew["kirillbelov.ltp.LTPClient", listenPort];
        javaWSClient = JavaNew["kirillbelov.websocketlink.WebSocketLinkClient", url, javaLTPClient]; 

        connection["JavaLTPClient"] = javaLTPClient;
        connection["JavaWebSocketClient"] = javaWSClient;

        With[{dynamicArray = CreateDataStructure["DynamicArray"]}, 
            connection["DataStore"] = dynamicArray; 
            connection["Data"] := dynamicArray["Elements"]
        ];

        connection["EventHandlers"] = <|
            "Save" -> Function[{conn, msg}, conn["DataStore"]["Append", msg]]
        |>;

        Block[{connect}, connection["JavaWebSocketClient"]@connect[]]; 
        Block[{isOpen}, TimeConstrained[While[!connection["JavaWebSocketClient"]@isOpen[], Pause[0.001]], 15, 
            Message[WebSocketConnect::notopened, url]]; 
        ];
    ];  

    Return[connection]
]; 


onMessage[connection_WebSocketConnectionObject][message_] := 
(Map[#[connection, message]&] @ connection["EventHandlers"]); 


(* ::Section::Closed:: *)
(*Ping*)


SyntaxInformation[WebSocketPing] = {
    "ArgumentsPattern" -> {_}
}; 


WebSocketPing[connection_WebSocketConnectionObject] := 
Module[{jclient = connection["JavaWebSocketClient"]}, 
    Block[{sendPing}, jclient@sendPing[]]; 
    Return[connection]
]; 


(* ::Section::Closed:: *)
(*Close*)


SyntaxInformation[WebSocketClose] = {
    "ArgumentsPattern" -> {_}
}; 


WebSocketClose[connection_WebSocketConnectionObject] := 
Module[{jclient = connection["JavaWebSocketClient"]}, 
    Block[{close}, jclient@close[]]; 
    Close[connection["ListenSocket"]]; 
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
Module[{serializer, frameString, jclient = connection["JavaWebSocketClient"]}, 
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