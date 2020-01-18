import 'package:flutter/material.dart';
import 'custom_icons.dart';
import 'package:share/share.dart';
import "package:flutter/services.dart";
import "package:toast/toast.dart";

///DEBUG CODE
//import 'package:device_preview/device_preview.dart';
//void main() => runApp(
//  DevicePreview(
//    builder: (context) => MyApp(),
//  ),
//);
//
//
//class MyApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      locale: DevicePreview.of(context).locale, // <--- Add the locale
//      builder: DevicePreview.appBuilder, // <--- Add the builder
//      title: 'Flutter Demo',
//      theme: ThemeData(
//        primarySwatch: Colors.blue,
//      ),
//      home: MyHomePage(title: 'Flutter Demo Home Page'),
//    );
//  }
//}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
        backgroundColor: Colors.green,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController facebook_text = new TextEditingController();
  TextEditingController twitter_text = new TextEditingController();
  TextEditingController linkedin_text = new TextEditingController();
  TextEditingController pinterest_text = new TextEditingController();
  TextEditingController tumblr_text = new TextEditingController();
  TextEditingController whatsapp_text = new TextEditingController();

  TextEditingController url_text = new TextEditingController();
  TextEditingController message_text = new TextEditingController();
  TextEditingController phone_text = new TextEditingController();

  String _generateFacebook({url}) {
    String updatedUrl = url.toString().replaceAll(":", "%3A");
    updatedUrl = updatedUrl.toString().replaceAll("/", "%2F");
    updatedUrl = updatedUrl.toString().replaceAll("#", "%23");
    String link = "https://www.facebook.com/sharer/sharer.php?u=$updatedUrl";
    print("facebook link :" + link);
    setState(() {
      facebook_text.text = link;
    });
    return link;
  }

  String _generateTwitter({url, message}) {
    String updatedMessage = message.toString().replaceAll(" ", "%20");
    String updatedUrl = url.toString().replaceAll(":", "%3A");
    updatedUrl = updatedUrl.toString().replaceAll("/", "%2F");
    updatedUrl = updatedUrl.toString().replaceAll("#", "%23");
    String link =
        "https://twitter.com/intent/tweet?url=$updatedUrl&text=$updatedMessage";
    print(link);
    setState(() {
      twitter_text.text = link;
    });
    return link;
  }

  String _generateLinkedIn({url, message}) {
    String updatedMessage = message.toString().replaceAll(" ", "%20");
    String updatedUrl = url.toString().replaceAll(":", "%3A");
    updatedUrl = updatedUrl.toString().replaceAll("/", "%2F");
    updatedUrl = updatedUrl.toString().replaceAll("#", "%23");
    String link =
        "https://www.linkedin.com/shareArticle?mini=true&url=$updatedUrl&summary=$updatedMessage";

    print(link);
    setState(() {
      linkedin_text.text = link;
    });
    return link;
  }

  String _generatePinterest({url, message}) {
    String updatedMessage = message.toString().replaceAll(" ", "%20");
    String updatedUrl = url.toString().replaceAll(":", "%3A");
    updatedUrl = updatedUrl.toString().replaceAll("/", "%2F");
    updatedUrl = updatedUrl.toString().replaceAll("#", "%23");
    String link =
        "http://pinterest.com/pin/create/button/?url=$updatedUrl&media=&description=$updatedMessage";
    print(link);
    setState(() {
      pinterest_text.text = link;
    });
    return link;
  }

  String _generateTumblr({url, message}) {
    String updatedMessage = message.toString().replaceAll(" ", "%20");
    String updatedUrl = url.toString().replaceAll(":", "%3A");
    updatedUrl = updatedUrl.toString().replaceAll("/", "%2F");
    updatedUrl = updatedUrl.toString().replaceAll("#", "%23");
    String link =
        "http://www.tumblr.com/share?v=3&u=$updatedUrl&t=$updatedMessage";
    print(link);
    setState(() {
      tumblr_text.text = link;
    });
    return link;
  }

  String _generateWhatsapp({message, phone}) {
    String updatedMessage = message.toString().replaceAll(" ", "%20");
    String updatedPhone = phone.toString().replaceAll(" ", "");

    String link =
        "https://api.whatsapp.com/send?phone=$updatedPhone&text=$updatedMessage";
    print(link);
    setState(() {
      whatsapp_text.text = link;
    });
    return link;
  }

  generateURLS() {
    String url = url_text.text.trim();
    String message = message_text.text.trim();
    String phone = phone_text.text.trim();
    _generateFacebook(url: url);
    _generateTwitter(url: url, message: message);
    _generateLinkedIn(url: url, message: message);
    _generatePinterest(url: url, message: message);
    _generateTumblr(url: url, message: message);
    _generateWhatsapp(message: message, phone: phone);
    FocusScope.of(context).requestFocus(FocusNode());
  }

  clearBox(TextEditingController controller) {
    setState(() {
      controller.text = "";
    });
  }

  copyToClipboard(TextEditingController controller) {
    if (!controller.text.isEmpty) {
      Clipboard.setData(new ClipboardData(text: controller.text));
      Toast.show("Link copied to clipboard", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(

      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8.0),
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                child: TextFormField(
                  controller: message_text,
                  decoration: InputDecoration(
                      hintText: 'Message ',
                      filled: true,
                      prefixIcon: Icon(
                        Icons.text_fields,
//                      size: 28.0,
                      ),
                      suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            clearBox(message_text);
                          })),
                ),
              ),
              Container(
                child: TextFormField(
                  controller: url_text,
                  decoration: InputDecoration(
                      hintText: 'Link URL',
                      filled: true,
                      prefixIcon: Icon(
                        Icons.link,
//                      size: 28.0,
                      ),
                      suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            clearBox(url_text);
                          })),
                ),
              ),
              Container(
                child: TextFormField(
                  controller: phone_text,
                  decoration: InputDecoration(
                      hintText: 'Phone number for whatsapp link',
                      filled: true,
                      prefixIcon: Icon(
                        Icons.phone,
//                      size: 28.0,
                      ),
                      suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            clearBox(phone_text);
                          })),
                ),
              ),
              RaisedButton(
                  color: Colors.green,
                  onPressed: generateURLS,
                  child: Text(
                    'Generate Links',
                  )),
              TextField(
                onTap: () {
                  copyToClipboard(facebook_text);
                },
                controller: facebook_text,
                readOnly: true,
                decoration: InputDecoration(
                  icon: Icon(
                    Custom.facebook,
                    color: Colors.blue,
                  ),
                  labelText: 'Facebook',
                  suffixIcon: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        Share.share(facebook_text.text);
                      }),
                ),
              ),
              TextField(
                controller: twitter_text,
                onTap: () {
                  copyToClipboard(twitter_text);
                },
                readOnly: true,
                decoration: InputDecoration(
                  icon: Icon(
                    Custom.twitter,
                    color: Colors.lightBlueAccent,
                  ),
                  labelText: 'Twitter',
                  suffixIcon: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        Share.share(twitter_text.text);
                      }),
                ),
              ),

              TextField(
                controller: linkedin_text,
                onTap: () {
                  copyToClipboard(linkedin_text);
                },
                readOnly: true,
                decoration: InputDecoration(
                  icon: Icon(
                    Custom.linkedin_squared,
                    color: Colors.blueAccent,
                  ),
                  labelText: 'LinkedIn',
                  suffixIcon: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        Share.share(linkedin_text.text);
                      }),
                ),
              ),
              TextField(
                controller: whatsapp_text,
                onTap: () {
                  copyToClipboard(whatsapp_text);
                },
                readOnly: true,
                decoration: InputDecoration(
                  icon: Icon(Custom.whatsapp, color: Colors.green),
                  labelText: 'Whatsapp',
                  suffixIcon: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        Share.share(whatsapp_text.text);
                      }),
                ),
              ),
              TextField(
                controller: pinterest_text,
                onTap: () {
                  copyToClipboard(pinterest_text);
                },
                readOnly: true,
                decoration: InputDecoration(
                  icon: Icon(
                    Custom.pinterest,
                    color: Colors.red,
                  ),
                  labelText: 'Pinterest',
                  suffixIcon: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        Share.share(pinterest_text.text);
                      }),
                ),
              ),
              TextField(
                controller: tumblr_text,
                onTap: () {
                  copyToClipboard(tumblr_text);
                },
                readOnly: true,
                decoration: InputDecoration(
                  icon: Icon(Custom.tumblr, color: Colors.blueGrey),
                  labelText: 'Tumblr',
                  suffixIcon: IconButton(
                      icon: Icon(Icons.share),
                      onPressed: () {
                        Share.share(tumblr_text.text);
                      }),
                ),
              ),

//              TextField(
//                controller: email_text,
//                onTap: () {
//                  copyToClipboard(whatsapp_text);
//                },
//                readOnly: true,
//                decoration: InputDecoration(
//                  icon: Icon(Icons.email, color: Colors.green),
//                  labelText: 'email',
//                  suffixIcon: IconButton(
//                      icon: Icon(Icons.share),
//                      onPressed: () {
//                        Share.share(email_text.text);
//                      }),
//                ),
//              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              // return object of type Dialog
              return AlertDialog(
                title: new Text("How to use this application"),
                content: new Text(
                    "To use the application paste or type a message, an URL and a phone number. Then press Generate Links button.\n"
                        "\nYou can click the generated URLs to copy or press the share button to share with other applications.\n\n"
                        "\nFacebook URL can embed a link."
                        "\nTwitter URL can embed a message."
                        "\nLinkedIn URL can embead link and a message"
                        "\nWhatsApp URL can embead message and a phone number"
                        "\nPinterest URL can embead a link and a message"
                        "\nTumblr URL can embead a link and a message",
                    textAlign: TextAlign.center),
                actions: <Widget>[
                  // usually buttons at the bottom of the dialog
                  new FlatButton(
                    child: new Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.help),
        backgroundColor: Colors.green,
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
