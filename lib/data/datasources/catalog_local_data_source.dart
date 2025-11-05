import 'package:mini_music_test_app/data/models/track_model.dart';

abstract class CatalogLocalDataSource {
  Future<List<TrackModel>> loadCatalog();
}

class AssetCatalogDataSource implements CatalogLocalDataSource {
  AssetCatalogDataSource({this.assetPath = 'assets/catalog/catalog.json'});

  final String assetPath;

  @override
  Future<List<TrackModel>> loadCatalog() => TrackModel.loadFromAsset(assetPath);
}
