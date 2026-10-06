import 'package:manga_jp/features/capture/data/image_source_service.dart';
import 'package:manga_jp/features/capture/domain/incoming_image.dart';

/// Test double for [ImageSourceService]. Never opens `image_picker`.
class FakeImageSourceService extends ImageSourceService {
  FakeImageSourceService({this.galleryImage, this.initial});

  final IncomingImage? galleryImage;
  final IncomingImage? initial;
  int galleryCalls = 0;

  @override
  Stream<IncomingImage> get mediaStream => const Stream.empty();

  @override
  Future<IncomingImage?> initialMedia() async => initial;

  @override
  Future<IncomingImage?> pickFromGallery() async {
    galleryCalls++;
    return galleryImage;
  }
}
