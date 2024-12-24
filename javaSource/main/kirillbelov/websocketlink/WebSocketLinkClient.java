/**
 * 
 */
package kirillbelov.websocketlink;

/*
  @author Kirill Belov
  
 */
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
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

	public int redirectPort;
	
	public Socket redirectSocket;

	public WebSocketLinkClient(String serverURI, String redirectHost, int redirectPort) throws URISyntaxException, IOException {
		super(new URI(serverURI));
		this.redirectHost = redirectHost;
		this.redirectPort = redirectPort;
		this.redirectSocket = new Socket(this.redirectHost, this.redirectPort);
	}

	public WebSocketLinkClient(String serverURI, String redirectHost, int redirectPort, Map<String, String> httpHeaders) throws URISyntaxException, IOException {
		super(new URI(serverURI), httpHeaders);
		this.redirectHost = redirectHost;
		this.redirectPort = redirectPort;
		this.redirectSocket = new Socket("localhost", this.redirectPort);
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
			redirectSocket.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/*
	 * close connection
	 */
	@Override
	public void onError(Exception arg0) {
		try {
			redirectSocket.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/*
	 * write message to connection
	 */
	@Override
	public void onMessage(String message) {
		try {
			OutputStream outToServer = redirectSocket.getOutputStream();
			DataOutputStream out = new DataOutputStream(outToServer);
			byte[] sign = "LTP#".getBytes(StandardCharsets.UTF_8);
			byte[] data = message.getBytes(StandardCharsets.UTF_8);
			byte[] length = ByteBuffer.allocate(4).putInt(data.length).array();
			ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
			outputStream.write(sign);
			outputStream.write(length);
			outputStream.write(data);
			out.write(outputStream.toByteArray());
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Override
	public void onOpen(ServerHandshake arg0) {
		System.out.println("new connection");
	}
}
