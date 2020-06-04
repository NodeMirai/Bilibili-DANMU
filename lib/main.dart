import 'package:flutter/material.dart';
// websocket相关的包
import 'package:web_socket_channel/io.dart';
// 编解码包, json反序列化
import 'dart:convert';
import 'dart:math';
// 二进制相关
import 'dart:typed_data';
import 'dart:io';
// 主要引用Timer定时器模块
import 'dart:async';

/**
 * 开启代理
 * 缺少此处代码会导致charles抓取不到
 * 什么事系统代理？
 */
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) {
        return "PROXY 192.168.1.102:80;";
      }
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // HttpOverrides.global = new MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        // ???
        home: Scaffold(
            // ???
            appBar: AppBar(title: const Text('Home')),
            body: new Wrap(children: [
              new Container(child: new InputItem()),
              new Container(
                  height: 300,
                  child: ListView.builder(
                      itemCount: 100,
                      itemExtent: 50.0, //强制高度为50.0
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(title: Text("$index"));
                      }))
            ])));
  }
}

class MessageList extends StatefulWidget {
  @override
  MessageListState createState() {
    // TODO: implement createState
    MessageListState();
  }
}

class MessageListState extends State<MessageList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: 100,
        itemExtent: 50.0, //强制高度为50.0
        itemBuilder: (BuildContext context, int index) {
          return ListTile(title: Text("$index"));
        });
  }
}

/**
 * StatefulWidget与State<>之间的关系
 */
class InputItem extends StatefulWidget {
  @override
  InputItemState createState() {
    // TODO: implement createState
    return InputItemState();
  }
}

class InputItemState extends State<InputItem> {
  final TextEditingController _controller = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    Widget InputItem = new Container(
        color: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: new Wrap(
          children: <Widget>[
            new Row(children: [
              new Container(
                margin: const EdgeInsets.only(right: 6),
                child: new Text(
                  '房间id',
                  style: new TextStyle(fontSize: 18),
                ),
              ),
              new Expanded(
                  child: new TextField(
                controller: _controller,
              ))
            ]),
            new Container(
              margin: EdgeInsets.only(top: 6),
              child: new Row(children: [
                RaisedButton(
                  onPressed: () {
                    // ????
                    connectRoom(3672155);
                    /* if (_controller.text == '') {
                      showMySimpleDialog(context);
                      return;
                    } */
                    // 如果校验通过，则发起请求
                  },
                  child: new Text('连接'),
                ),
                RaisedButton(
                  onPressed: () => {},
                  child: new Text('断开'),
                ),
              ]),
            )
          ],
        ));
    return InputItem;
  }

  void writeInt(List<int> buffer, int start, int len, int value) {
    int i = 0;
    while (i < len) {
      buffer[start + i] = (value / pow(256, len - i - 1)).round();
      i++;
    }
  }

  /**
   * 将发送内容拼装为buffer
   */
  Uint8List encode(String str, int op) {
    // 将想要发送的内容转为二进制数据
    Uint8List data = Uint8List.fromList(utf8.encode(str));
    // 计算出包的总长度
    int packetLen = 16 + data.length;
    // 进入房间时需要发送的验证信息前缀：协议类型、操作类型等
    List<int> header = [0, 0, 0, 0, 0, 16, 0, 1, 0, 0, 0, op, 0, 0, 0, 1];
    // 将总长度写入数据包前4个字节
    writeInt(header, 0, 4, packetLen);
    header.addAll(data);
    return Uint8List.fromList(header);
  }

  /**
   * 链接主流程
   */
  void connectRoom(int roomid) {
    var channel =
        IOWebSocketChannel.connect('wss://broadcastlv.chat.bilibili.com:2245/sub');

    Uint8List hehe = encode('{"roomid":${roomid},"protover":1}', 7);

    // 进房发送消息确认
    channel.sink.add(hehe);
    // 心跳,以下内容类似setInterval
    Timer sub = Timer.periodic(new Duration(seconds: 30), (timer) {
      channel.sink.add(encode('', 2));
      print('心跳');
    });
    
    channel.stream.listen(
      (msgEvent) {
        ResData packet = decode(msgEvent);
        switch (packet.op) {
          case 8:
            print('加入房间');
            break;
          case 3:
            /* const count = packet.body.count
      print(`人气：${count}`); */
            break;
          case 5:
            packet.body.forEach((body) {
              var cmd = body['cmd'].toString();
              if (cmd.contains(':')) {
                cmd = cmd.substring(0, cmd.indexOf(':'));
              }
              switch (cmd) {
                case 'DANMU_MSG':
                  print('${body['info'][2][1]}: ${body['info'][1]}');
                  break;
                case 'SEND_GIFT':
                  print(
                      '${body.data.uname} ${body.data.action} ${body.data.int} 个 ${body.data.giftName}');
                  break;
                case 'WELCOME':
                  print('欢迎 ${body.data.uname}');
                  break;
                // 此处省略很多其他通知类型
                default:
                  print(body);
              }
            });
            break;
          default:
            print(packet);
        }
      },
      onDone: () {
        print('websocket close');
        sub.cancel();
      },
      onError: (error) {
        debugPrint('ws error $error');
      },
    );
  }

  /**
   * 读取指定buffer中从start byte到len byte的数据并返回整数
   * 此处会
   */
  int readInt(List<int> buffer, int start, int len) {
    int result = 0;
    for (int i = len - 1; i >= 0; i--) {
      result += pow(256, len - i - 1) * buffer[start + i];
    }
    return result;
  }

  ResData decode(List<int> buffer) {
    ResData resData = new ResData();

    resData.packetLen = readInt(buffer, 0, 4);
    resData.headerLen = readInt(buffer, 4, 2);
    resData.ver = readInt(buffer, 6, 2);
    resData.op = readInt(buffer, 8, 4);
    resData.seq = readInt(buffer, 12, 4);
    // 操作类型为5表示弹幕
    if (resData.op == 5) {
      resData.body = [];
      int offset = 0;
      while (offset < buffer.length) {
        int packetLen = readInt(buffer, offset + 0, 4);
        int headerLen = 16;
        // 从头部长度到包总长度之间为数据
        var p = buffer.getRange(offset + headerLen, offset + packetLen);
        List<int> data = zlib.decode(p.toList());
        String str = utf8.decode(Uint8List.fromList(data));
        resData.body.add(jsonDecode(str.substring(str.indexOf('{'))));

        offset += packetLen;
      }
    } else if (resData.op == 3) {
      /* resData.body = {e
          count: readInt(buffer,16,4)
        }; */
    }

    return resData;
  }
}

class ResData {
  int packetLen;
  int headerLen;
  int ver;
  int op;
  int seq;
  dynamic body;
}

/**
 * 唤起弹窗方法
 */
void showMySimpleDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return new SimpleDialog(
          title: new Text("SimpleDialog"),
          children: <Widget>[
            new SimpleDialogOption(
              child: new Text("SimpleDialogOption One"),
              onPressed: () {
                Navigator.of(context).pop("SimpleDialogOption One");
              },
            ),
            new SimpleDialogOption(
              child: new Text("SimpleDialogOption Two"),
              onPressed: () {
                Navigator.of(context).pop("SimpleDialogOption Two");
              },
            ),
            new SimpleDialogOption(
              child: new Text("SimpleDialogOption Three"),
              onPressed: () {
                Navigator.of(context).pop("SimpleDialogOption Three");
              },
            ),
          ],
        );
      });
}
