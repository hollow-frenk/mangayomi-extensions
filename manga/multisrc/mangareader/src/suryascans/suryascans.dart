import '../../../../../model/source.dart';

  Source get suryascansSource => _suryascansSource;
            
  Source _suryascansSource = Source(
    name: "Surya Scans",
    baseUrl: "https://suryascans.com",
    lang: "en",
    isNsfw:true,
    typeSource: "mangareader",
    iconUrl:"https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/manga/multisrc/mangareader/src/suryascans/icon.png",
    dateFormat:"MMMM dd, yyyy",
    dateFormatLocale:"en_us",
  );