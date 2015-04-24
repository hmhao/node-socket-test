package io.socket.flash {
	
	public interface ISocketIOLogger {
		function log(message:String):void;
		function error(message:String):void;
	}
}