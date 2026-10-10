/// How a list of entries is shown. Remembered per type on the device.
enum EntryView { text, listWithPhotos, grid }

extension EntryViewLabel on EntryView {
  String get label => switch (this) {
    EntryView.text => 'Text',
    EntryView.listWithPhotos => 'List with photos',
    EntryView.grid => 'Grid',
  };
}
