// lib/tax/regions.dart — the regions a bill can name as its place of supply.
//
// WHY THIS FILE EXISTS
//
// "Place of supply" was a picker of twenty Indian states, shown to
// everybody. A shop in Albania picking where it had sold something was
// offered Tamil Nadu and West Bengal, which is not a cosmetic problem:
// the field prints on the invoice.
//
// WHAT THESE ARE, AND HOW MUCH TO TRUST THEM
//
// First-level administrative divisions — states, provinces, regions,
// counties, emirates. Unlike the rates in rate_table.dart these are
// reference data rather than law: they change rarely, and a wrong one
// is a typo on a document rather than a tax liability. They are still
// not verified against any official source, and some countries have
// genuinely contested or recently reorganised divisions.
//
// INDIA IS NOT HERE ON PURPOSE
//
// India's list lives in models.dart as kStates, because each entry
// carries the GST state code — 'Tamil Nadu (33)' — and GSTR-1,
// gstr1_builder.dart and the intra/inter-state split all parse that
// code out of the string. Duplicating it here would create two lists
// that could disagree about a number the tax return depends on.
//
// A COUNTRY NOT IN THIS TABLE IS NOT BROKEN
//
// It gets a free-text field instead of a picker. That is the same
// choice this codebase makes everywhere it lacks data: offer the
// shopkeeper a box rather than a list of somebody else's regions. Most
// countries do not split tax by region at all, so for them the field
// is a location on a document and nothing more.
//
// ADDING A COUNTRY: add a row below. The format is
//   code|Region;Region;Region
// and the test asserts the shape, uniqueness and sorting.

const String _regions = '''
AE|Abu Dhabi;Ajman;Dubai;Fujairah;Ras Al Khaimah;Sharjah;Umm Al Quwain
AL|Berat;Dibër;Durrës;Elbasan;Fier;Gjirokastër;Korçë;Kukës;Lezhë;Shkodër;Tirana;Vlorë
AR|Buenos Aires;Buenos Aires City;Catamarca;Chaco;Chubut;Corrientes;Córdoba;Entre Ríos;Formosa;Jujuy;La Pampa;La Rioja;Mendoza;Misiones;Neuquén;Río Negro;Salta;San Juan;San Luis;Santa Cruz;Santa Fe;Santiago del Estero;Tierra del Fuego;Tucumán
AT|Burgenland;Carinthia;Lower Austria;Salzburg;Styria;Tyrol;Upper Austria;Vienna;Vorarlberg
AU|Australian Capital Territory;New South Wales;Northern Territory;Queensland;South Australia;Tasmania;Victoria;Western Australia
BD|Barisal;Chittagong;Dhaka;Khulna;Mymensingh;Rajshahi;Rangpur;Sylhet
BE|Antwerp;Brussels;East Flanders;Flemish Brabant;Hainaut;Limburg;Liège;Luxembourg;Namur;Walloon Brabant;West Flanders
BR|Acre;Alagoas;Amapá;Amazonas;Bahia;Ceará;Distrito Federal;Espírito Santo;Goiás;Maranhão;Mato Grosso;Mato Grosso do Sul;Minas Gerais;Paraná;Paraíba;Pará;Pernambuco;Piauí;Rio Grande do Norte;Rio Grande do Sul;Rio de Janeiro;Rondônia;Roraima;Santa Catarina;Sergipe;São Paulo;Tocantins
CA|Alberta;British Columbia;Manitoba;New Brunswick;Newfoundland and Labrador;Northwest Territories;Nova Scotia;Nunavut;Ontario;Prince Edward Island;Quebec;Saskatchewan;Yukon
CH|Aargau;Appenzell Ausserrhoden;Appenzell Innerrhoden;Basel-Landschaft;Basel-Stadt;Bern;Fribourg;Geneva;Glarus;Graubünden;Jura;Lucerne;Neuchâtel;Nidwalden;Obwalden;Schaffhausen;Schwyz;Solothurn;St. Gallen;Thurgau;Ticino;Uri;Valais;Vaud;Zug;Zurich
CL|Antofagasta;Araucanía;Arica y Parinacota;Atacama;Aysén;Biobío;Coquimbo;Los Lagos;Los Ríos;Magallanes;Maule;O'Higgins;Santiago;Tarapacá;Valparaíso;Ñuble
CN|Anhui;Beijing;Chongqing;Fujian;Gansu;Guangdong;Guangxi;Guizhou;Hainan;Hebei;Heilongjiang;Henan;Hong Kong;Hubei;Hunan;Inner Mongolia;Jiangsu;Jiangxi;Jilin;Liaoning;Macau;Ningxia;Qinghai;Shaanxi;Shandong;Shanghai;Shanxi;Sichuan;Tianjin;Tibet;Xinjiang;Yunnan;Zhejiang
CO|Amazonas;Antioquia;Arauca;Atlántico;Bogotá;Bolívar;Boyacá;Caldas;Caquetá;Casanare;Cauca;Cesar;Chocó;Cundinamarca;Córdoba;Guainía;Guaviare;Huila;La Guajira;Magdalena;Meta;Nariño;Norte de Santander;Putumayo;Quindío;Risaralda;San Andrés;Santander;Sucre;Tolima;Valle del Cauca;Vaupés;Vichada
DE|Baden-Württemberg;Bavaria;Berlin;Brandenburg;Bremen;Hamburg;Hesse;Lower Saxony;Mecklenburg-Vorpommern;North Rhine-Westphalia;Rhineland-Palatinate;Saarland;Saxony;Saxony-Anhalt;Schleswig-Holstein;Thuringia
DK|Capital Region;Central Denmark;North Denmark;Region Zealand;Southern Denmark
EG|Alexandria;Aswan;Asyut;Beheira;Beni Suef;Cairo;Dakahlia;Damietta;Faiyum;Gharbia;Giza;Ismailia;Kafr El Sheikh;Luxor;Matrouh;Minya;Monufia;New Valley;North Sinai;Port Said;Qalyubia;Qena;Red Sea;Sharqia;Sohag;South Sinai;Suez
ES|Andalusia;Aragon;Asturias;Balearic Islands;Basque Country;Canary Islands;Cantabria;Castile and León;Castilla-La Mancha;Catalonia;Ceuta;Extremadura;Galicia;La Rioja;Madrid;Melilla;Murcia;Navarre;Valencia
FI|Central Finland;Central Ostrobothnia;Kainuu;Kanta-Häme;Kymenlaakso;Lapland;North Karelia;North Ostrobothnia;Northern Savonia;Ostrobothnia;Pirkanmaa;Päijät-Häme;Satakunta;South Karelia;South Ostrobothnia;Southern Savonia;Southwest Finland;Uusimaa;Åland
FR|Auvergne-Rhône-Alpes;Bourgogne-Franche-Comté;Bretagne;Centre-Val de Loire;Corse;Grand Est;Hauts-de-France;Normandie;Nouvelle-Aquitaine;Occitanie;Pays de la Loire;Provence-Alpes-Côte d'Azur;Île-de-France
GB|England;Northern Ireland;Scotland;Wales
GH|Ahafo;Ashanti;Bono;Bono East;Central;Eastern;Greater Accra;North East;Northern;Oti;Savannah;Upper East;Upper West;Volta;Western;Western North
GR|Attica;Central Greece;Central Macedonia;Crete;East Macedonia and Thrace;Epirus;Ionian Islands;North Aegean;Peloponnese;South Aegean;Thessaly;West Greece;West Macedonia
ID|Aceh;Bali;Banten;Bengkulu;Central Java;Central Kalimantan;Central Sulawesi;East Java;East Kalimantan;East Nusa Tenggara;Gorontalo;Jakarta;Jambi;Lampung;Maluku;North Kalimantan;North Maluku;North Sulawesi;North Sumatra;Papua;Riau;Riau Islands;South Kalimantan;South Sulawesi;South Sumatra;Southeast Sulawesi;West Java;West Kalimantan;West Nusa Tenggara;West Papua;West Sulawesi;West Sumatra;Yogyakarta
IE|Carlow;Cavan;Clare;Cork;Donegal;Dublin;Galway;Kerry;Kildare;Kilkenny;Laois;Leitrim;Limerick;Longford;Louth;Mayo;Meath;Monaghan;Offaly;Roscommon;Sligo;Tipperary;Waterford;Westmeath;Wexford;Wicklow
IL|Central;Haifa;Jerusalem;Northern;Southern;Tel Aviv
IT|Abruzzo;Aosta Valley;Apulia;Basilicata;Calabria;Campania;Emilia-Romagna;Friuli-Venezia Giulia;Lazio;Liguria;Lombardy;Marche;Molise;Piedmont;Sardinia;Sicily;Trentino-Alto Adige;Tuscany;Umbria;Veneto
JP|Aichi;Akita;Aomori;Chiba;Ehime;Fukui;Fukuoka;Fukushima;Gifu;Gunma;Hiroshima;Hokkaido;Hyogo;Ibaraki;Ishikawa;Iwate;Kagawa;Kagoshima;Kanagawa;Kochi;Kumamoto;Kyoto;Mie;Miyagi;Miyazaki;Nagano;Nagasaki;Nara;Niigata;Oita;Okayama;Okinawa;Osaka;Saga;Saitama;Shiga;Shimane;Shizuoka;Tochigi;Tokushima;Tokyo;Tottori;Toyama;Wakayama;Yamagata;Yamaguchi;Yamanashi
KE|Baringo;Bomet;Bungoma;Busia;Elgeyo-Marakwet;Embu;Garissa;Homa Bay;Isiolo;Kajiado;Kakamega;Kericho;Kiambu;Kilifi;Kirinyaga;Kisii;Kisumu;Kitui;Kwale;Laikipia;Lamu;Machakos;Makueni;Mandera;Marsabit;Meru;Migori;Mombasa;Murang'a;Nairobi;Nakuru;Nandi;Narok;Nyamira;Nyandarua;Nyeri;Samburu;Siaya;Taita-Taveta;Tana River;Tharaka-Nithi;Trans Nzoia;Turkana;Uasin Gishu;Vihiga;Wajir;West Pokot
KR|Busan;Chungbuk;Chungnam;Daegu;Daejeon;Gangwon;Gwangju;Gyeongbuk;Gyeonggi;Gyeongnam;Incheon;Jeju;Jeonbuk;Jeonnam;Sejong;Seoul;Ulsan
LK|Central;Eastern;North Central;North Western;Northern;Sabaragamuwa;Southern;Uva;Western
MA|Béni Mellal-Khénifra;Casablanca-Settat;Dakhla-Oued Ed-Dahab;Drâa-Tafilalet;Fès-Meknès;Guelmim-Oued Noun;Laâyoune-Sakia El Hamra;Marrakesh-Safi;Oriental;Rabat-Salé-Kénitra;Souss-Massa;Tanger-Tetouan-Al Hoceima
MX|Aguascalientes;Baja California;Baja California Sur;Campeche;Chiapas;Chihuahua;Coahuila;Colima;Durango;Guanajuato;Guerrero;Hidalgo;Jalisco;Mexico City;Michoacán;Morelos;México;Nayarit;Nuevo León;Oaxaca;Puebla;Querétaro;Quintana Roo;San Luis Potosí;Sinaloa;Sonora;Tabasco;Tamaulipas;Tlaxcala;Veracruz;Yucatán;Zacatecas
MY|Johor;Kedah;Kelantan;Kuala Lumpur;Labuan;Melaka;Negeri Sembilan;Pahang;Penang;Perak;Perlis;Putrajaya;Sabah;Sarawak;Selangor;Terengganu
NG|Abia;Adamawa;Akwa Ibom;Anambra;Bauchi;Bayelsa;Benue;Borno;Cross River;Delta;Ebonyi;Edo;Ekiti;Enugu;Federal Capital Territory;Gombe;Imo;Jigawa;Kaduna;Kano;Katsina;Kebbi;Kogi;Kwara;Lagos;Nasarawa;Niger;Ogun;Ondo;Osun;Oyo;Plateau;Rivers;Sokoto;Taraba;Yobe;Zamfara
NL|Drenthe;Flevoland;Friesland;Gelderland;Groningen;Limburg;North Brabant;North Holland;Overijssel;South Holland;Utrecht;Zeeland
NO|Agder;Akershus;Buskerud;Finnmark;Innlandet;Møre og Romsdal;Nordland;Oslo;Rogaland;Telemark;Troms;Trøndelag;Vestfold;Vestland;Østfold
NP|Bagmati;Gandaki;Karnali;Koshi;Lumbini;Madhesh;Sudurpashchim
NZ|Auckland;Bay of Plenty;Canterbury;Gisborne;Hawke's Bay;Manawatu-Whanganui;Marlborough;Nelson;Northland;Otago;Southland;Taranaki;Tasman;Waikato;Wellington;West Coast
PE|Amazonas;Apurímac;Arequipa;Ayacucho;Cajamarca;Callao;Cusco;Huancavelica;Huánuco;Ica;Junín;La Libertad;Lambayeque;Lima;Loreto;Madre de Dios;Moquegua;Pasco;Piura;Puno;San Martín;Tacna;Tumbes;Ucayali;Áncash
PH|Bangsamoro;Bicol;Cagayan Valley;Calabarzon;Caraga;Central Luzon;Central Visayas;Cordillera;Davao;Eastern Visayas;Ilocos;Metro Manila;Mimaropa;Northern Mindanao;Soccsksargen;Western Visayas;Zamboanga Peninsula
PK|Azad Kashmir;Balochistan;Gilgit-Baltistan;Islamabad Capital Territory;Khyber Pakhtunkhwa;Punjab;Sindh
PL|Greater Poland;Holy Cross;Kuyavian-Pomeranian;Lesser Poland;Lower Silesian;Lublin;Lubusz;Masovian;Opole;Podlaskie;Pomeranian;Silesian;Subcarpathian;Warmian-Masurian;West Pomeranian;Łódź
PT|Aveiro;Azores;Beja;Braga;Bragança;Castelo Branco;Coimbra;Faro;Guarda;Leiria;Lisbon;Madeira;Portalegre;Porto;Santarém;Setúbal;Viana do Castelo;Vila Real;Viseu;Évora
RU|Bashkortostan;Chelyabinsk;Dagestan;Irkutsk;Kemerovo;Krasnodar;Krasnoyarsk;Moscow;Moscow Oblast;Nizhny Novgorod;Novosibirsk;Omsk;Perm;Primorsky;Rostov;Samara;Saratov;St. Petersburg;Stavropol;Sverdlovsk;Tatarstan;Tyumen;Volgograd;Voronezh
SA|Al Bahah;Al Jawf;Al Madinah;Al Qassim;Asir;Eastern Province;Hail;Jazan;Makkah;Najran;Northern Borders;Riyadh;Tabuk
SE|Blekinge;Dalarna;Gotland;Gävleborg;Halland;Jämtland;Jönköping;Kalmar;Kronoberg;Norrbotten;Skåne;Stockholm;Södermanland;Uppsala;Värmland;Västerbotten;Västernorrland;Västmanland;Västra Götaland;Örebro;Östergötland
SG|Central;East;North;North-East;West
TH|Bangkok;Central;Eastern;Northeastern;Northern;Southern;Western
TR|Adana;Ankara;Antalya;Bursa;Diyarbakır;Erzurum;Eskişehir;Gaziantep;Hatay;Kayseri;Kocaeli;Konya;Malatya;Manisa;Mersin;Samsun;Trabzon;Van;İstanbul;İzmir;Şanlıurfa
TZ|Arusha;Dar es Salaam;Dodoma;Geita;Iringa;Kagera;Katavi;Kigoma;Kilimanjaro;Lindi;Manyara;Mara;Mbeya;Morogoro;Mtwara;Mwanza;Njombe;Pwani;Rukwa;Ruvuma;Shinyanga;Simiyu;Singida;Songwe;Tabora;Tanga
UA|Cherkasy;Chernihiv;Chernivtsi;Dnipropetrovsk;Donetsk;Ivano-Frankivsk;Kharkiv;Kherson;Khmelnytskyi;Kirovohrad;Kyiv;Luhansk;Lviv;Mykolaiv;Odesa;Poltava;Rivne;Sumy;Ternopil;Vinnytsia;Volyn;Zakarpattia;Zaporizhzhia;Zhytomyr
UG|Central;Eastern;Northern;Western
US|Alabama;Alaska;Arizona;Arkansas;California;Colorado;Connecticut;Delaware;District of Columbia;Florida;Georgia;Hawaii;Idaho;Illinois;Indiana;Iowa;Kansas;Kentucky;Louisiana;Maine;Maryland;Massachusetts;Michigan;Minnesota;Mississippi;Missouri;Montana;Nebraska;Nevada;New Hampshire;New Jersey;New Mexico;New York;North Carolina;North Dakota;Ohio;Oklahoma;Oregon;Pennsylvania;Rhode Island;South Carolina;South Dakota;Tennessee;Texas;Utah;Vermont;Virginia;Washington;West Virginia;Wisconsin;Wyoming
VN|An Giang;Bac Ninh;Ca Mau;Can Tho;Cao Bang;Da Nang;Dak Lak;Dien Bien;Dong Nai;Dong Thap;Gia Lai;Ha Noi;Ha Tinh;Hai Phong;Ho Chi Minh City;Hue;Hung Yen;Khanh Hoa;Lai Chau;Lam Dong;Lang Son;Lao Cai;Nghe An;Ninh Binh;Phu Tho;Quang Ngai;Quang Ninh;Quang Tri;Son La;Tay Ninh;Thai Nguyen;Thanh Hoa;Tuyen Quang;Vinh Long
ZA|Eastern Cape;Free State;Gauteng;KwaZulu-Natal;Limpopo;Mpumalanga;North West;Northern Cape;Western Cape
''';

/// The regions of a country, or null where the table has no row.
///
/// Null is a working state, not a failure: the caller offers a
/// free-text field instead of a picker.
List<String>? regionsFor(String countryCode) => _table[countryCode.toUpperCase()];

/// Every country code the table covers.
Iterable<String> get regionTableCountries => _table.keys;

Map<String, List<String>>? _cache;

Map<String, List<String>> get _table {
  final cached = _cache;
  if (cached != null) return cached;
  final out = <String, List<String>>{};
  for (final line in _regions.split('\n')) {
    if (line.trim().isEmpty) continue;
    final i = line.indexOf('|');
    if (i < 0) continue;
    final code = line.substring(0, i).trim();
    final names = line
        .substring(i + 1)
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (code.length == 2 && names.isNotEmpty) out[code] = names;
  }
  return _cache = out;
}
