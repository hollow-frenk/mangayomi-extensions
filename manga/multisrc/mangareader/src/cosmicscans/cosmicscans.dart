import '../../../../../model/source.dart';

  Source get cosmicscansSource => _cosmicscansSource;
            
  Source _cosmicscansSource = Source(
    name: "Cosmic Scans",
    baseUrl: "https://cosmicscans.com",
    lang: "en",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/cosmicscans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );