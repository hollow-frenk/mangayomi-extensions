import '../../../../../model/source.dart';

  Source get monarcamangaSource => _monarcamangaSource;
            
  Source _monarcamangaSource = Source(
    name: "MonarcaManga",
    baseUrl: "https://monarcamanga.com",
    lang: "es",
    isNsfw:true,
    typeSource: "madara",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/madara/src/monarcamanga/icon.png",
    dateFormat:"MMM d, yyy",
    dateFormatLocale:"es",
  );