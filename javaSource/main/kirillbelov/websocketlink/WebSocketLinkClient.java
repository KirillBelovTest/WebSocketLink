package kirillbelov.websocketlink;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.handshake.ServerHandshake;
import kirillbelov.ltp.LTPClient;

public class WebSocketLinkClient extends WebSocketClient {
    public LTPClient ltpClient;

    public WebSocketLinkClient(String serverURI, LTPClient ltpClient) throws URISyntaxException, IOException {
        super(new URI(serverURI));
        this.ltpClient = ltpClient;
    }
    
    @Override
    public void onClose(int arg0, String arg1, boolean arg2) {
        super.close();
        try {
            ltpClient.getSocket().close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onError(Exception arg0) {
        super.close();
        try {
            ltpClient.getSocket().close();
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
        System.out.println("onOpen");
    }
}
