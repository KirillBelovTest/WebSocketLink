package kirillbelov.websocketlink;

import io.socket.emitter.Emitter;

public class LTPListener {
    public static Emitter.Listener getListener(){
        return new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                System.out.println(args[0]); 
            }
        }; 
    }
}
