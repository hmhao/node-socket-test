var net = require("net");
var client = net.connect({
    port: 1337
}, function() {
    console.log('已连接成功');
    client.write('world!\r\n');
});
client.on('data', function(data) {
    console.log(data.toString());
    client.end();
});
client.on('end', function() {
    console.log('已断开连接');
});
