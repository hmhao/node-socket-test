package io.socket.flash {
	
	/**
	 * 参看socket.io->engine.io->engine.io-parser
	 */
	public class Packet {
		private var _type:String;
		private var _data:Object;
		
		public static const CONNECT_TYPE:String = "0";
		public static const DISCONNECT_TYPE:String = "1";
		public static const PING_TYPE:String = "2";
		public static const PONG_TYPE:String = "3";
		public static const MESSAGE_TYPE:String = "4";
		public static const UPGRADE_TYPE:String = "5";
		public static const NOOP_TYPE:String = "6";
		public static const ERROR_TYPE:String = "7";
		
		public function Packet(type:String, data:Object) {
			this._type = type;
			this._data = data || '';
		}
		
		public function get type():String {
			return _type;
		}
		
		public function get data():Object {
			return _data;
		}
	}
}