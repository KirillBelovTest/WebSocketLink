package kirillbelov.websocketlink;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

public class LTPClient {
    public String redirectHost;

	public int redirectPort;
	
	public Socket redirectSocket;

    public LTPClient(String redirectHost, int redirectPort) throws UnknownHostException, IOException {
        this.redirectHost = redirectHost;
        this.redirectPort = redirectPort;
        this.redirectSocket = new Socket(this.redirectHost, this.redirectPort);
    }

    public void send(String message) throws IOException {
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

    public void close() throws IOException {
        this.redirectSocket.close();
    }
}