import 'package:device_id/device_id.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oxit_booqe_app/main.dart';
import 'package:oxit_booqe_app/models/Post.dart';
import 'package:oxit_booqe_app/register_view/login.dart';
import 'package:oxit_booqe_app/services/auth_methods.dart';
import 'package:oxit_booqe_app/services/blog_methods.dart';
import 'package:oxit_booqe_app/single_post_screen.dart';

import 'widgets.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/Menu.dart';

const String testDevice = 'YOUR_DEVICE_ID';

class LatestPostsScreen extends StatefulWidget {
  static const title = 'News';
  static const androidIcon = Icon(Icons.library_books);
  static const iosIcon = Icon(CupertinoIcons.news);

  @override
  _LatestPostsScreenState createState() => _LatestPostsScreenState();
}

class _LatestPostsScreenState extends State<LatestPostsScreen> {
  BlogMethods blogMethods = new BlogMethods();

  static MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    keywords: <String>['flutterio', 'beautiful apps'],
    contentUrl: 'https://flutter.io',

    childDirected: false,

    testDevices: <String>[
      //"f23b6a44a06957b4"
    ], // Android emulators are considered test devices
  );

  final NativeAd nativeAd = NativeAd(
    adUnitId: NativeAd.testAdUnitId,
    factoryId: 'adFactoryExample',
    targetingInfo: targetingInfo,
    listener: (MobileAdEvent event) {
      print("$NativeAd event $event");
    },
  );

  String deviceID;

  void getDeviceID() async {
    String deviceId = await DeviceId.getID;
    deviceID = 'Device ID is $deviceId';
    print('Device ID is $deviceId');

    FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    String token = await _firebaseMessaging.getToken();
    print('x' + token);
  }

  String colorIcon = 'build/assets/icons/strawberry_color.png';
  String icon = 'build/assets/icons/strawberry.png';

  static const _adUnitID = "ca-app-pub-3940256099942544/2247696110";

  List<Color> colors;
  List<String> titles;
  List<String> contents;
  List<dynamic> menus = new List<dynamic>();
  Future<List<Post>> posts;
  List<Post> posts1;

  BannerAd _bannerAd;
  NativeAd _nativeAd;
  InterstitialAd _interstitialAd;

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: BannerAd.testAdUnitId,
      size: AdSize.banner,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("BannerAd event $event");
      },
    );
  }

  InterstitialAd createInterstitialAd() {
    return InterstitialAd(
      adUnitId: InterstitialAd.testAdUnitId,
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("InterstitialAd event $event");
      },
    );
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  List<Menu> parseMenu(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();

    return parsed.map<Menu>((json) => Menu.fromJson(json)).toList();
  }

  Future<List<Post>> fetchPost() async {
    String aToken = await storage.read(key: 'access');

    final response =
        await http.get(SERVER_IP + '/booqe/blogs-api-get/', headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $aToken',
    });

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      List jsonResponse = jsonDecode(Utf8Decoder().convert(response.bodyBytes));
      posts1 = jsonResponse.map((post) => new Post.fromJson(post)).toList();
      //return jsonResponse.map((post) => new Post.fromJson(post)).toList();
      return posts1;
    } else if (response.statusCode == 401) {
      AuthMethods authMethods = new AuthMethods();
      int status = await authMethods.refreshToken();

      if (status == 200) {
        fetchPost();
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  void showAdd() async {
    String addValue = await storage.read(key: "mainAdd");

    if (int.parse(addValue) % 3 == 0) {
      FirebaseAdMob.instance.initialize(appId: FirebaseAdMob.testAppId);
      _interstitialAd = createInterstitialAd()
        ..load()
        ..show();
    }

    int x = int.parse(addValue) + 1;
    print(x);

    storage.write(key: "mainAdd", value: x.toString());
  }

  @override
  void initState() {
    //FirebaseAdMob.instance.initialize(appId: FirebaseAdMob.testAppId);
    posts = this.fetchPost();
    //print(menus.length);
    //colors = getRandomColors(_itemsLength);
    //titles = List.generate(_itemsLength, (index) => generateRandomHeadline());
    //contents =
    //  List.generate(_itemsLength, (index) => lorem(paragraphs: 1, words: 24));
    super.initState();
    getDeviceID();
    showAdd();

    /* _bannerAd ??= createBannerAd();
                      _bannerAd
                        ..load()
                        ..show(horizontalCenterOffset: -50, anchorOffset: 100, anchorType: AnchorType.top,);*/
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  ListView _postList(data) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (BuildContext context, int index) {
          int x = index + 1;

          return Container(
              child: SafeArea(
            top: false,
            bottom: false,
            child: Card(
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SinglePostsScreen(
                              blogId: data[index].id.toString())));
                },
                child: Container(
                    width: 500,
                    child: Column(
                      children: <Widget>[
                        Image.network(data[index].postImage,
                            color: Color.fromRGBO(255, 255, 255, 1),
                            colorBlendMode: BlendMode.modulate),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: <Widget>[
                                IconButton(
                                  alignment: Alignment.topLeft,
                                  icon: data[index].pin
                                      ? Image.asset(
                                          "lib/assets/icons/strawberry_color.png")
                                      : Image.asset(
                                          "lib/assets/icons/strawberry.png"),
                                  tooltip: 'Increase volume by 10',
                                  onPressed: () async {
                                    int status = await blogMethods
                                        .pinBlog(data[index].id);

                                    if (status == 200) {
                                      data[index].setPin(blogMethods
                                          .isTrueOrIsFalse(data[index].pin));

                                      setState(() {
                                        //data[index].pin = blogMethods.isTrueOrIsFalse(data[index].pin);
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  alignment: Alignment.topLeft,
                                  icon: Image.asset("lib/assets/icons/eye.png"),
                                  
                                  onPressed: () async {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SinglePostsScreen(
                                                    blogId: data[index]
                                                        .id
                                                        .toString())));
                                  },
                                )
                              ],
                            )),
                        Divider(
                          height: 24.0,
                          indent: 10,
                          color: Colors.black26,
                        ),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                                margin: const EdgeInsets.all(3.0),
                                padding: const EdgeInsets.all(3.0),
                                width: 500.0,
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(255, 255, 255, 0.4),
                                ),
                                child: Row(children: <Widget>[
                                  Flexible(
                                      child: RichText(
                                    text: new TextSpan(
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
                                      style: new TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black,
                                      ),
                                      children: <TextSpan>[
                                        new TextSpan(
                                            text: data[index].title,
                                            style: new TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        new TextSpan(
                                            text: data[index].description),
                                      ],
                                    ),
                                  )),
                                ]))),
                      ],
                    )),
              ),
            ),
          ));
        });
  }

  /**Widget _listBuilder(BuildContext context, int index) {
    if (index >= menus.length) return null;

    return SafeArea(
      top: false,
      bottom: false,
      child: Card(
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () {
            print('Card tapped.');
          },
          child: Container(
              width: 500,
              height: 550,
              child: Column(
                children: <Widget>[
                  Image.network(
                      'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
                      color: Color.fromRGBO(255, 255, 255, 1),
                      colorBlendMode: BlendMode.modulate),
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      alignment: Alignment.topLeft,
                      icon: like
                          ? Image.asset(
                              "build/assets/icons/strawberry_color.png")
                          : Image.asset("build/assets/icons/strawberry.png"),
                      tooltip: 'Increase volume by 10',
                      onPressed: () {
                        setState(() {
                          if (like) {
                            like = false;
                          } else {
                            like = true;
                          }
                        });
                      },
                    ),
                  ),
                  Divider(
                    height: 24.0,
                    indent: 10,
                    color: Colors.black26,
                  ),
                  Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                          margin: const EdgeInsets.all(3.0),
                          padding: const EdgeInsets.all(3.0),
                          width: 500.0,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.4),
                          ),
                          child: Row(children: <Widget>[
                            Flexible(
                                child: RichText(
                              text: new TextSpan(
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
                                style: new TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  new TextSpan(
                                      text: 'World ',
                                      style: new TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  new TextSpan(
                                      text:
                                          'Hello Hello Hello Hello Hello Hello Hello Hello Hello Hello'),
                                ],
                              ),
                            )),
                          ]))),
                ],
              )),
        ),
      ),
    );
  }**/

  // ===========================================================================
  // Non-shared code below because this tab uses different scaffolds.
  // ===========================================================================

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Booqe',
              textAlign: TextAlign.center, style: GoogleFonts.lora()),
          backgroundColor: Colors.white,
        ),
        body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () async {
              setState(() {
                posts = fetchPost();
              });
            },
            child: Container(
                color: Colors.grey[100],
                child: Container(
                  color: Colors.white,
                  child: FutureBuilder<List<Post>>(
                    future: posts,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        List<Post> data = snapshot.data;
                        return _postList(data);
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ))));
  }

  Widget _buildIos(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("BOOQE", style: GoogleFonts.lora()),
      ),
      child: Container(
          color: Colors.grey[100],
          child: Container(
            color: Colors.white,
            child: FutureBuilder<List<Post>>(
              future: posts,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Post> data = snapshot.data;
                  return _postList(data);
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          )),
    );
  }

  @override
  Widget build(context) {
    return PlatformWidget(
      androidBuilder: _buildAndroid,
      iosBuilder: _buildIos,
    );
  }
}
