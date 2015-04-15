package io.socket.flash {
	import com.adobe.serialization.json.JSON;
	
	/**
	 * 参看socket.io->socket.io-parser
	 */
	public class Parser {
		
		public static const CONNECT:int = 0;
		public static const DISCONNECT:int = 1;
		public static const EVENT:int = 2;
		public static const ACK:int = 3;
		public static const ERROR:int = 4;
		public static const BINARY_EVENT:int = 5;
		public static const BINARY_ACK:int = 6;
		
		public static const types:Array = [
			'CONNECT', 
			'DISCONNECT', 
			'EVENT', 
			'BINARY_EVENT', 
			'ACK', 
			'BINARY_ACK', 
			'ERROR'];
		
		public static function decodeString(str:String):Object {
			var p:Object = {};
			var i:int = 0;
			var c:*;
			
			// look up type
			p.type = Number(str.charAt(0));
			if (null == types[p.type])
				return {type: ERROR, data: 'parser error'};
			
			// look up attachments if type binary
			if (BINARY_EVENT == p.type || BINARY_ACK == p.type) {
				p.attachments = '';
				while (str.charAt(++i) != '-') {
					p.attachments += str.charAt(i);
				}
				p.attachments = Number(p.attachments);
			}
			
			// look up namespace (if any)
			if ('/' == str.charAt(i + 1)) {
				p.nsp = '';
				while (++i) {
					c = str.charAt(i);
					if (',' == c)
						break;
					p.nsp += c;
					if (i + 1 == str.length)
						break;
				}
			} else {
				p.nsp = '/';
			}
			
			// look up id
			var next:* = str.charAt(i + 1);
			if ('' != next && Number(next) == next) {
				p.id = '';
				while (++i) {
					c = str.charAt(i);
					if (null == c || Number(c) != c) {
						--i;
						break;
					}
					p.id += str.charAt(i);
					if (i + 1 == str.length)
						break;
				}
				p.id = Number(p.id);
			}
			
			// look up json data
			if (str.charAt(++i)) {
				try {
					p.data = com.adobe.serialization.json.JSON.decode(str.substr(i));
				} catch (e:Error) {
					return {type: ERROR, data: 'parser error'};
				}
			}
			return p;
		}
		
		public static function encodeAsString(obj:Object):String {
			var str:String = '';
			var nsp:Boolean = false;
			
			// first is type
			str += obj.type;
			
			// attachments if we have them
			if (BINARY_EVENT == obj.type || BINARY_ACK == obj.type) {
				str += obj.attachments;
				str += '-';
			}
			
			// if we have a namespace other than `/`
			// we append it followed by a comma `,`
			if (obj.nsp && '/' != obj.nsp) {
				nsp = true;
				str += obj.nsp;
			}
			
			// immediately followed by the id
			if (null != obj.id) {
				if (nsp) {
					str += ',';
					nsp = false;
				}
				str += obj.id;
			}
			
			// json data
			if (null != obj.data) {
				if (nsp)
					str += ',';
				str += com.adobe.serialization.json.JSON.encode(obj.data);
			}
			return str;
		}
	}
}