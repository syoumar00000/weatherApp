import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_weather/temperature.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http ;
import 'dart:convert';
import 'my_flutter_app_icons.dart';


/*void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);// met l'application uniquement en portrait
  runApp(MyApp());
}*/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Location location = new Location();
  LocationData position;
  try {
    position = (await location.getLocation()) ;
   print(position);
  } on PlatformException catch (e) {
    print("Erreur: $e");  }
    if (position != null) {
      final latitude = position.latitude;
      final longitude = position.longitude;
      final Coordinates coordinates = new Coordinates(latitude, longitude);
      final villes = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      if (villes != null) {
        print(villes.first.locality);
        runApp(new MyApp(villes.first.locality)); }
    }
}

class MyApp extends StatelessWidget {
  MyApp(String locality);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'My Weather'),
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
  String key = "villes";
  List<String> villes = [];
  String villeChoisie;
  Location location;
  Temperature temperature;
  LocationData locationData;
  Stream<LocationData> stream;
  Coordinates coordVilleChoisie;
  String nameCurrent = " Ville Actuelle";

  AssetImage night = AssetImage("assets/n.jpg");
  AssetImage sun = AssetImage("assets/d1.jpg");
  AssetImage rain = AssetImage("assets/d2.jpg");


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    obtenir();
    location =  new Location();//initialisation de la localisation
    //getFirstLocation();
    listenToStream();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      drawer: new Drawer(
        child: new Container(
          child: new ListView.builder(
              itemCount: villes.length + 2 ,
              itemBuilder: (context, i) {
                if (i == 0){
                  return DrawerHeader(
                    child: new Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        textAvecStyle("Mes Villes ", fontSize: 22.0,),
                        new RaisedButton(
                            color: Colors.white,
                            elevation: 8.0,
                            child: textAvecStyle("Ajoutez une Ville", color: Colors.blue),
                            onPressed: ajoutVille
                        ),
                      ],
                    ),
                  );
                }else if(i == 1) {
                  return new ListTile(
                    title: textAvecStyle(nameCurrent),
                    onTap: (){
                      setState(() {
                        villeChoisie = null;
                        coordVilleChoisie = null;
                        api();
                        Navigator.pop(context);
                      });
                    },
                  );
                } else {
                  String ville = villes[i - 2];
                  return new ListTile(
                    title: textAvecStyle(ville),
                    trailing: new IconButton(
                        icon: new Icon(Icons.delete, color: Colors.white,),
                        onPressed: (() => supprimer(ville))
                    ),
                    onTap: (){
                      setState(() {
                        villeChoisie = ville;
                        coordonneeDeLaVille();
                        Navigator.pop(context);//pour fermer le drawer lors du clique sur une ville
                      });
                    },
                  );
                }
              }),
          color: Colors.blue,
        ),
      ),
      body: (temperature == null)? new Center(child: new Text((villeChoisie == null)? nameCurrent: villeChoisie),)
          : Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: new BoxDecoration(
          image: new DecorationImage(image: getBackground(), fit: BoxFit.cover)
        ),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            textAvecStyle((villeChoisie == null)? nameCurrent : villeChoisie, fontSize: 40.0,fontStyle: FontStyle.italic),
            textAvecStyle(temperature.description, fontSize: 30.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Image(image: getIcon()),
                textAvecStyle("${temperature.temp.toInt()} °C", fontSize: 65.0),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                extra("${temperature.min.toInt()} °C", MyFlutterApp.up),
                extra("${temperature.max.toInt()} °C", MyFlutterApp.down),
                extra("${temperature.pressure.toInt()}", MyFlutterApp.temperatire),
                extra("${temperature.humidity.toInt()}%", MyFlutterApp.drizzle),
              ],
            ),
          ],
        ),
      )
    );
  }

  Column extra(String data, IconData iconData){
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Icon(iconData, color: Colors.white, size: 32.0,),
        textAvecStyle(data),
      ],
    );
  }

  //fonction texte avec su style pour eviter des repetitions de code
  Text textAvecStyle(String data, {color: Colors.white, fontSize:20.0, fontStyle: FontStyle.italic, textAlign: TextAlign.center}){
    return new Text(
      data,
      textAlign: textAlign,
      style: new TextStyle(
        color: color,
        fontStyle: fontStyle,
        fontSize: fontSize,
      ),
    );
  }
  Future<Null> ajoutVille() async {
    return showDialog(
        barrierDismissible: true,
        builder: (BuildContext buildcontext) {
          return new SimpleDialog(
            contentPadding: EdgeInsets.all(20.0),
            title: textAvecStyle("Ajouter une Ville", fontSize: 22.0, color: Colors.blue),
            children: <Widget>[
              new TextField(
                decoration: new InputDecoration(
                    labelText: "Ville: "
                ),
                onSubmitted: (String str){
                  ajouter(str);
                  Navigator.pop(buildcontext);
                },
              ),
            ],
          );
        },
        context: context
    );
  }
  // mes shared preferences
  void obtenir() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> liste = await sharedPreferences.getStringList(key);
    if(liste != null){
      setState(() {
        villes = liste;
      });
    }
  }
  void ajouter(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    villes.add(str);
    await sharedPreferences.setStringList(key, villes);
    obtenir();
   
  }
  void supprimer(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    villes.remove(str);
    await sharedPreferences.setStringList(key, villes);
    obtenir();
  }

  AssetImage getIcon() {
    String icon = temperature.icon.replaceAll('d', '').replaceAll('n', '');
    return AssetImage("assets/$icon.png");
  }

  AssetImage getBackground() {
    print(temperature.icon);
    if(temperature.icon.contains("n")){
      return night;
    } else {
      if((temperature.icon.contains("01")) || (temperature.icon.contains("02")) || (temperature.icon.contains("03"))) {
        return sun;
      } else {
        return rain;
      }
    }
  }


  //Location
  // avoir la position une fois
  getFirstLocation() async {
    try {
      locationData = await location.getLocation();
      print("nouvelle position: ${locationData.latitude} / ${locationData.longitude}");
      locationToStringVille();
    } catch (e) {
      print("we have a mistake: $e");
    }
  }
  // avoir la position a chaque changement(quand l'on se deplace)
  listenToStream() {
    stream = location.onLocationChanged;
    stream .listen((newPosition) {
      if((locationData == null) ||(newPosition.longitude == locationData.longitude) && (newPosition.latitude == locationData.latitude)) {
        setState(() {
          print("New => ${newPosition.latitude} ----- ${newPosition.longitude}");
          locationData = newPosition;
          locationToStringVille();
        });
      }
    });
  }

  //Geocoder
  // localisation pour avoir la ville
locationToStringVille() async {
    if(locationData != null){
      Coordinates coordinates = new Coordinates(locationData.latitude, locationData.longitude);
      final cityName = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      setState(() {
        nameCurrent = cityName.first.locality;
        api();
      });
     // print(cityName.first.locality);
    }
}
//transformer le nom de la ville par ses coordonnees
coordonneeDeLaVille() async {
    if(villeChoisie != null){
      List<Address> addresses = await Geocoder.local.findAddressesFromQuery(villeChoisie);
      if(addresses.length > 0){
        Address first = addresses.first;
        Coordinates coords = first.coordinates;
        setState(() {
          coordVilleChoisie = coords;
         // print(coordVilleChoisie);
          api();
        });
      }
    }
}

 api() async {
    double lat;
    double lon;
    if(coordVilleChoisie != null){
      lat = coordVilleChoisie.latitude;
      lon = coordVilleChoisie.longitude;
    } else if(locationData != null){
      lat = locationData.latitude;
      lon = locationData.longitude;
    }

    if(lat != null && lon != null ){
      final key = "&APPID=928de42c510e44b1812926abb8f6a379";
      String lang = "&lang=${Localizations.localeOf(context).languageCode}";
      String baseAPI = "http://api.openweathermap.org/data/2.5/weather?";
      String coordsString = "lat=$lat&lon=$lon";
      String units = "&units=metric";
      String totalString = baseAPI + coordsString + units + lang + key;
      final response = await http.get(totalString);
      if(response.statusCode == 200){
        Map map = json.decode(response.body);
        setState(() {
          temperature = Temperature(map);
          print(temperature.description);
        });
      }
    }
 }
  
}
