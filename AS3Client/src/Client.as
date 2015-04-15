package {
	import com.adobe.serialization.json.JSON;
	
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFieldAutoSize;
	import flash.events.KeyboardEvent;
	
	import io.socket.flash.ISocketIOTransport;
	import io.socket.flash.ISocketIOTransportFactory;
	import io.socket.flash.SocketIOErrorEvent;
	import io.socket.flash.SocketIOEvent;
	import io.socket.flash.SocketIOTransportFactory;
	import io.socket.flash.WebsocketTransport;
	
	public class Client extends Sprite {
		private var _socketIOTransportFactory:ISocketIOTransportFactory = new SocketIOTransportFactory();
		private var _ioSocket:ISocketIOTransport;
		
		private var _uName:TextField;
		private var _uInput:TextField;
		private var _content:TextField;
		
		public function Client() {
			initUI();
			initSocketIO();
		}
		
		private function initUI():void {
			_uName = new TextField();
			_uName.text = "Connecting...";
			_uName.autoSize = TextFieldAutoSize.LEFT;
			
			_uInput = new TextField();
			_uInput.type = TextFieldType.INPUT;
			_uInput.border = true;
			_uInput.width = 150;
			_uInput.height = 20;
			_uInput.y = _uName.y + _uName.height + 5;
			_uInput.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			
			_content = new TextField();
			_content.border = true;
			_content.width = 250;
			_content.height = 200;
			_content.y = _uInput.y + _uInput.height + 5;
			
			addChild(_uName);
			addChild(_uInput);
			addChild(_content);
		}
		
		private function keyUpHandler(event:KeyboardEvent):void {
			if (event.keyCode == 13) {
				_ioSocket.send(_uInput.text);
				_uInput.text = "";
			}
		}
		
		private function initSocketIO():void {
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
				if (event.message is Array) {
					var msg:Array = event.message as Array,
						cmd:String = msg.length > 0 ? event.message[0] : "",
						data:Object = msg.length > 1 ? event.message[1] : { },
						p:String = "";
					switch(cmd) {
						case "open":
							_uName.text = "Choose a name:";
							break;
						case "system":
							if (data.type === "welcome") {
								_uName.text = data.text;
								_uName.textColor = data.color;
								p = "system @ " + data.time + " : Welcome " + data.text + "\n";
							} else if (data.type == "disconnect") {
								p = "system @ " + data.time + " : Bye " + data.text + "\n";
							}
							_content.text = p + _content.text;
							break;
						case "message":
							p = data.author + " @ " + data.time + " : " + data.text + "\n";
							_content.text = p + _content.text;
							break;
					}
				}
			}
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