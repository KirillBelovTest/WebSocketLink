package kirillbelov.websocketlink;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Map; 

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.handshake.ServerHandshake;

public class WebSocketLinkClient extends WebSocketClient {
	public static void main(String[] args) throws URISyntaxException, IOException {
		WebSocketLinkClient client = new WebSocketLinkClient("wss://stream.binance.com:9443/ws/btcusdt@miniTicker", "localhost", 9001);
		client.connect();
	}
	
	public String redirectHost;

	public LTPClient ltpClient;

	public WebSocketLinkClient(String serverURI, String redirectHost, int redirectPort) throws URISyntaxException, IOException {
		super(new URI(serverURI));
		this.ltpClient = new LTPClient(redirectHost, redirectPort);
	}

	public WebSocketLinkClient(String serverURI, String redirectHost, int redirectPort, Map<String, String> httpHeaders) throws URISyntaxException, IOException {
		super(new URI(serverURI), httpHeaders);
		this.ltpClient = new LTPClient(redirectHost, redirectPort);
	}
	
	public WebSocketLinkClient(URI serverUri, Draft draft) {
		super(serverUri, draft);
	}

	public WebSocketLinkClient(URI serverURI) {
		super(serverURI);
	}

	public WebSocketLinkClient(URI serverUri, Map<String, String> httpHeaders) {
		super(serverUri, httpHeaders);
	}
	
	@Override
	public void onClose(int arg0, String arg1, boolean arg2) {
		super.close();
		try {
			ltpClient.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Override
	public void onError(Exception arg0) {
		super.close();
		try {
			ltpClient.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Override
	public void onMessage(String message) {
		try {
			System.out.println("onMessage: " + message);
			ltpClient.send(message);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Override
	public void onOpen(ServerHandshake arg0) {
		
	}
}
