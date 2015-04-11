package 
{
	import flash.display.*; 
    import flash.events.*; 
    import flash.net.*; 
    import flash.system.*; 
    import flash.text.*; 
    import flash.utils.*; 
	
    public class Client extends Sprite { 
         
        public function Client() {           
            var socket:Socket = new Socket(); 
            socket.addEventListener(Event.CONNECT,onEvent);//侦听连接事件 
            socket.addEventListener(ProgressEvent.SOCKET_DATA,onEvent);//侦听数据收到事件 
            socket.connect('127.0.0.1',1337);//连接服务端 
        } 
        private function onEvent(e:Event):void  { 
            var socket:Socket = e.target as Socket; 
            switch(e.type){ 
                case Event.CONNECT: 
                    trace('已连接成功'); 
                    socket.writeUTFBytes('我是来自客户端的消息');//把字符串按照utf-8的编码发出去 
                    break; 
                case ProgressEvent.SOCKET_DATA: 
                    trace('收到数据,长度'+socket.bytesAvailable); 
                    read(socket); 
                    break; 
            } 
        } 
        private function read(socket:Socket):void   { 
            var ba:ByteArray = new ByteArray();//缓冲区 
            socket.readBytes(ba,0,socket.bytesAvailable);//按收到的数据长度来读 
            var val:String = ba.readUTFBytes(ba.length);//安装utf-8的编码解析二进制 
            trace(val); 
        } 
    } 
	
}