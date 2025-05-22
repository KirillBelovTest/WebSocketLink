#!/usr/bin/env wolframscript
(* ::Package:: *)

If[$FrontEnd === Null, 
	PacletDirectoryLoad[Directory[]], 
	PacletDirectoryLoad[NotebookDirectory[]]
]; 
Get["KirillBelov`WebSocketLink`"];
connection = WebSocketConnect["wss://stream.binance.com:9443/ws/btcusdt@miniTicker"];


connection["EventHandlers", "UpdateChart"] = Function[Echo[#2]];


First @ connection["Data"]


DateListPlot @ 
Query[All, {
	"E" /* Function[FromUnixTime[#/1000]], "c" /* ToExpression
}] @ connection["Data"]
