import '../../../../../model/source.dart';

  Source get magusmangaSource => _magusmangaSource;
            
  Source _magusmangaSource = Source(
    name: "Magus Manga",
    baseUrl: "https://magusmanga.com",
    lang: "ar",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/magusmanga/icon.png",
    dateFormat:"MMMMM d, yyyy",
    dateFormatLocale:"ar",
  );