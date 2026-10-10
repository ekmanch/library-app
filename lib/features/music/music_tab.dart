/// The three tabs of the music list (A14). The view is remembered per tab.
enum MusicTab { artists, albums, songs }

extension MusicTabLabel on MusicTab {
  String get label => switch (this) {
    MusicTab.artists => 'Artists',
    MusicTab.albums => 'Albums',
    MusicTab.songs => 'Songs',
  };
}
