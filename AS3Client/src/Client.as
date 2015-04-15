package {
	import com.adobe.serialization.json.JSON;
	import io.socket.flash.ISocketIOTransport;
	import io.socket.flash.ISocketIOTransportFactory;
	import io.socket.flash.SocketIOErrorEvent;
	import io.socket.flash.SocketIOEvent;
	import io.socket.flash.SocketIOTransportFactory;
	import io.socket.flash.WebsocketTransport;
	import io.socket.flash.XhrPollingTransport;
	
	import flash.display.Sprite;
	
	public class Client extends Sprite {
		private var _socketIOTransportFactory:ISocketIOTransportFactory = new SocketIOTransportFactory();
		private var _ioSocket:ISocketIOTransport;
		
		public function Client() {
			_ioSocket = _socketIOTransportFactory.createSocketIOTransport(WebsocketTransport.TRANSPORT_TYPE, "localhost:3000/socket.io", this);
			_ioSocket.addEventListener(SocketIOEvent.CONNECT, onSocketConnected);
			_ioSocket.addEventListener(SocketIOEvent.DISCONNECT, onSocketDisconnected);
			_ioSocket.addEventListener(SocketIOEvent.MESSAGE, onSocketMessage);
			_ioSocket.addEventListener(SocketIOErrorEvent.CONNECTION_FAULT, onSocketConnectionFault);
			_ioSocket.addEventListener(SocketIOErrorEvent.SECURITY_FAULT, onSocketSecurityFault);
			_ioSocket.connect();
		}
		
		private function onSocketConnectionFault(event:SocketIOErrorEvent):void {
			logMessage(event.type + ":" + event.text);
		}
		
		private function onSocketSecurityFault(event:SocketIOErrorEvent):void {
			logMessage(event.type + ":" + event.text);
		}
		
		private function onSocketMessage(event:SocketIOEvent):void {
			if (event.message is String) {
				logMessage(String(event.message));
			} else {
				logMessage(JSON.encode(event.message));
			}
		}
		
		private function onSendClick():void {
			_ioSocket.send({type: "chatMessage", data: "Привет!!!"});
			_ioSocket.send({type: "chatMessage", data: "Delirium tremens"});
			_ioSocket.send("HELLO!!!");
		}
		
		private function onSocketConnected(event:SocketIOEvent):void {
			logMessage("Connected" + event.target);
		}
		
		private function onSocketDisconnected(event:SocketIOEvent):void {
			logMessage("Disconnected" + event.target);
		}
		
		private function logMessage(message:String):void {
			trace(message);
		}
	}
}