package io.socket.flash {
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.utils.unescapeMultiByte;
	import flash.utils.ByteArray;
	
	public class BaseSocketIOTransport extends EventDispatcher implements ISocketIOTransport {
		protected var _hostname:String;
		public static const FRAME:String = "\ufffd";
		public static const SEPARATOR:String = ":";
		private var _connectLoader:URLLoader;
		protected var _sessionId:String;
		protected var _pingInterval:int;
		protected var _pingTimeout:int;
		protected var _pingIntervalTimer:Timer;
		protected var _pingTimeoutTimer:Timer;
		
		public function BaseSocketIOTransport(hostname:String = "") {
			_hostname = hostname;
		}
		
		public function get sessionId():String {
			return _sessionId;
		}
		
		public function get hostname():String {
			return _hostname;
		}
		
		public function send(message:Object):void {
		}
		
		protected function sendPacket(packet:Packet):void {
		
		}
		
		public function connect():void {
			var urlLoader:URLLoader = new URLLoader();
			var urlRequest:URLRequest = new URLRequest(hostname + "/?transport=polling&t=" + currentMills());
			urlLoader.addEventListener(Event.COMPLETE, onConnectedComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onConnectIoErrorEvent);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onConnectSecurityError);
			_connectLoader = urlLoader;
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.load(urlRequest);
		}
		
		private function decodePayloadAsBinary(byteArray:ByteArray):String {
			var ba:ByteArray = byteArray;
			var isString:Boolean = ba[0] === 0;
			var dataLength:String = "";
			var data:String = "";
			var byte:int;
			
			ba.position = 1;
			while (ba.bytesAvailable > 0) {
				byte = ba.readUnsignedByte();
				if (byte == 255)
					break;
				dataLength += byte;
			}
			var dataBytes:ByteArray = new ByteArray();
			dataBytes.writeBytes(ba, 2 + dataLength.length);
			if (isString) {
				dataBytes.position = 0;
				while (dataBytes.bytesAvailable > 0) {
					data += String.fromCharCode(dataBytes.readUnsignedByte());
				}
			}
			return data;
		}
		
		private function onConnectedComplete(event:Event):void {
			var data:String = decodePayloadAsBinary(_connectLoader.data);
			data = data.substring(1);
			var json:Object = JSON.decode(data);
			
			_sessionId = json.sid;
			_pingInterval = json.pingInterval;
			_pingTimeout = json.pingTimeout;
			_connectLoader.close();
			_connectLoader = null;
			if (_sessionId == null) {
				// Invalid request
				var errorEvent:SocketIOErrorEvent = new SocketIOErrorEvent(SocketIOErrorEvent.CONNECTION_FAULT, "Invalid sessionId request");
				dispatchEvent(errorEvent);
				return;
			}
			onSessionIdRecevied(_sessionId);
		}
		
		protected function onSessionIdRecevied(sessionId:String):void {
			
		}
		
		private function onConnectSecurityError(event:SecurityErrorEvent):void {
			_connectLoader = null;
			var socketIOErrorEvent:SocketIOErrorEvent = new SocketIOErrorEvent(SocketIOErrorEvent.SECURITY_FAULT, event.text);
			dispatchEvent(socketIOErrorEvent);
		}
		
		private function onConnectIoErrorEvent(event:IOErrorEvent):void {
			_connectLoader = null;
			var socketIOErrorEvent:SocketIOErrorEvent = new SocketIOErrorEvent(SocketIOErrorEvent.CONNECTION_FAULT, event.text);
			dispatchEvent(socketIOErrorEvent);
		}
		
		protected function currentMills():Number {
			return (new Date()).time;
		}
		
		public function disconnect():void {
			if(_pingIntervalTimer){
				_pingIntervalTimer.reset();
				_pingIntervalTimer.removeEventListener(TimerEvent.TIMER, onPingInterval);
				_pingIntervalTimer = null;
			}
			
			if(_pingTimeoutTimer){
				_pingTimeoutTimer.reset();
				_pingTimeoutTimer.removeEventListener(TimerEvent.TIMER, onPingInterval);
				_pingTimeoutTimer = null;
			}
		}
		
		protected function setPing():void {
			_pingIntervalTimer = new Timer(_pingInterval);
			_pingIntervalTimer.addEventListener(TimerEvent.TIMER, onPingInterval);
			_pingTimeoutTimer = new Timer(_pingTimeout);
			_pingTimeoutTimer.addEventListener(TimerEvent.TIMER, onPingTimeout);
			
			_pingIntervalTimer.start();
		}
		
		protected function onPingInterval(event:TimerEvent):void {
			sendPing();
			trace('writing ping packet - expecting pong within ' + _pingTimeout);
			onHeartbeat();
		}
		
		protected function onHeartbeat():void {
			_pingTimeoutTimer.reset();
			_pingTimeoutTimer.start();
		}
		
		protected function onPingTimeout(event:TimerEvent):void {
			trace("ping timeout");
			disconnect();
		}
		
		public function processMessages(messages:Array):void {
			// Socket is live - any packet counts
			onHeartbeat();
			for each (var message:String in messages) {
				var type:String = message.charAt(0);
				var index:int = 1;
				var data:String = message.substr(index, message.length);
				switch (type) {
					case Packet.CONNECT_TYPE: 
						fireConnected();
						break;
					case Packet.PING_TYPE: 
						sendPing();
						break;
					case Packet.PONG_TYPE: 
						receivePong(data);
						break;
					case Packet.MESSAGE_TYPE: 
						fireMessageEvent(data);
						break;
					case Packet.DISCONNECT_TYPE: 
						disconnect();
						return;
					case Packet.ERROR_TYPE: 
						disconnect();
					default: 
				}
			}
		}
		
		protected function fireConnected():void {
			dispatchEvent(new SocketIOEvent(SocketIOEvent.CONNECT));
		}
		
		protected function sendProbe():void {
			sendPacket(new Packet(Packet.PING_TYPE, "probe"));
		}
		
		protected function sendPing():void {
			trace("sendPing");
			sendPacket(new Packet(Packet.PING_TYPE, ""));
		}
		
		protected function receivePong(data:String):void {
			if (data === "probe") {
				sendPacket(new Packet(Packet.UPGRADE_TYPE, ""));
			}else {
				trace("receivePong");
			}
		}
		
		protected function fireMessageEvent(message:String):void {
			var msg:Object = Parser.decodeString(message);
			switch (msg.type) {
				case Parser.CONNECT: 
					this.fireConnected();
					break;
				case Parser.EVENT: 
				case Parser.BINARY_EVENT: 
					var messageEvent:SocketIOEvent;
					messageEvent = new SocketIOEvent(SocketIOEvent.MESSAGE, msg.data);
					dispatchEvent(messageEvent);
					break;
				case Parser.ACK: 
					//this.onack(packet);
					break;
				case Parser.BINARY_ACK: 
					//this.onack(packet);
					break;
				case Parser.DISCONNECT: 
					this.disconnect();
					break;
				case Parser.ERROR: 
					this.disconnect();
					break;
			}
		}
		
		protected function fireDisconnect():void {
			dispatchEvent(new SocketIOEvent(SocketIOEvent.DISCONNECT));
		}
		
		public function decode(data:String, unescape:Boolean = false):Array {
			if (unescape) {
				data = unescapeMultiByte(data);
			}
			if (data.substr(0, FRAME.length) !== FRAME) {
				return [data];
			}
			
			var messages:Array = [], number:*, n:*;
			do {
				if (data.substr(0, FRAME.length) !== FRAME) {
					return messages;
				}
				data = data.substr(FRAME.length);
				number = "", n = "";
				for (var i:int = 0, l:int = data.length; i < l; i++) {
					n = Number(data.substr(i, 1));
					if (data.substr(i, 1) == n) {
						number += n;
					} else {
						data = data.substr(number.length + FRAME.length);
						number = Number(number);
						break;
					}
				}
				messages.push(data.substr(0, number));
				data = data.substr(number);
			} while (data !== "");
			return messages;
		}
		
		public function encodePackets(packets:Array):String {
			var ret:String = "";
			if (packets.length == 1) {
				ret = encodePacket(packets[0]);
			} else {
				for each (var packet:Packet in packets) {
					var message:String = encodePacket(packet);
					if (message != null) {
						ret += FRAME + message.length + FRAME + message
					}
				}
			}
			return ret;
		};
		
		private function encodePacket(packet:Packet):String {
			switch (packet.type) {
				case Packet.MESSAGE_TYPE: 
					return Packet.MESSAGE_TYPE + Parser.encodeAsString({type: Parser.EVENT, data: ["message", packet.data]});
				default: 
					return packet.type + String(packet.data);
			}
		}
	}
}