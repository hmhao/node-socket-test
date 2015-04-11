var net = require('net'),
    crypto = require('crypto');

var WS = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
var index = 0;
var server = net.createServer(function(socket) {
    index++;
    // 每次客户端连接都会新建一个 Client
    new Client(index, socket);
});
server.listen(1337, '127.0.0.1');

console.log('服务端已开启...');

function Client(index, socket) { //用于和客户端映射的类，每个客户端（socket）对应一个这样的对象
    var myIndex = index;
    var key; //对于HTMLClient的websocket需要进行握手后才能通信
    socket.on('data', function(d) {
        var dataLen = d.length,
            dataText = d.toString();
        if (!key && (key = dataText.match(/Sec-WebSocket-Key: (.+)|$/)[1])) {
            //WebSocket握手
            key = crypto.createHash('sha1').update(key + WS).digest('base64');
            socket.write([
                'HTTP/1.1 101 Switching Protocols',
                'Upgrade: websocket',
                'Connection: Upgrade',
                'Sec-WebSocket-Accept: ' + key
            ].join('\r\n') + '\r\n\r\n');
        } else {
            if (key) {
                //解析数据
                var frame = decodeDataFrame(d);
                //文本帧
                if (frame.Opcode == 1) {
                    //转义数据
                    dataText = frame.PayloadData.replace(/\W/g, function(e) {
                            e = e.charCodeAt(0).toString(16);
                            if (e.length == 3) e = '0' + e;
                            return '\\' + (e.length > 2 ? 'u' : 'x') + e;
                        });
                    //编码数据帧
                    var buffer = encodeDataFrame({
                        FIN: 1,
                        Opcode: 1,
                        PayloadData: '你好,第' + myIndex + '号客户端。我是服务端'
                    });
                    socket.write(buffer);
                };
            } else {
                socket.write('你好,第' + myIndex + '号客户端。我是服务端');
            }
        }
        console.log('收到客户端的数据，长度:' + dataLen);
        console.log(dataText);
    });
}

/*WebSocket数据帧解析*/
function decodeDataFrame(e) {
    var i = 0,
        j, s, frame = {
            //解析前两个字节的基本数据
            FIN: e[i] >> 7,
            Opcode: e[i++] & 15,
            Mask: e[i] >> 7,
            PayloadLength: e[i++] & 0x7F
        };
    //处理特殊长度126和127
    if (frame.PayloadLength == 126)
        frame.PayloadLength = (e[i++] << 8) + e[i++];
    if (frame.PayloadLength == 127)
        i += 4, //长度一般用四字节的整型，前四个字节通常为长整形留空的
        frame.PayloadLength = (e[i++] << 24) + (e[i++] << 16) + (e[i++] << 8) + e[i++];
    //判断是否使用掩码
    if (frame.Mask) {
        //获取掩码实体
        frame.MaskingKey = [e[i++], e[i++], e[i++], e[i++]];
        //对数据和掩码做异或运算
        for (j = 0, s = []; j < frame.PayloadLength; j++)
            s.push(e[i + j] ^ frame.MaskingKey[j % 4]);
    } else s = e.slice(i, frame.PayloadLength); //否则直接使用数据
    //数组转换成缓冲区来使用
    s = new Buffer(s);
    //如果有必要则把缓冲区转换成字符串来使用
    if (frame.Opcode == 1) s = s.toString();
    //设置上数据部分
    frame.PayloadData = s;
    //返回数据帧
    return frame;
};

/*WebSocket数据帧编码*/
function encodeDataFrame(e) {
    var s = [],
        o = new Buffer(e.PayloadData),
        l = o.length;
    //输入第一个字节
    s.push((e.FIN << 7) + e.Opcode);
    //输入第二个字节，判断它的长度并放入相应的后续长度消息
    //永远不使用掩码
    if (l < 126) s.push(l);
    else if (l < 0x10000) s.push(126, (l & 0xFF00) >> 8, l & 0xFF);
    else s.push(
        127, 0, 0, 0, 0, //8字节数据，前4字节一般没用留空
        (l & 0xFF000000) >> 24, (l & 0xFF0000) >> 16, (l & 0xFF00) >> 8, l & 0xFF
    );
    //返回头部分和数据部分的合并缓冲区
    return Buffer.concat([new Buffer(s), o]);
};
