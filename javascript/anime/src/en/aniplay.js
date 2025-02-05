const mangayomiSources = [{
    "name": "Aniplay",
    "lang": "en",
    "baseUrl": "https://aniplaynow.live",
    "apiUrl": "https://aniplaynow.live",
    "iconUrl": "https://www.google.com/s2/favicons?sz=128&domain=https://aniplaynow.live/",
    "typeSource": "single",
    "itemType": 1,
    "version": "1.0.2",
    "dateFormat": "",
    "dateFormatLocale": "",
    "pkgPath": "anime/src/en/aniplay.js"
}];

class DefaultExtension extends MProvider {

    constructor() {
        super();
        this.client = new Client();
    }

    getHeaders(url) {
        return {
            Referer: this.source.apiUrl
        }
    }

    getPreference(key) {
        const preferences = new SharedPreferences();
        return preferences.get(key);
    }


    // code from torrentioanime.js
    anilistQuery() {
        return `
            query ($page: Int, $perPage: Int, $sort: [MediaSort], $search: String) {
                Page(page: $page, perPage: $perPage) {
                    pageInfo {
                        currentPage
                        hasNextPage
                    }
                    media(type: ANIME, sort: $sort, search: $search, status_in: [RELEASING, FINISHED, NOT_YET_RELEASED]) {
                        id
                        title {
                            romaji
                            english
                            native
                        }
                        coverImage {
                            extraLarge
                            large
                        }
                        description
                        status
                        tags {
                            name
                        }
                        genres
                        studios {
                            nodes {
                                name
                            }
                        }
                        countryOfOrigin
                        isAdult
                    }
                }
            }
        `.trim();
    }

    // code from torrentioanime.js
    anilistLatestQuery() {
        const currentTimeInSeconds = Math.floor(Date.now() / 1000);
        return `
            query ($page: Int, $perPage: Int, $sort: [AiringSort]) {
              Page(page: $page, perPage: $perPage) {
                pageInfo {
                  currentPage
                  hasNextPage
                }
                airingSchedules(
                  airingAt_greater: 0
                  airingAt_lesser: ${currentTimeInSeconds - 10000}
                  sort: $sort
                ) {
                  media {
                    id
                    title {
                      romaji
                      english
                      native
                    }
                    coverImage {
                      extraLarge
                      large
                    }
                    description
                    status
                    tags {
                      name
                    }
                    genres
                    studios {
                      nodes {
                        name
                      }
                    }
                    countryOfOrigin
                    isAdult
                  }
                }
              }
            }
        `.trim();
    }

    // code from torrentioanime.js
    async getAnimeDetails(anilistId) {
        const query = `
                query($id: Int){
                    Media(id: $id){
                        id
                        title {
                            romaji
                            english
                            native
                        }
                        coverImage {
                            extraLarge
                            large
                        }
                        description
                        status
                        tags {
                            name
                        }
                        genres
                        studios {
                            nodes {
                                name
                            }
                        }
                        format    
                        countryOfOrigin
                        isAdult
                    }
                }
            `.trim();

        const variables = JSON.stringify({ id: anilistId });

        const res = await this.makeGraphQLRequest(query, variables);
        const media = JSON.parse(res.body).data.Media;
        const anime = {};
        anime.name = (() => {
            var preferenceTitle = this.getPreference("aniplay_pref_title");
            switch (preferenceTitle) {
                case "romaji":
                    return media?.title?.romaji || "";
                case "english":
                    return media?.title?.english?.trim() || media?.title?.romaji || "";
                case "native":
                    return media?.title?.native || "";
                default:
                    return "";
            }
        })();
        anime.imageUrl = media?.coverImage?.extraLarge || "";
        anime.description = (media?.description || "No Description")
            .replace(/<br><br>/g, "\n")
            .replace(/<.*?>/g, "");

        anime.status = (() => {
            switch (media?.status) {
                case "RELEASING":
                    return 0;
                case "FINISHED":
                    return 1;
                case "HIATUS":
                    return 2;
                case "NOT_YET_RELEASED":
                    return 3;
                default:
                    return 5;
            }
        })();

        const tagsList = media?.tags?.map(tag => tag.name).filter(Boolean) || [];
        const genresList = media?.genres || [];
        anime.genre = [...new Set([...tagsList, ...genresList])].sort();
        const studiosList = media?.studios?.nodes?.map(node => node.name).filter(Boolean) || [];
        anime.author = studiosList.sort().join(", ");
        anime.format = media.format
        return anime;
    }

    // code from torrentioanime.js
    async makeGraphQLRequest(query, variables) {
        const res = await this.client.post("https://graphql.anilist.co", {},
            {
                query, variables
            });
        return res;
    }

    // code from torrentioanime.js
    parseSearchJson(jsonLine, isLatestQuery = false) {
        const jsonData = JSON.parse(jsonLine);
        jsonData.type = isLatestQuery ? "AnilistMetaLatest" : "AnilistMeta";
        const metaData = jsonData;

        const mediaList = metaData.type == "AnilistMeta"
            ? metaData.data?.Page?.media || []
            : metaData.data?.Page?.airingSchedules.map(schedule => schedule.media) || [];

        const hasNextPage = metaData.type == "AnilistMeta" || metaData.type == "AnilistMetaLatest"
            ? metaData.data?.Page?.pageInfo?.hasNextPage || false
            : false;

        const animeList = mediaList
            .filter(media => !((media?.countryOfOrigin === "CN" || media?.isAdult) && isLatestQuery))
            .map(media => {
                const anime = {};
                anime.link = media?.id?.toString() || "";
                anime.name = (() => {
                    var preferenceTitle = this.getPreference("aniplay_pref_title");
                    switch (preferenceTitle) {
                        case "romaji":
                            return media?.title?.romaji || "";
                        case "english":
                            return media?.title?.english?.trim() || media?.title?.romaji || "";
                        case "native":
                            return media?.title?.native || "";
                        default:
                            return "";
                    }
                })();
                anime.imageUrl = media?.coverImage?.extraLarge || "";

                return anime;
            });

        return { "list": animeList, "hasNextPage": hasNextPage };
    }

    async getPopular(page) {
        const variables = JSON.stringify({
            page: page,
            perPage: 30,
            sort: "TRENDING_DESC"
        });

        const res = await this.makeGraphQLRequest(this.anilistQuery(), variables);

        return this.parseSearchJson(res.body)
    }

    async getLatestUpdates(page) {
        const variables = JSON.stringify({
            page: page,
            perPage: 30,
            sort: "TIME_DESC"
        });

        const res = await this.makeGraphQLRequest(this.anilistLatestQuery(), variables);

        return this.parseSearchJson(res.body, true)
    }

    async search(query, page, filters) {
        const variables = JSON.stringify({
            page: page,
            perPage: 30,
            sort: "POPULARITY_DESC",
            search: query
        });

        const res = await this.makeGraphQLRequest(this.anilistQuery(), variables);

        return this.parseSearchJson(res.body)
    }

    get supportsLatest() {
        throw new Error("supportsLatest not implemented");
    }

    async aniplayRequest(slug, body) {
        var next_action = ""

        if (slug.indexOf("info/") > -1) {
            next_action = 'f3422af67c84852f5e63d50e1f51718f1c0225c4'
        } else if (slug.indexOf("watch/") > -1) {
            next_action = '5dbcd21c7c276c4d15f8de29d9ef27aef5ea4a5e'
        }
        var url = `${this.source.baseUrl}/anime/${slug}`
        var headers = {
            "referer": "https://aniplaynow.live",
            'next-action': next_action,
            "Content-Type": "application/json",
        }

        var response = await new Client().post(url, headers, body);

        if (response.statusCode != 200) {
            throw new Error("Error: " + response.statusText);
        }
        return JSON.parse(response.body.split('1:')[1])

    }

    async getDetail(url) {
        var anilistId = url
        var animeData = await this.getAnimeDetails(anilistId)


        var slug = `info/${anilistId}`
        var body = [anilistId, true, false]
        var result = await this.aniplayRequest(slug, body)
        if (result.length < 1) {
            throw new Error("Error: No data found for the given URL");
        }

        var user_provider = this.getPreference("aniplay_pref_provider_new");
        var choices = result
        if (user_provider !== "all") {
            for (var ch of result) {
                if (ch["providerId"] == user_provider) {
                    choices = [ch]
                    break;
                }
            }
        }

        for (const choice of choices) {
            var user_mark_filler_ep = this.getPreference("aniplay_pref_mark_filler");
            var chapters = []
            var epList = choice.episodes
            for (var ep of epList) {
                var title = ep.title
                var num = ep.number
                var isFiller = ep.isFiller

                var scanlator = isFiller && user_mark_filler_ep ? `Filler` : null;

                var dateUpload = "createdAt" in ep ? new Date(ep.createdAt) : new Date().now()
                dateUpload = dateUpload.valueOf().toString();
                delete ep.img
                delete ep.title
                delete ep.description
                delete ep.isFiller
                var epUrl = `${anilistId}||${JSON.stringify(ep)}||${choice.providerId}`
                chapters.push({ name: `E${num}: ${title}`, url: epUrl, dateUpload, scanlator })
            }
        }


        var format = animeData.format
        if (format === "MOVIE") chapters[0].name = "Movie"

        animeData.link = `${this.source.baseUrl}/anime/${slug}`
        animeData.chapters = chapters.reverse()
        return animeData
    }


    // Sorts streams based on user preference.
    async sortStreams(streams) {
        var sortedStreams = [];
        var copyStreams = streams.slice()

        var pref = await this.getPreference("aniplay_pref_video_resolution");
        for (var stream of streams) {

            if (stream.quality.indexOf(pref) > -1) {
                sortedStreams.push(stream);
                var index = copyStreams.indexOf(stream);
                if (index > -1) {
                    copyStreams.splice(index, 1);
                }
                break;
            }
        }
        return [...sortedStreams, ...copyStreams]
    }

    // Extracts the streams url for different resolutions from a hls stream.
    async extractStreams(url, providerId) {
        const response = await new Client().get(url);
        const body = response.body;
        const lines = body.split('\n');
        var streams = [{
            url: url,
            originalUrl: url,
            quality: "auto",
        }];

        for (let i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('#EXT-X-STREAM-INF:')) {
                var resolution = lines[i].match(/RESOLUTION=(\d+x\d+)/)[1];
                var m3u8Url = lines[i + 1].trim();
                if (providerId === "anya") {
                    m3u8Url = `https://prox.uqable.easypanel.host${m3u8Url}`
                } else if (providerId === "yuki") {
                    var orginalUrl = url
                    m3u8Url = orginalUrl.replace("master.m3u8", m3u8Url)
                }
                streams.push({
                    url: m3u8Url,
                    originalUrl: m3u8Url,
                    quality: `${resolution} - ${providerId}`,
                });
            }
        }
        return streams

    }

    async getAnyaStreams(result) {
        var m3u8Url = result.sources[0].url
        m3u8Url = `https://prox.uqable.easypanel.host/fetch?url=${m3u8Url}&ref=https://anix.sh`
        return await this.extractStreams(m3u8Url, "anya");
    }

    async getYukiStreams(result) {
        var m3u8Url = result.sources[0].url
        var streams = await this.extractStreams(m3u8Url, "yuki");


        var subtitles = result.tracks
        streams[0].subtitles = subtitles

        return streams
    }

    // For anime episode video list
    async getVideoList(url) {
        var urlSplits = url.split("||")
        var anilistId = urlSplits[0]
        var epData = JSON.parse(urlSplits[1])
        var providerId = urlSplits[2]

        var user_audio_type = this.getPreference("aniplay_pref_audio_type");
        var subOrDub = epData.hasDub && user_audio_type === "dub" ? "dub" : "sub"

        var slug = `watch/${anilistId}`
        var body = [
            anilistId,
            providerId,
            epData.id,
            epData.number.toString(),
            subOrDub
        ]
        var result = await this.aniplayRequest(slug, body)
        if (result === null) {
            throw new Error("Error: No data found for the given URL");
        }

        var streams = []
        if (providerId == "anya") {
            streams = await this.getAnyaStreams(result)
        }
        else {
            streams = await this.getYukiStreams(result)
        }

        return await this.sortStreams(streams)

    }

    getSourcePreferences() {
        return [
            {
                "key": "aniplay_pref_title",
                "listPreference": {
                    "title": "Preferred Title",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": ["Romaji", "English", "Native"],
                    "entryValues": ["romaji", "english", "native"],
                }
            },
            {
                "key": "aniplay_pref_provider_new",
                "listPreference": {
                    "title": "Preferred provider",
                    "summary": "",
                    "valueIndex": 0,
                    "entries": ["All", "Anya", "Yuki"],
                    "entryValues": ["all", "anya", "yuki"],
                }
            }, {
                "key": "aniplay_pref_mark_filler",
                "switchPreferenceCompat": {
                    "title": "Mark filler episodes",
                    "summary": "Filler episodes will be marked with (F)",
                    "value": false
                }
            },
            {
                "key": "aniplay_pref_audio_type",
                "listPreference": {
                    "title": "Preferred audio type",
                    "summary": "Sub/Dub",
                    "valueIndex": 0,
                    "entries": ["Sub", "Dub"],
                    "entryValues": ["sub", "dub"],
                }
            }, {
                key: 'aniplay_pref_video_resolution',
                listPreference: {
                    title: 'Preferred video resolution',
                    summary: '',
                    valueIndex: 0,
                    entries: ["Auto", "1080p", "720p", "480p", "360p"],
                    entryValues: ["auto", "1080", "720", "480", "360"]
                }
            },

        ]
    }
}
