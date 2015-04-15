var io = require('socket.io-client');
var client = io.connect('http://localhost:3000');

client.on('connect', function(){
  console.log('已连接成功');
});
//监听自定义system事件
client.on('open', function(data){
  //设置名字
  client.send("Node Client");
});
//监听自定义system事件，判断welcome或者disconnect，打印系统消息信息
client.on('system', function(json) {
    var p = '';
    if (json.type === 'welcome') {
        console.log('system @ '+ json.time + ' : Welcome ' + json.text);
    } else if (json.type == 'disconnect') {
        console.log('system @ '+ json.time + ' : Bye ' + json.text);
    }
});

//监听自定义message事件，打印消息信息
client.on('message', function(json) {
    var p = '<p><span style="color:' + json.color + ';">' + json.author + '</span> @ ' + json.time + ' : ' + json.text + '</p>';
    console.log(json.author + ' @ ' + json.time + ' : ' + json.text);
});