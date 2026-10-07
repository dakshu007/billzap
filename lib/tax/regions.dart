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
// Four of the 177 are deliberately absent, and that is a decision
// rather than a gap: Gibraltar, Monaco, Macao and Vatican City are
// single-settlement jurisdictions. Asking which region of Vatican City
// a sale happened in is not a question, so the field is free text
// there and a shopkeeper can write a street if they want one.
//
// ADDING A COUNTRY: add a row below. The format is
//   code|Region;Region;Region
// and the test asserts the shape, uniqueness and sorting.

const String _regions = '''
AE|Abu Dhabi;Ajman;Dubai;Fujairah;Ras Al Khaimah;Sharjah;Umm Al Quwain
AG|Barbuda;Redonda;Saint George;Saint John;Saint Mary;Saint Paul;Saint Peter;Saint Philip
AL|Berat;Dibër;Durrës;Elbasan;Fier;Gjirokastër;Korçë;Kukës;Lezhë;Shkodër;Tirana;Vlorë
AM|Aragatsotn;Ararat;Armavir;Gegharkunik;Kotayk;Lori;Shirak;Syunik;Tavush;Vayots Dzor;Yerevan
AO|Bengo;Benguela;Bie;Cabinda;Cuando Cubango;Cuanza Norte;Cuanza Sul;Cunene;Huambo;Huila;Luanda;Lunda Norte;Lunda Sul;Malanje;Moxico;Namibe;Uige;Zaire
AR|Buenos Aires;Buenos Aires City;Catamarca;Chaco;Chubut;Corrientes;Córdoba;Entre Ríos;Formosa;Jujuy;La Pampa;La Rioja;Mendoza;Misiones;Neuquén;Río Negro;Salta;San Juan;San Luis;Santa Cruz;Santa Fe;Santiago del Estero;Tierra del Fuego;Tucumán
AT|Burgenland;Carinthia;Lower Austria;Salzburg;Styria;Tyrol;Upper Austria;Vienna;Vorarlberg
AU|Australian Capital Territory;New South Wales;Northern Territory;Queensland;South Australia;Tasmania;Victoria;Western Australia
AW|Noord;Oranjestad;Paradera;San Nicolas;Santa Cruz;Savaneta;Tanki Leendert
AZ|Absheron;Baku;Ganja;Lankaran;Mingachevir;Nakhchivan;Shaki;Shirvan;Sumqayit;Yevlakh
BA|Brcko District;Federation of Bosnia and Herzegovina;Republika Srpska
BD|Barisal;Chittagong;Dhaka;Khulna;Mymensingh;Rajshahi;Rangpur;Sylhet
BE|Antwerp;Brussels;East Flanders;Flemish Brabant;Hainaut;Limburg;Liège;Luxembourg;Namur;Walloon Brabant;West Flanders
BF|Boucle du Mouhoun;Cascades;Centre;Centre-Est;Centre-Nord;Centre-Ouest;Centre-Sud;Est;Hauts-Bassins;Nord;Plateau-Central;Sahel;Sud-Ouest
BG|Blagoevgrad;Burgas;Dobrich;Gabrovo;Haskovo;Kardzhali;Kyustendil;Lovech;Montana;Pazardzhik;Pernik;Pleven;Plovdiv;Razgrad;Ruse;Shumen;Silistra;Sliven;Smolyan;Sofia;Sofia City;Stara Zagora;Targovishte;Varna;Veliko Tarnovo;Vidin;Vratsa;Yambol
BH|Capital;Muharraq;Northern;Southern
BJ|Alibori;Atacora;Atlantique;Borgou;Collines;Couffo;Donga;Littoral;Mono;Oueme;Plateau;Zou
BM|Devonshire;Hamilton;Hamilton City;Paget;Pembroke;Saint George;Saint George's;Sandys;Smith's;Southampton;Warwick
BO|Beni;Chuquisaca;Cochabamba;La Paz;Oruro;Pando;Potosi;Santa Cruz;Tarija
BR|Acre;Alagoas;Amapá;Amazonas;Bahia;Ceará;Distrito Federal;Espírito Santo;Goiás;Maranhão;Mato Grosso;Mato Grosso do Sul;Minas Gerais;Paraná;Paraíba;Pará;Pernambuco;Piauí;Rio Grande do Norte;Rio Grande do Sul;Rio de Janeiro;Rondônia;Roraima;Santa Catarina;Sergipe;São Paulo;Tocantins
BS|Acklins;Andros;Berry Islands;Bimini;Cat Island;Crooked Island;Eleuthera;Exuma;Freeport;Grand Bahama;Harbour Island;Inagua;Long Island;Mayaguana;Nassau;New Providence;Ragged Island;Rum Cay;San Salvador;Spanish Wells
BW|Central;Chobe;Francistown;Gaborone;Ghanzi;Kgalagadi;Kgatleng;Kweneng;North East;North West;South East;Southern
BY|Brest;Gomel;Grodno;Minsk;Minsk City;Mogilev;Vitebsk
BZ|Belize;Cayo;Corozal;Orange Walk;Stann Creek;Toledo
CA|Alberta;British Columbia;Manitoba;New Brunswick;Newfoundland and Labrador;Northwest Territories;Nova Scotia;Nunavut;Ontario;Prince Edward Island;Quebec;Saskatchewan;Yukon
CD|Bas-Uele;Equateur;Haut-Katanga;Haut-Lomami;Haut-Uele;Ituri;Kasai;Kasai-Central;Kasai-Oriental;Kinshasa;Kongo-Central;Kwango;Kwilu;Lomami;Lualaba;Mai-Ndombe;Maniema;Mongala;Nord-Kivu;Nord-Ubangi;Sankuru;Sud-Kivu;Sud-Ubangi;Tanganyika;Tshopo;Tshuapa
CG|Bouenza;Brazzaville;Cuvette;Cuvette-Ouest;Kouilou;Lekoumou;Likouala;Niari;Plateaux;Pointe-Noire;Pool;Sangha
CH|Aargau;Appenzell Ausserrhoden;Appenzell Innerrhoden;Basel-Landschaft;Basel-Stadt;Bern;Fribourg;Geneva;Glarus;Graubünden;Jura;Lucerne;Neuchâtel;Nidwalden;Obwalden;Schaffhausen;Schwyz;Solothurn;St. Gallen;Thurgau;Ticino;Uri;Valais;Vaud;Zug;Zurich
CI|Abidjan;Bas-Sassandra;Comoe;Denguele;Goh-Djiboua;Lacs;Lagunes;Montagnes;Sassandra-Marahoue;Savanes;Vallee du Bandama;Woroba;Yamoussoukro;Zanzan
CL|Antofagasta;Araucanía;Arica y Parinacota;Atacama;Aysén;Biobío;Coquimbo;Los Lagos;Los Ríos;Magallanes;Maule;O'Higgins;Santiago;Tarapacá;Valparaíso;Ñuble
CM|Adamawa;Centre;East;Far North;Littoral;North;North West;South;South West;West
CN|Anhui;Beijing;Chongqing;Fujian;Gansu;Guangdong;Guangxi;Guizhou;Hainan;Hebei;Heilongjiang;Henan;Hong Kong;Hubei;Hunan;Inner Mongolia;Jiangsu;Jiangxi;Jilin;Liaoning;Macau;Ningxia;Qinghai;Shaanxi;Shandong;Shanghai;Shanxi;Sichuan;Tianjin;Tibet;Xinjiang;Yunnan;Zhejiang
CO|Amazonas;Antioquia;Arauca;Atlántico;Bogotá;Bolívar;Boyacá;Caldas;Caquetá;Casanare;Cauca;Cesar;Chocó;Cundinamarca;Córdoba;Guainía;Guaviare;Huila;La Guajira;Magdalena;Meta;Nariño;Norte de Santander;Putumayo;Quindío;Risaralda;San Andrés;Santander;Sucre;Tolima;Valle del Cauca;Vaupés;Vichada
CR|Alajuela;Cartago;Guanacaste;Heredia;Limon;Puntarenas;San Jose
CU|Artemisa;Camaguey;Ciego de Avila;Cienfuegos;Granma;Guantanamo;Havana;Holguin;Isla de la Juventud;Las Tunas;Matanzas;Mayabeque;Pinar del Rio;Sancti Spiritus;Santiago de Cuba;Villa Clara
CV|Boa Vista;Brava;Maio;Mosteiros;Paul;Porto Novo;Praia;Ribeira Brava;Ribeira Grande;Sal;Santa Catarina;Santa Cruz;Sao Domingos;Sao Filipe;Sao Vicente;Tarrafal
CY|Famagusta;Kyrenia;Larnaca;Limassol;Nicosia;Paphos
CZ|Central Bohemian;Hradec Kralove;Karlovy Vary;Liberec;Moravian-Silesian;Olomouc;Pardubice;Plzen;Prague;South Bohemian;South Moravian;Usti nad Labem;Vysocina;Zlin
DE|Baden-Württemberg;Bavaria;Berlin;Brandenburg;Bremen;Hamburg;Hesse;Lower Saxony;Mecklenburg-Vorpommern;North Rhine-Westphalia;Rhineland-Palatinate;Saarland;Saxony;Saxony-Anhalt;Schleswig-Holstein;Thuringia
DJ|Ali Sabieh;Arta;Dikhil;Djibouti;Obock;Tadjourah
DK|Capital Region;Central Denmark;North Denmark;Region Zealand;Southern Denmark
DM|Saint Andrew;Saint David;Saint George;Saint John;Saint Joseph;Saint Luke;Saint Mark;Saint Patrick;Saint Paul;Saint Peter
DO|Azua;Baoruco;Barahona;Dajabon;Distrito Nacional;Duarte;El Seibo;Elias Pina;Espaillat;Hato Mayor;Hermanas Mirabal;Independencia;La Altagracia;La Romana;La Vega;Maria Trinidad Sanchez;Monsenor Nouel;Monte Cristi;Monte Plata;Pedernales;Peravia;Puerto Plata;Samana;San Cristobal;San Jose de Ocoa;San Juan;San Pedro de Macoris;Sanchez Ramirez;Santiago;Santiago Rodriguez;Santo Domingo;Valverde
DZ|Adrar;Algiers;Annaba;Batna;Bechar;Bejaia;Biskra;Blida;Bouira;Chlef;Constantine;Djelfa;El Oued;Ghardaia;Jijel;Laghouat;Mascara;Medea;Mostaganem;Msila;Oran;Ouargla;Setif;Sidi Bel Abbes;Skikda;Tebessa;Tiaret;Tizi Ouzou;Tlemcen
EC|Azuay;Bolivar;Canar;Carchi;Chimborazo;Cotopaxi;El Oro;Esmeraldas;Galapagos;Guayas;Imbabura;Loja;Los Rios;Manabi;Morona Santiago;Napo;Orellana;Pastaza;Pichincha;Santa Elena;Santo Domingo de los Tsachilas;Sucumbios;Tungurahua;Zamora Chinchipe
EE|Harju;Hiiu;Ida-Viru;Jarva;Jogeva;Laane;Laane-Viru;Parnu;Polva;Rapla;Saare;Tartu;Valga;Viljandi;Voru
EG|Alexandria;Aswan;Asyut;Beheira;Beni Suef;Cairo;Dakahlia;Damietta;Faiyum;Gharbia;Giza;Ismailia;Kafr El Sheikh;Luxor;Matrouh;Minya;Monufia;New Valley;North Sinai;Port Said;Qalyubia;Qena;Red Sea;Sharqia;Sohag;South Sinai;Suez
ER|Anseba;Debub;Gash-Barka;Maekel;Northern Red Sea;Southern Red Sea
ES|Andalusia;Aragon;Asturias;Balearic Islands;Basque Country;Canary Islands;Cantabria;Castile and León;Castilla-La Mancha;Catalonia;Ceuta;Extremadura;Galicia;La Rioja;Madrid;Melilla;Murcia;Navarre;Valencia
ET|Addis Ababa;Afar;Amhara;Benishangul-Gumuz;Central Ethiopia;Dire Dawa;Gambela;Harari;Oromia;Sidama;Somali;South Ethiopia;South West Ethiopia;Tigray
FI|Central Finland;Central Ostrobothnia;Kainuu;Kanta-Häme;Kymenlaakso;Lapland;North Karelia;North Ostrobothnia;Northern Savonia;Ostrobothnia;Pirkanmaa;Päijät-Häme;Satakunta;South Karelia;South Ostrobothnia;Southern Savonia;Southwest Finland;Uusimaa;Åland
FJ|Ba;Bua;Cakaudrove;Kadavu;Lau;Lomaiviti;Macuata;Nadroga-Navosa;Naitasiri;Namosi;Ra;Rewa;Rotuma;Serua;Tailevu
FM|Chuuk;Kosrae;Pohnpei;Yap
FR|Auvergne-Rhône-Alpes;Bourgogne-Franche-Comté;Bretagne;Centre-Val de Loire;Corse;Grand Est;Hauts-de-France;Normandie;Nouvelle-Aquitaine;Occitanie;Pays de la Loire;Provence-Alpes-Côte d'Azur;Île-de-France
GA|Estuaire;Haut-Ogooue;Moyen-Ogooue;Ngounie;Nyanga;Ogooue-Ivindo;Ogooue-Lolo;Ogooue-Maritime;Woleu-Ntem
GB|England;Northern Ireland;Scotland;Wales
GD|Carriacou and Petite Martinique;Saint Andrew;Saint David;Saint George;Saint John;Saint Mark;Saint Patrick
GE|Abkhazia;Adjara;Guria;Imereti;Kakheti;Kvemo Kartli;Mtskheta-Mtianeti;Racha-Lechkhumi;Samegrelo-Zemo Svaneti;Samtskhe-Javakheti;Shida Kartli;Tbilisi
GH|Ahafo;Ashanti;Bono;Bono East;Central;Eastern;Greater Accra;North East;Northern;Oti;Savannah;Upper East;Upper West;Volta;Western;Western North
GM|Banjul;Central River;Lower River;North Bank;Upper River;West Coast
GN|Boke;Conakry;Faranah;Kankan;Kindia;Labe;Mamou;Nzerekore
GR|Attica;Central Greece;Central Macedonia;Crete;East Macedonia and Thrace;Epirus;Ionian Islands;North Aegean;Peloponnese;South Aegean;Thessaly;West Greece;West Macedonia
GT|Alta Verapaz;Baja Verapaz;Chimaltenango;Chiquimula;El Progreso;Escuintla;Guatemala;Huehuetenango;Izabal;Jalapa;Jutiapa;Peten;Quetzaltenango;Quiche;Retalhuleu;Sacatepequez;San Marcos;Santa Rosa;Solola;Suchitepequez;Totonicapan;Zacapa
GW|Bafata;Biombo;Bissau;Bolama;Cacheu;Gabu;Oio;Quinara;Tombali
HK|Central and Western;Eastern;Islands;Kowloon City;Kwai Tsing;Kwun Tong;North;Sai Kung;Sha Tin;Sham Shui Po;Southern;Tai Po;Tsuen Wan;Tuen Mun;Wan Chai;Wong Tai Sin;Yau Tsim Mong;Yuen Long
HN|Atlantida;Choluteca;Colon;Comayagua;Copan;Cortes;El Paraiso;Francisco Morazan;Gracias a Dios;Intibuca;Islas de la Bahia;La Paz;Lempira;Ocotepeque;Olancho;Santa Barbara;Valle;Yoro
HR|Bjelovar-Bilogora;Brod-Posavina;Dubrovnik-Neretva;Istria;Karlovac;Koprivnica-Krizevci;Krapina-Zagorje;Lika-Senj;Medimurje;Osijek-Baranja;Pozega-Slavonia;Primorje-Gorski Kotar;Sibenik-Knin;Sisak-Moslavina;Split-Dalmatia;Varazdin;Virovitica-Podravina;Vukovar-Srijem;Zadar;Zagreb;Zagreb City
HT|Artibonite;Centre;Grand'Anse;Nippes;Nord;Nord-Est;Nord-Ouest;Ouest;Sud;Sud-Est
HU|Bacs-Kiskun;Baranya;Bekes;Borsod-Abauj-Zemplen;Budapest;Csongrad-Csanad;Fejer;Gyor-Moson-Sopron;Hajdu-Bihar;Heves;Jasz-Nagykun-Szolnok;Komarom-Esztergom;Nograd;Pest;Somogy;Szabolcs-Szatmar-Bereg;Tolna;Vas;Veszprem;Zala
ID|Aceh;Bali;Banten;Bengkulu;Central Java;Central Kalimantan;Central Sulawesi;East Java;East Kalimantan;East Nusa Tenggara;Gorontalo;Jakarta;Jambi;Lampung;Maluku;North Kalimantan;North Maluku;North Sulawesi;North Sumatra;Papua;Riau;Riau Islands;South Kalimantan;South Sulawesi;South Sumatra;Southeast Sulawesi;West Java;West Kalimantan;West Nusa Tenggara;West Papua;West Sulawesi;West Sumatra;Yogyakarta
IE|Carlow;Cavan;Clare;Cork;Donegal;Dublin;Galway;Kerry;Kildare;Kilkenny;Laois;Leitrim;Limerick;Longford;Louth;Mayo;Meath;Monaghan;Offaly;Roscommon;Sligo;Tipperary;Waterford;Westmeath;Wexford;Wicklow
IL|Central;Haifa;Jerusalem;Northern;Southern;Tel Aviv
IQ|Al Anbar;Babil;Baghdad;Basra;Dhi Qar;Diyala;Dohuk;Erbil;Karbala;Kirkuk;Maysan;Muthanna;Najaf;Nineveh;Qadisiyyah;Salah ad Din;Sulaymaniyah;Wasit
IR|Alborz;Ardabil;Bushehr;Chaharmahal and Bakhtiari;East Azerbaijan;Fars;Gilan;Golestan;Hamadan;Hormozgan;Ilam;Isfahan;Kerman;Kermanshah;Khuzestan;Kohgiluyeh and Boyer-Ahmad;Kurdistan;Lorestan;Markazi;Mazandaran;North Khorasan;Qazvin;Qom;Razavi Khorasan;Semnan;Sistan and Baluchestan;South Khorasan;Tehran;West Azerbaijan;Yazd;Zanjan
IS|Capital Region;East;Northeast;Northwest;South;Southern Peninsula;West;Westfjords
IT|Abruzzo;Aosta Valley;Apulia;Basilicata;Calabria;Campania;Emilia-Romagna;Friuli-Venezia Giulia;Lazio;Liguria;Lombardy;Marche;Molise;Piedmont;Sardinia;Sicily;Trentino-Alto Adige;Tuscany;Umbria;Veneto
JM|Clarendon;Hanover;Kingston;Manchester;Portland;Saint Andrew;Saint Ann;Saint Catherine;Saint Elizabeth;Saint James;Saint Mary;Saint Thomas;Trelawny;Westmoreland
JO|Ajloun;Amman;Aqaba;Balqa;Irbid;Jerash;Karak;Maan;Madaba;Mafraq;Tafilah;Zarqa
JP|Aichi;Akita;Aomori;Chiba;Ehime;Fukui;Fukuoka;Fukushima;Gifu;Gunma;Hiroshima;Hokkaido;Hyogo;Ibaraki;Ishikawa;Iwate;Kagawa;Kagoshima;Kanagawa;Kochi;Kumamoto;Kyoto;Mie;Miyagi;Miyazaki;Nagano;Nagasaki;Nara;Niigata;Oita;Okayama;Okinawa;Osaka;Saga;Saitama;Shiga;Shimane;Shizuoka;Tochigi;Tokushima;Tokyo;Tottori;Toyama;Wakayama;Yamagata;Yamaguchi;Yamanashi
KE|Baringo;Bomet;Bungoma;Busia;Elgeyo-Marakwet;Embu;Garissa;Homa Bay;Isiolo;Kajiado;Kakamega;Kericho;Kiambu;Kilifi;Kirinyaga;Kisii;Kisumu;Kitui;Kwale;Laikipia;Lamu;Machakos;Makueni;Mandera;Marsabit;Meru;Migori;Mombasa;Murang'a;Nairobi;Nakuru;Nandi;Narok;Nyamira;Nyandarua;Nyeri;Samburu;Siaya;Taita-Taveta;Tana River;Tharaka-Nithi;Trans Nzoia;Turkana;Uasin Gishu;Vihiga;Wajir;West Pokot
KG|Batken;Bishkek;Chuy;Issyk-Kul;Jalal-Abad;Naryn;Osh;Osh City;Talas
KH|Banteay Meanchey;Battambang;Kampong Cham;Kampong Chhnang;Kampong Speu;Kampong Thom;Kampot;Kandal;Kep;Koh Kong;Kratie;Mondulkiri;Oddar Meanchey;Pailin;Phnom Penh;Preah Sihanouk;Preah Vihear;Prey Veng;Pursat;Ratanakiri;Siem Reap;Stung Treng;Svay Rieng;Takeo;Tbong Khmum
KM|Anjouan;Grande Comore;Moheli
KN|Christ Church Nichola Town;Saint Anne Sandy Point;Saint George Basseterre;Saint George Gingerland;Saint James Windward;Saint John Capisterre;Saint John Figtree;Saint Mary Cayon;Saint Paul Capisterre;Saint Paul Charlestown;Saint Peter Basseterre;Saint Thomas Lowland;Saint Thomas Middle Island;Trinity Palmetto Point
KR|Busan;Chungbuk;Chungnam;Daegu;Daejeon;Gangwon;Gwangju;Gyeongbuk;Gyeonggi;Gyeongnam;Incheon;Jeju;Jeonbuk;Jeonnam;Sejong;Seoul;Ulsan
KW|Ahmadi;Capital;Farwaniya;Hawalli;Jahra;Mubarak Al-Kabeer
KY|Bodden Town;Cayman Brac;East End;George Town;Little Cayman;North Side;West Bay
KZ|Abai;Akmola;Aktobe;Almaty;Almaty City;Astana;Atyrau;East Kazakhstan;Jetisu;Karaganda;Kostanay;Kyzylorda;Mangystau;North Kazakhstan;Pavlodar;Shymkent;Turkistan;Ulytau;West Kazakhstan;Zhambyl
LA|Attapeu;Bokeo;Bolikhamsai;Champasak;Houaphanh;Khammouane;Luang Namtha;Luang Prabang;Oudomxay;Phongsaly;Salavan;Savannakhet;Sekong;Vientiane;Vientiane Prefecture;Xaignabouli;Xaisomboun;Xiangkhouang
LB|Akkar;Baalbek-Hermel;Beirut;Beqaa;Mount Lebanon;Nabatieh;North;South
LC|Anse la Raye;Canaries;Castries;Choiseul;Dennery;Gros Islet;Laborie;Micoud;Soufriere;Vieux Fort
LI|Balzers;Eschen;Gamprin;Mauren;Planken;Ruggell;Schaan;Schellenberg;Triesen;Triesenberg;Vaduz
LK|Central;Eastern;North Central;North Western;Northern;Sabaragamuwa;Southern;Uva;Western
LR|Bomi;Bong;Gbarpolu;Grand Bassa;Grand Cape Mount;Grand Gedeh;Grand Kru;Lofa;Margibi;Maryland;Montserrado;Nimba;River Cess;River Gee;Sinoe
LT|Alytus;Kaunas;Klaipeda;Marijampole;Panevezys;Siauliai;Taurage;Telsiai;Utena;Vilnius
LU|Capellen;Clervaux;Diekirch;Echternach;Esch-sur-Alzette;Grevenmacher;Luxembourg;Mersch;Redange;Remich;Vianden;Wiltz
LV|Daugavpils;Jekabpils;Jelgava;Jurmala;Liepaja;Ogre;Rezekne;Riga;Valmiera;Ventspils
LY|Al Jabal al Akhdar;Al Jabal al Gharbi;Al Jafara;Al Jufra;Al Kufrah;Al Marj;Al Marqab;Al Wahat;Benghazi;Darnah;Ghat;Misrata;Murzuq;Nalut;Nuqat al Khams;Sabha;Sirte;Tripoli;Wadi al Hayat;Wadi al Shatii;Zawiya
MA|Béni Mellal-Khénifra;Casablanca-Settat;Dakhla-Oued Ed-Dahab;Drâa-Tafilalet;Fès-Meknès;Guelmim-Oued Noun;Laâyoune-Sakia El Hamra;Marrakesh-Safi;Oriental;Rabat-Salé-Kénitra;Souss-Massa;Tanger-Tetouan-Al Hoceima
MD|Balti;Bender;Cahul;Chisinau;Comrat;Edinet;Gagauzia;Orhei;Soroca;Transnistria;Ungheni
MK|Eastern;Northeastern;Pelagonia;Polog;Skopje;Southeastern;Southwestern;Vardar
ML|Bamako;Gao;Kayes;Kidal;Koulikoro;Mopti;Segou;Sikasso;Taoudenit;Tombouctou
MM|Ayeyarwady;Bago;Chin;Kachin;Kayah;Kayin;Magway;Mandalay;Mon;Naypyidaw;Rakhine;Sagaing;Shan;Tanintharyi;Yangon
MN|Arkhangai;Bayan-Olgii;Bayankhongor;Bulgan;Darkhan-Uul;Dornod;Dornogovi;Dundgovi;Govi-Altai;Govisumber;Khentii;Khovd;Khovsgol;Omnogovi;Orkhon;Ovorkhangai;Selenge;Sukhbaatar;Tov;Ulaanbaatar;Uvs;Zavkhan
MT|Gozo;Northern;Northern Harbour;South Eastern;Southern Harbour;Western
MU|Agalega;Black River;Flacq;Grand Port;Moka;Pamplemousses;Plaines Wilhems;Port Louis;Riviere du Rempart;Rodrigues;Savanne
MV|Addu City;Alif Alif;Alif Dhaal;Baa;Dhaalu;Faafu;Gaafu Alif;Gaafu Dhaalu;Gnaviyani;Haa Alif;Haa Dhaalu;Kaafu;Laamu;Lhaviyani;Male;Meemu;Noonu;Raa;Seenu;Shaviyani;Thaa;Vaavu
MX|Aguascalientes;Baja California;Baja California Sur;Campeche;Chiapas;Chihuahua;Coahuila;Colima;Durango;Guanajuato;Guerrero;Hidalgo;Jalisco;Mexico City;Michoacán;Morelos;México;Nayarit;Nuevo León;Oaxaca;Puebla;Querétaro;Quintana Roo;San Luis Potosí;Sinaloa;Sonora;Tabasco;Tamaulipas;Tlaxcala;Veracruz;Yucatán;Zacatecas
MY|Johor;Kedah;Kelantan;Kuala Lumpur;Labuan;Melaka;Negeri Sembilan;Pahang;Penang;Perak;Perlis;Putrajaya;Sabah;Sarawak;Selangor;Terengganu
MZ|Cabo Delgado;Gaza;Inhambane;Manica;Maputo;Maputo City;Nampula;Niassa;Sofala;Tete;Zambezia
NA|Erongo;Hardap;Karas;Kavango East;Kavango West;Khomas;Kunene;Ohangwena;Omaheke;Omusati;Oshana;Oshikoto;Otjozondjupa;Zambezi
NE|Agadez;Diffa;Dosso;Maradi;Niamey;Tahoua;Tillaberi;Zinder
NG|Abia;Adamawa;Akwa Ibom;Anambra;Bauchi;Bayelsa;Benue;Borno;Cross River;Delta;Ebonyi;Edo;Ekiti;Enugu;Federal Capital Territory;Gombe;Imo;Jigawa;Kaduna;Kano;Katsina;Kebbi;Kogi;Kwara;Lagos;Nasarawa;Niger;Ogun;Ondo;Osun;Oyo;Plateau;Rivers;Sokoto;Taraba;Yobe;Zamfara
NI|Boaco;Carazo;Chinandega;Chontales;Esteli;Granada;Jinotega;Leon;Madriz;Managua;Masaya;Matagalpa;North Caribbean Coast;Nueva Segovia;Rio San Juan;Rivas;South Caribbean Coast
NL|Drenthe;Flevoland;Friesland;Gelderland;Groningen;Limburg;North Brabant;North Holland;Overijssel;South Holland;Utrecht;Zeeland
NO|Agder;Akershus;Buskerud;Finnmark;Innlandet;Møre og Romsdal;Nordland;Oslo;Rogaland;Telemark;Troms;Trøndelag;Vestfold;Vestland;Østfold
NP|Bagmati;Gandaki;Karnali;Koshi;Lumbini;Madhesh;Sudurpashchim
NZ|Auckland;Bay of Plenty;Canterbury;Gisborne;Hawke's Bay;Manawatu-Whanganui;Marlborough;Nelson;Northland;Otago;Southland;Taranaki;Tasman;Waikato;Wellington;West Coast
OM|Ad Dakhiliyah;Ad Dhahirah;Al Batinah North;Al Batinah South;Al Buraimi;Al Wusta;Ash Sharqiyah North;Ash Sharqiyah South;Dhofar;Musandam;Muscat
PA|Bocas del Toro;Chiriqui;Cocle;Colon;Darien;Embera-Wounaan;Guna Yala;Herrera;Los Santos;Naso Tjer Di;Ngobe-Bugle;Panama;Panama Oeste;Veraguas
PE|Amazonas;Apurímac;Arequipa;Ayacucho;Cajamarca;Callao;Cusco;Huancavelica;Huánuco;Ica;Junín;La Libertad;Lambayeque;Lima;Loreto;Madre de Dios;Moquegua;Pasco;Piura;Puno;San Martín;Tacna;Tumbes;Ucayali;Áncash
PG|Bougainville;Central;Chimbu;East New Britain;East Sepik;Eastern Highlands;Enga;Gulf;Hela;Jiwaka;Madang;Manus;Milne Bay;Morobe;National Capital District;New Ireland;Northern;Southern Highlands;West New Britain;West Sepik;Western;Western Highlands
PH|Bangsamoro;Bicol;Cagayan Valley;Calabarzon;Caraga;Central Luzon;Central Visayas;Cordillera;Davao;Eastern Visayas;Ilocos;Metro Manila;Mimaropa;Northern Mindanao;Soccsksargen;Western Visayas;Zamboanga Peninsula
PK|Azad Kashmir;Balochistan;Gilgit-Baltistan;Islamabad Capital Territory;Khyber Pakhtunkhwa;Punjab;Sindh
PL|Greater Poland;Holy Cross;Kuyavian-Pomeranian;Lesser Poland;Lower Silesian;Lublin;Lubusz;Masovian;Opole;Podlaskie;Pomeranian;Silesian;Subcarpathian;Warmian-Masurian;West Pomeranian;Łódź
PT|Aveiro;Azores;Beja;Braga;Bragança;Castelo Branco;Coimbra;Faro;Guarda;Leiria;Lisbon;Madeira;Portalegre;Porto;Santarém;Setúbal;Viana do Castelo;Vila Real;Viseu;Évora
PY|Alto Paraguay;Alto Parana;Amambay;Asuncion;Boqueron;Caaguazu;Caazapa;Canindeyu;Central;Concepcion;Cordillera;Guaira;Itapua;Misiones;Neembucu;Paraguari;Presidente Hayes;San Pedro
QA|Al Daayen;Al Khor;Al Rayyan;Al Shahaniya;Al Shamal;Al Wakrah;Doha;Umm Salal
RO|Alba;Arad;Arges;Bacau;Bihor;Bistrita-Nasaud;Botosani;Braila;Brasov;Bucharest;Buzau;Calarasi;Caras-Severin;Cluj;Constanta;Covasna;Dambovita;Dolj;Galati;Giurgiu;Gorj;Harghita;Hunedoara;Ialomita;Iasi;Ilfov;Maramures;Mehedinti;Mures;Neamt;Olt;Prahova;Salaj;Satu Mare;Sibiu;Suceava;Teleorman;Timis;Tulcea;Valcea;Vaslui;Vrancea
RS|Belgrade;Bor;Braničevo;Jablanica;Kolubara;Mačva;Moravica;Nišava;Pirot;Podunavlje;Pomoravlje;Pčinja;Rasina;Raška;South Banat;South Bačka;Toplica;Vojvodina;West Bačka;Zaječar;Zlatibor;Šumadija
RU|Altai;Amur;Arkhangelsk;Astrakhan;Bashkortostan;Belgorod;Bryansk;Buryatia;Chechnya;Chelyabinsk;Chuvashia;Dagestan;Ingushetia;Irkutsk;Ivanovo;Kabardino-Balkaria;Kaliningrad;Kalmykia;Kaluga;Kamchatka;Karelia;Kemerovo;Khabarovsk;Khakassia;Kirov;Komi;Kostroma;Krasnodar;Krasnoyarsk;Kurgan;Kursk;Leningrad;Lipetsk;Magadan;Mari El;Mordovia;Moscow;Moscow Oblast;Murmansk;Nizhny Novgorod;North Ossetia;Novgorod;Novosibirsk;Omsk;Orenburg;Oryol;Penza;Perm;Primorsky;Pskov;Rostov;Ryazan;Sakha;Sakhalin;Samara;Saratov;Smolensk;St. Petersburg;Stavropol;Sverdlovsk;Tambov;Tatarstan;Tomsk;Tula;Tver;Tyumen;Tyva;Udmurtia;Ulyanovsk;Vladimir;Volgograd;Vologda;Voronezh;Yaroslavl;Zabaykalsky
RW|Eastern;Kigali;Northern;Southern;Western
SA|Al Bahah;Al Jawf;Al Madinah;Al Qassim;Asir;Eastern Province;Hail;Jazan;Makkah;Najran;Northern Borders;Riyadh;Tabuk
SB|Central;Choiseul;Guadalcanal;Honiara;Isabel;Makira-Ulawa;Malaita;Rennell and Bellona;Temotu;Western
SC|Anse Boileau;Anse Royale;Baie Lazare;Beau Vallon;Cascade;English River;Glacis;Grand Anse Mahe;Grand Anse Praslin;La Digue;Mont Fleuri;Plaisance;Pointe Larue;Port Glaud;Takamaka;Victoria
SD|Blue Nile;Central Darfur;East Darfur;Gedaref;Gezira;Kassala;Khartoum;North Darfur;North Kordofan;Northern;Red Sea;River Nile;Sennar;South Darfur;South Kordofan;West Darfur;West Kordofan;White Nile
SE|Blekinge;Dalarna;Gotland;Gävleborg;Halland;Jämtland;Jönköping;Kalmar;Kronoberg;Norrbotten;Skåne;Stockholm;Södermanland;Uppsala;Värmland;Västerbotten;Västernorrland;Västmanland;Västra Götaland;Örebro;Östergötland
SG|Central;East;North;North-East;West
SI|Carinthia;Celje;Central Sava;Central Slovenia;Coastal-Karst;Drava;Gorizia;Littoral-Inner Carniola;Lower Sava;Mura;Savinja;Southeast Slovenia;Upper Carniola
SK|Banska Bystrica;Bratislava;Kosice;Nitra;Presov;Trencin;Trnava;Zilina
SL|Eastern;North West;Northern;Southern;Western Area
SM|Acquaviva;Borgo Maggiore;Chiesanuova;Domagnano;Faetano;Fiorentino;Montegiardino;San Marino;Serravalle
SN|Dakar;Diourbel;Fatick;Kaffrine;Kaolack;Kedougou;Kolda;Louga;Matam;Saint-Louis;Sedhiou;Tambacounda;Thies;Ziguinchor
SO|Awdal;Bakool;Banaadir;Bari;Bay;Galguduud;Gedo;Hiiraan;Jubbada Dhexe;Jubbada Hoose;Mudug;Nugaal;Sanaag;Shabeellaha Dhexe;Shabeellaha Hoose;Sool;Togdheer;Woqooyi Galbeed
SR|Brokopondo;Commewijne;Coronie;Marowijne;Nickerie;Para;Paramaribo;Saramacca;Sipaliwini;Wanica
SV|Ahuachapan;Cabanas;Chalatenango;Cuscatlan;La Libertad;La Paz;La Union;Morazan;San Miguel;San Salvador;San Vicente;Santa Ana;Sonsonate;Usulutan
TC|Grand Turk;Middle Caicos;North Caicos;Providenciales;Salt Cay;South Caicos;West Caicos
TD|Barh-El-Gazel;Batha;Borkou;Chari-Baguirmi;Ennedi-Est;Ennedi-Ouest;Guera;Hadjer-Lamis;Kanem;Lac;Logone Occidental;Logone Oriental;Mandoul;Mayo-Kebbi Est;Mayo-Kebbi Ouest;Moyen-Chari;Ndjamena;Ouaddai;Salamat;Sila;Tandjile;Tibesti;Wadi Fira
TG|Centrale;Kara;Maritime;Plateaux;Savanes
TH|Bangkok;Central;Eastern;Northeastern;Northern;Southern;Western
TJ|Districts of Republican Subordination;Dushanbe;Gorno-Badakhshan;Khatlon;Sughd
TM|Ahal;Ashgabat;Balkan;Dashoguz;Lebap;Mary
TN|Ariana;Beja;Ben Arous;Bizerte;Gabes;Gafsa;Jendouba;Kairouan;Kasserine;Kebili;Kef;Mahdia;Manouba;Medenine;Monastir;Nabeul;Sfax;Sidi Bouzid;Siliana;Sousse;Tataouine;Tozeur;Tunis;Zaghouan
TO|Eua;Haapai;Niuas;Tongatapu;Vavau
TR|Adana;Adıyaman;Afyonkarahisar;Aksaray;Amasya;Ankara;Antalya;Ardahan;Artvin;Aydın;Ağrı;Balıkesir;Bartın;Batman;Bayburt;Bilecik;Bingöl;Bitlis;Bolu;Burdur;Bursa;Denizli;Diyarbakır;Düzce;Edirne;Elazığ;Erzincan;Erzurum;Eskişehir;Gaziantep;Giresun;Gümüşhane;Hakkari;Hatay;Isparta;Iğdır;Kahramanmaraş;Karabük;Karaman;Kars;Kastamonu;Kayseri;Kilis;Kocaeli;Konya;Kütahya;Kırklareli;Kırıkkale;Kırşehir;Malatya;Manisa;Mardin;Mersin;Muğla;Muş;Nevşehir;Niğde;Ordu;Osmaniye;Rize;Sakarya;Samsun;Siirt;Sinop;Sivas;Tekirdağ;Tokat;Trabzon;Tunceli;Uşak;Van;Yalova;Yozgat;Zonguldak;Çanakkale;Çankırı;Çorum;İstanbul;İzmir;Şanlıurfa;Şırnak
TT|Arima;Chaguanas;Couva-Tabaquite-Talparo;Diego Martin;Mayaro-Rio Claro;Penal-Debe;Point Fortin;Port of Spain;Princes Town;San Fernando;San Juan-Laventille;Sangre Grande;Siparia;Tobago;Tunapuna-Piarco
TW|Changhua;Chiayi;Chiayi City;Hsinchu;Hsinchu City;Hualien;Kaohsiung;Keelung;Kinmen;Lienchiang;Miaoli;Nantou;New Taipei;Penghu;Pingtung;Taichung;Tainan;Taipei;Taitung;Taoyuan;Yilan;Yunlin
TZ|Arusha;Dar es Salaam;Dodoma;Geita;Iringa;Kagera;Katavi;Kigoma;Kilimanjaro;Lindi;Manyara;Mara;Mbeya;Morogoro;Mtwara;Mwanza;Njombe;Pwani;Rukwa;Ruvuma;Shinyanga;Simiyu;Singida;Songwe;Tabora;Tanga
UA|Cherkasy;Chernihiv;Chernivtsi;Dnipropetrovsk;Donetsk;Ivano-Frankivsk;Kharkiv;Kherson;Khmelnytskyi;Kirovohrad;Kyiv;Luhansk;Lviv;Mykolaiv;Odesa;Poltava;Rivne;Sumy;Ternopil;Vinnytsia;Volyn;Zakarpattia;Zaporizhzhia;Zhytomyr
UG|Central;Eastern;Northern;Western
US|Alabama;Alaska;Arizona;Arkansas;California;Colorado;Connecticut;Delaware;District of Columbia;Florida;Georgia;Hawaii;Idaho;Illinois;Indiana;Iowa;Kansas;Kentucky;Louisiana;Maine;Maryland;Massachusetts;Michigan;Minnesota;Mississippi;Missouri;Montana;Nebraska;Nevada;New Hampshire;New Jersey;New Mexico;New York;North Carolina;North Dakota;Ohio;Oklahoma;Oregon;Pennsylvania;Rhode Island;South Carolina;South Dakota;Tennessee;Texas;Utah;Vermont;Virginia;Washington;West Virginia;Wisconsin;Wyoming
UY|Artigas;Canelones;Cerro Largo;Colonia;Durazno;Flores;Florida;Lavalleja;Maldonado;Montevideo;Paysandu;Rio Negro;Rivera;Rocha;Salto;San Jose;Soriano;Tacuarembo;Treinta y Tres
UZ|Andijan;Bukhara;Fergana;Jizzakh;Karakalpakstan;Kashkadarya;Khorezm;Namangan;Navoiy;Samarkand;Sirdaryo;Surkhandarya;Tashkent;Tashkent City
VE|Amazonas;Anzoategui;Apure;Aragua;Barinas;Bolivar;Capital District;Carabobo;Cojedes;Delta Amacuro;Falcon;Guarico;La Guaira;Lara;Merida;Miranda;Monagas;Nueva Esparta;Portuguesa;Sucre;Tachira;Trujillo;Yaracuy;Zulia
VG|Anegada;Jost Van Dyke;Tortola;Virgin Gorda
VN|An Giang;Bac Ninh;Ca Mau;Can Tho;Cao Bang;Da Nang;Dak Lak;Dien Bien;Dong Nai;Dong Thap;Gia Lai;Ha Noi;Ha Tinh;Hai Phong;Ho Chi Minh City;Hue;Hung Yen;Khanh Hoa;Lai Chau;Lam Dong;Lang Son;Lao Cai;Nghe An;Ninh Binh;Phu Tho;Quang Ngai;Quang Ninh;Quang Tri;Son La;Tay Ninh;Thai Nguyen;Thanh Hoa;Tuyen Quang;Vinh Long
VU|Malampa;Penama;Sanma;Shefa;Tafea;Torba
WS|Aana;Aiga-i-le-Tai;Atua;Fa'asaleleaga;Gaga'emauga;Gagaifomauga;Palauli;Satupa'itea;Tuamasaga;Va'a-o-Fonoti;Vaisigano
YE|Abyan;Aden;Al Bayda;Al Dhale;Al Hudaydah;Al Jawf;Al Mahrah;Al Mahwit;Amran;Dhamar;Hadhramaut;Hajjah;Ibb;Lahij;Marib;Raymah;Saada;Sanaa;Sanaa City;Shabwah;Socotra;Taiz
ZA|Eastern Cape;Free State;Gauteng;KwaZulu-Natal;Limpopo;Mpumalanga;North West;Northern Cape;Western Cape
ZM|Central;Copperbelt;Eastern;Luapula;Lusaka;Muchinga;North-Western;Northern;Southern;Western
ZW|Bulawayo;Harare;Manicaland;Mashonaland Central;Mashonaland East;Mashonaland West;Masvingo;Matabeleland North;Matabeleland South;Midlands
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
