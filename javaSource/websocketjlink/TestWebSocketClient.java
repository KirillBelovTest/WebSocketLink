/**
 * 
 */
package websocketjlink;

import java.io.IOException;
import java.net.Socket;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.UnknownHostException;
import java.util.Map;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.handshake.ServerHandshake;

public class TestWebSocketClient extends WebSocketClient {
	
	public static void main(String[] args) throws UnknownHostException, URISyntaxException, IOException {
		TestWebSocketClient client = new TestWebSocketClient("wss://ws-feed.exchange.coinbase.com"); 
		client.connect();
		boolean b1 = client.isOpen();
		client.send("{\r\n"
				+ "    \"type\": \"subscribe\",\r\n"
				+ "    \"product_ids\": [\r\n"
				+ "        \"ETH-USD\",\r\n"
				+ "        \"BTC-USD\"\r\n"
				+ "    ],\r\n"
				+ "    \"channels\": [\"ticker\"]\r\n"
				+ "}");
	}
	
	public int redirectPort;
	
	public Socket redirectSocket;

	public TestWebSocketClient(String serverURI) throws URISyntaxException {
		super(new URI(serverURI));
	}
	
	public TestWebSocketClient(URI serverUri, Draft draft) {
		super(serverUri, draft);
	}

	public TestWebSocketClient(URI serverURI) {
		super(serverURI);
	}

	public TestWebSocketClient(URI serverUri, Map<String, String> httpHeaders) {
		super(serverUri, httpHeaders);
	}

	@Override
	public void onClose(int arg0, String arg1, boolean arg2) {
		
	}

	@Override
	public void onError(Exception arg0) { 
		
	}

	@Override
	public void onMessage(String message) {
		System.out.println(message);
	}

	@Override
	public void onOpen(ServerHandshake arg0) {
		
	}
}
