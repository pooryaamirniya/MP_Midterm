typedef Json = Map<String, dynamic>;

class Track {
  final String id, title, artist, album, coverUrl, streamUrl;
  final int duration;
  final bool isFavorite;
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverUrl,
    required this.streamUrl,
    required this.duration,
    this.isFavorite = false,
  });
  factory Track.fromJson(Json j) => Track(
    id: '${j['id']}',
    title: j['title'] ?? '',
    artist: j['artist'] ?? '',
    album: j['album'] ?? '',
    coverUrl: j['cover_url'] ?? '',
    streamUrl: j['stream_url'] ?? '',
    duration: (j['duration'] as num?)?.toInt() ?? 0,
    isFavorite: j['is_favorite'] == true,
  );
}

class UserProfile {
  final String email, username, displayName;
  const UserProfile({
    required this.email,
    required this.username,
    required this.displayName,
  });
  factory UserProfile.fromJson(Json j) => UserProfile(
    email: j['email'] ?? '',
    username: j['username'] ?? '',
    displayName: j['display_name'] ?? j['username'] ?? '',
  );
  Json toJson() => {
    'email': email,
    'username': username,
    'display_name': displayName,
  };
}

class MusicPlaylist {
  final int id, count;
  final String name, description;
  final List<Track> tracks;
  const MusicPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.count,
    this.tracks = const [],
  });
  factory MusicPlaylist.fromJson(Json j) => MusicPlaylist(
    id: (j['id'] as num).toInt(),
    name: j['name'] ?? '',
    description: j['description'] ?? '',
    count: (j['track_count'] as num?)?.toInt() ?? 0,
    tracks: (j['tracks'] as List? ?? [])
        .map((e) => Track.fromJson(e as Json))
        .toList(),
  );
}

class PageResult<T> {
  final List<T> items;
  final int count;
  final bool hasNext;
  const PageResult(this.items, this.count, this.hasNext);
  factory PageResult.fromJson(Json j, T Function(Json) parse) => PageResult(
    (j['results'] as List? ?? []).map((e) => parse(e as Json)).toList(),
    (j['count'] as num?)?.toInt() ?? 0,
    j['next'] != null,
  );
}

String clockText(Duration value) {
  final seconds = value.inSeconds.clamp(0, 86400);
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
