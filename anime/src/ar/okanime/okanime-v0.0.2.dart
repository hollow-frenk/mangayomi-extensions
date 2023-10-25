import 'dart:convert';
import 'package:bridge_lib/bridge_lib.dart';

getPopularAnime(MManga anime) async {
  final data = {"url": "https://www.okanime.xyz"};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  anime.urls = MBridge.xpath(res,
      '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');

  anime.names = MBridge.xpath(res,
      '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');

  anime.images = MBridge.xpath(res,
      '//div[@class="section" and contains(text(),"افضل انميات")]/div[@class="section-content"]/div/div/div[contains(@class,"anime-card")]/div[@class="anime-image")]/img/@src');
  anime.hasNextPage = false;
  return anime;
}

getAnimeDetail(MManga anime) async {
  final statusList = [
    {"يعرض الان": 0, "مكتمل": 1}
  ];
  final data = {"url": anime.link};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;

  final status = MBridge.xpath(res,
      '//*[@class="full-list-info" and contains(text(),"حالة الأنمي")]/small/a/text()');
  if (status.isNotEmpty) {
    anime.status = MBridge.parseStatus(status.first, statusList);
  }
  anime.description =
      MBridge.xpath(res, '//*[@class="review-content"]/text()').first;
  final genre = MBridge.xpath(res, '//*[@class="review-author-info"]/a/text()');
  anime.genre = genre;

  anime.urls = MBridge.xpath(res,
          '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/@href')
      .reversed
      .toList();

  anime.names = MBridge.xpath(res,
          '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h5/a/text()')
      .reversed
      .toList();
  anime.chaptersDateUploads = [];
  return anime;
}

getLatestUpdatesAnime(MManga anime) async {
  final data = {
    "url": "https://www.okanime.xyz/espisode-list?page=${anime.page}"
  };
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  anime.urls = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');

  anime.names = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');

  anime.images = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="episode-image")]/img/@src');
  final nextPage =
      MBridge.xpath(res, '//li[@class="page-item"]/a[@rel="next"]/@href');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

searchAnime(MManga anime) async {
  String url = "https://www.okanime.xyz/search/?s=${anime.query}";
  if (anime.page > 1) {
    url += "&page=${anime.page}";
  }
  final data = {"url": url};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  anime.urls = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/@href');

  anime.names = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-title")]/h4/a/text()');

  anime.images = MBridge.xpath(res,
      '//*[contains(@class,"anime-card")]/div[@class="anime-image")]/img/@src');
  final nextPage =
      MBridge.xpath(res, '//li[@class="page-item"]/a[@rel="next"]/@href');
  if (nextPage.isEmpty) {
    anime.hasNextPage = false;
  } else {
    anime.hasNextPage = true;
  }
  return anime;
}

getVideoList(MManga anime) async {
  final datas = {"url": anime.link};
  final response = await MBridge.http('GET', json.encode(datas));

  if (response.hasError) {
    return response;
  }
  String res = response.body;
  final urls = MBridge.xpath(res, '//*[@id="streamlinks"]/a/@data-src');
  final qualities = MBridge.xpath(res, '//*[@id="streamlinks"]/a/span/text()');

  List<MVideo> videos = [];
  for (var i = 0; i < urls.length; i++) {
    final url = urls[i];
    final quality = getQuality(qualities[i]);
    List<MVideo> a = [];

    if (url.contains("https://doo")) {
      a = await MBridge.doodExtractor(url, "DoodStream - $quality");
    } else if (url.contains("mp4upload")) {
      a = await MBridge.mp4UploadExtractor(url, null, "", "");
    } else if (url.contains("ok.ru")) {
      a = await MBridge.okruExtractor(url);
    } else if (url.contains("voe.sx")) {
      a = await MBridge.voeExtractor(url, "VoeSX $quality");
    } else if (containsVidBom(url)) {
      a = await MBridge.vidBomExtractor(url);
    }
    if (a.isNotEmpty) {
      videos.addAll(a);
    }
  }
  return videos;
}

String getQuality(String quality) {
  quality = quality.replaceAll(" ", "");
  if (quality == "HD") {
    return "720p";
  } else if (quality == "FHD") {
    return "1080p";
  } else if (quality == "SD") {
    return "480p";
  }
  return "240p";
}

bool containsVidBom(String url) {
  url = url;
  final list = ["vidbam", "vadbam", "vidbom", "vidbm"];
  for (var n in list) {
    if (url.contains(n)) {
      return true;
    }
  }
  return false;
}
