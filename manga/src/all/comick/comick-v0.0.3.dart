import 'package:bridge_lib/bridge_lib.dart';
import 'dart:convert';

getLatestUpdatesManga(MManga manga) async {
  final url =
      "${manga.apiUrl}/v1.0/search?sort=uploaded&page=${manga.page}&tachiyomi=true";
  final data = {"url": url, "headers": getHeader(manga.baseUrl)};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.names = MBridge.jsonPathToList(res, r'$.title', 0);
  List<String> ids = MBridge.jsonPathToList(res, r'$.hid', 0);
  List<String> mangaUrls = [];
  for (var id in ids) {
    mangaUrls.add("/comic/$id/#");
  }
  manga.urls = mangaUrls;
  manga.images = MBridge.jsonPathToList(res, r'$.cover_url', 0);
  return manga;
}

getMangaDetail(MManga manga) async {
  final statusList = [
    {
      "1": 0,
      "2": 1,
      "3": 3,
      "4": 2,
    }
  ];

  final headers = getHeader(manga.baseUrl);

  final urll =
      "${manga.apiUrl}${manga.link.replaceAll("#", '')}?tachiyomi=true";
  final data = {"url": urll, "headers": headers};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.author = MBridge.jsonPathToString(res, r'$.authors[*].name', '');
  manga.genre =
      MBridge.jsonPathToString(res, r'$.genres[*].name', "_.").split("_.");
  manga.description = MBridge.jsonPathToString(res, r'$..desc', '');
  manga.status = MBridge.parseStatus(
      MBridge.jsonPathToString(res, r'$..comic.status', ''), statusList);
  final chapUrlReq =
      "${manga.apiUrl}${manga.link.replaceAll("#", '')}chapters?lang=${manga.lang}&tachiyomi=true&page=1";
  final dataReq = {"url": chapUrlReq, "headers": headers};
  final request = await MBridge.http('GET', json.encode(dataReq));
  if (request.hasError) {
    return response;
  }
  var total = MBridge.jsonPathToString(request.body, r'$.total', '');
  final chapterLimit = MBridge.intParse("$total");
  final newChapUrlReq =
      "${manga.apiUrl}${manga.link.replaceAll("#", '')}chapters?limit=$chapterLimit&lang=${manga.lang}&tachiyomi=true&page=1";

  final newDataReq = {"url": newChapUrlReq, "headers": headers};
  final newRequest = await MBridge.http('GET', json.encode(newDataReq));
  if (newRequest.hasError) {
    return response;
  }
  manga.urls =
      MBridge.jsonPathToString(newRequest.body, r'$.chapters[*].hid', "_.")
          .split("_.");
  final chapDate = MBridge.jsonPathToString(
          newRequest.body, r'$.chapters[*].created_at', "_.")
      .split("_.");
  manga.chaptersDateUploads =
      MBridge.listParseDateTime(chapDate, "yyyy-MM-dd'T'HH:mm:ss'Z'", "en");
  manga.chaptersVolumes =
      MBridge.jsonPathToString(newRequest.body, r'$.chapters[*].vol', "_.")
          .split("_.");
  manga.chaptersScanlators = MBridge.jsonPathToString(
          newRequest.body, r'$.chapters[*].group_name', "_.")
      .split("_.");
  manga.names =
      MBridge.jsonPathToString(newRequest.body, r'$.chapters[*].title', "_.")
          .split("_.");
  manga.chaptersChaps =
      MBridge.jsonPathToString(newRequest.body, r'$.chapters[*].chap', "_.")
          .split("_.");

  return manga;
}

getPopularManga(MManga manga) async {
  final urll =
      "${manga.apiUrl}/v1.0/search?sort=follow&page=${manga.page}&tachiyomi=true";
  final data = {"url": urll, "headers": getHeader(manga.baseUrl)};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.names = MBridge.jsonPathToList(res, r'$.title', 0);
  List<String> ids = MBridge.jsonPathToList(res, r'$.hid', 0);
  List<String> mangaUrls = [];
  for (var id in ids) {
    mangaUrls.add("/comic/$id/#");
  }
  manga.urls = mangaUrls;
  manga.images = MBridge.jsonPathToList(res, r'$.cover_url', 0);
  return manga;
}

searchManga(MManga manga) async {
  final urll = "${manga.apiUrl}/v1.0/search?q=${manga.query}&tachiyomi=true";
  final data = {"url": urll, "headers": getHeader(manga.baseUrl)};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  manga.names = MBridge.jsonPathToList(res, r'$.title', 0);
  List<String> ids = MBridge.jsonPathToList(res, r'$.hid', 0);
  List<String> mangaUrls = [];
  for (var id in ids) {
    mangaUrls.add("/comic/$id/#");
  }
  manga.urls = mangaUrls;
  manga.images = MBridge.jsonPathToList(res, r'$.cover_url', 0);
  return manga;
}

getChapterPages(MManga manga) async {
  final url = "${manga.apiUrl}/chapter/${manga.link}?tachiyomi=true";
  final data = {"url": url, "headers": getHeader(url)};
  final response = await MBridge.http('GET', json.encode(data));
  if (response.hasError) {
    return response;
  }
  String res = response.body;
  return MBridge.jsonPathToString(res, r'$.chapter.images[*].url', '_.')
      .split('_.');
}

Map<String, String> getHeader(String url) {
  final headers = {
    "Referer": "$url/",
    'User-Agent':
        "Tachiyomi Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:110.0) Gecko/20100101 Firefox/110.0"
  };
  return headers;
}
