/**
 * 
 */
package websocketjlink;

/**
 * @author Kirill
 *
 */
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.util.Map;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.handshake.ServerHandshake;

public class WebSocketJLinkClient extends WebSocketClient {
	
	public static void main(String[] args) throws UnknownHostException, URISyntaxException, IOException {
		WebSocketJLinkClient client = new WebSocketJLinkClient("wss://stream.binance.com:9443/ws/btcusdt@miniTicker", 9001);
		client.connect();
	}
	
	public int redirectPort;
	
	public Socket redirectSocket;

	public WebSocketJLinkClient(String serverURI, int redirectPort) throws URISyntaxException, UnknownHostException, IOException {
		super(new URI(serverURI));
		this.redirectPort = redirectPort;
		this.redirectSocket = new Socket("localhost", this.redirectPort);
	}
	
	public WebSocketJLinkClient(URI serverUri, Draft draft) {
		super(serverUri, draft);
	}

	public WebSocketJLinkClient(URI serverURI) {
		super(serverURI);
	}

	public WebSocketJLinkClient(URI serverUri, Map<String, String> httpHeaders) {
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

	@Override
	public void onError(Exception arg0) { 
		
	}

	@Override
	public void onMessage(String message) {
		try {
			OutputStream outToServer = redirectSocket.getOutputStream();
			DataOutputStream out = new DataOutputStream(outToServer);
			byte[] data = message.getBytes("UTF8"); 
			byte[] length = ByteBuffer.allocate(4).putInt(data.length).array(); 
			ByteArrayOutputStream outputStream = new ByteArrayOutputStream();			
			System.out.println("length: " + data.length);
			System.out.println(message);
			System.out.println();
			outputStream.write(length);
			outputStream.write(data);
			out.write(outputStream.toByteArray());
			System.out.println(message);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Override
	public void onOpen(ServerHandshake arg0) {
		
	}
}
