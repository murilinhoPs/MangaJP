import 'dart:typed_data';
import 'dart:ui';

/// Prefix the native reader feeds [imageSizeFromHeader] (PNG IHDR, WebP
/// dimension bytes, typical JPEG APP1 + SOF). See `page_image_io.dart`.
const kPageImageHeaderCap = 128 * 1024;

/// File format from magic bytes (not the path extension).
enum ImageMagic { png, jpeg, webp, unknown }

/// PNG signature (8 bytes).
const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

/// Classifies [bytes] by magic. Extension is ignored.
ImageMagic detectImageMagic(List<int> bytes) {
  if (_startsWith(bytes, pngSignature)) {
    return ImageMagic.png;
  }
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return ImageMagic.jpeg;
  }
  if (_isWebp(bytes)) {
    return ImageMagic.webp;
  }
  return ImageMagic.unknown;
}

/// Pixel size from a header prefix. No full-image decode.
///
/// JPEG APP1/EXIF can sit before SOF, so pass more than 24 bytes for JPEG.
/// Orientation 5–8 swaps width and height to match Flutter's JPEG codec.
Size? imageSizeFromHeader(List<int> header) {
  switch (detectImageMagic(header)) {
    case ImageMagic.png:
      return pngSizeFromHeader(header);
    case ImageMagic.jpeg:
      return jpegSizeFromHeader(header);
    case ImageMagic.webp:
      return webpSizeFromHeader(header);
    case ImageMagic.unknown:
      return null;
  }
}

/// Parses width × height from a PNG signature + IHDR (24 bytes).
Size? pngSizeFromHeader(List<int> header) {
  if (header.length < 24) {
    return null;
  }
  for (var i = 0; i < pngSignature.length; i++) {
    if (header[i] != pngSignature[i]) {
      return null;
    }
  }
  final bytes = Uint8List.fromList(header.sublist(0, 24));
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  if (width == 0 || height == 0) {
    return null;
  }
  return Size(width.toDouble(), height.toDouble());
}

/// SOF width × height. EXIF orientation 5–8 swaps the pair.
Size? jpegSizeFromHeader(List<int> header) {
  if (header.length < 4 || header[0] != 0xFF || header[1] != 0xD8) {
    return null;
  }
  var i = 2;
  var orientation = 1;
  while (i < header.length) {
    if (header[i] != 0xFF) {
      return null;
    }
    while (i < header.length && header[i] == 0xFF) {
      i++;
    }
    if (i >= header.length) {
      return null;
    }
    final marker = header[i++];
    if (marker == 0xD9 || marker == 0xDA) {
      return null;
    }
    if (marker >= 0xD0 && marker <= 0xD7 || marker == 0x01 || marker == 0xD8) {
      continue;
    }
    if (i + 1 >= header.length) {
      return null;
    }
    final length = (header[i] << 8) | header[i + 1];
    if (length < 2) {
      return null;
    }
    final payloadStart = i + 2;
    final payloadEnd = i + length;
    if (payloadEnd > header.length) {
      return null;
    }
    if (_isSof(marker)) {
      if (payloadStart + 4 >= header.length) {
        return null;
      }
      final height = (header[payloadStart + 1] << 8) | header[payloadStart + 2];
      final width = (header[payloadStart + 3] << 8) | header[payloadStart + 4];
      if (width == 0 || height == 0) {
        return null;
      }
      if (orientation >= 5 && orientation <= 8) {
        return Size(height.toDouble(), width.toDouble());
      }
      return Size(width.toDouble(), height.toDouble());
    }
    if (marker == 0xE1) {
      final parsed = _jpegExifOrientation(header, payloadStart, payloadEnd);
      if (parsed != null) {
        orientation = parsed;
      }
    }
    i = payloadEnd;
  }
  return null;
}

/// VP8 / VP8L / VP8X canvas size from a RIFF/WEBP prefix.
///
/// Simple WebP (no VP8X) stores the whole bitstream in one `VP8 `/`VP8L`
/// chunk. The page reader only feeds a header prefix, so this parser needs
/// just the dimension bytes (`payload + 10` / `payload + 5`), not the rest
/// of the chunk.
Size? webpSizeFromHeader(List<int> header) {
  if (!_isWebp(header) || header.length < 16) {
    return null;
  }
  var offset = 12;
  while (offset + 8 <= header.length) {
    final tag = String.fromCharCodes(header.sublist(offset, offset + 4));
    final size =
        header[offset + 4] |
        (header[offset + 5] << 8) |
        (header[offset + 6] << 16) |
        (header[offset + 7] << 24);
    final payload = offset + 8;
    final payloadEnd = payload + size;
    switch (tag) {
      case 'VP8X':
        if (size < 10 || payload + 10 > header.length) {
          return null;
        }
        final width =
            1 +
            (header[payload + 4] |
                (header[payload + 5] << 8) |
                (header[payload + 6] << 16));
        final height =
            1 +
            (header[payload + 7] |
                (header[payload + 8] << 8) |
                (header[payload + 9] << 16));
        if (width == 0 || height == 0) {
          return null;
        }
        return Size(width.toDouble(), height.toDouble());
      case 'VP8 ':
        if (size < 10 || payload + 10 > header.length) {
          return null;
        }
        // Lossy: 3-byte frame tag, then 9d 01 2a, then 14-bit width/height.
        if (header[payload + 3] != 0x9D ||
            header[payload + 4] != 0x01 ||
            header[payload + 5] != 0x2A) {
          return null;
        }
        final width =
            (header[payload + 6] | (header[payload + 7] << 8)) & 0x3FFF;
        final height =
            (header[payload + 8] | (header[payload + 9] << 8)) & 0x3FFF;
        if (width == 0 || height == 0) {
          return null;
        }
        return Size(width.toDouble(), height.toDouble());
      case 'VP8L':
        if (size < 5 || payload + 5 > header.length) {
          return null;
        }
        if (header[payload] != 0x2F) {
          return null;
        }
        final bits =
            header[payload + 1] |
            (header[payload + 2] << 8) |
            (header[payload + 3] << 16) |
            (header[payload + 4] << 24);
        final width = (bits & 0x3FFF) + 1;
        final height = ((bits >> 14) & 0x3FFF) + 1;
        if (width == 0 || height == 0) {
          return null;
        }
        return Size(width.toDouble(), height.toDouble());
      default:
        if (payloadEnd > header.length) {
          return null;
        }
        break;
    }
    offset = payloadEnd + (size.isOdd ? 1 : 0);
  }
  return null;
}

bool _startsWith(List<int> bytes, List<int> prefix) {
  if (bytes.length < prefix.length) {
    return false;
  }
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) {
      return false;
    }
  }
  return true;
}

bool _isWebp(List<int> bytes) {
  if (bytes.length < 12) {
    return false;
  }
  return bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
}

bool _isSof(int marker) {
  return marker == 0xC0 ||
      marker == 0xC1 ||
      marker == 0xC2 ||
      marker == 0xC3 ||
      marker == 0xC5 ||
      marker == 0xC6 ||
      marker == 0xC7 ||
      marker == 0xC9 ||
      marker == 0xCA ||
      marker == 0xCB ||
      marker == 0xCD ||
      marker == 0xCE ||
      marker == 0xCF;
}

int? _jpegExifOrientation(List<int> header, int start, int end) {
  // APP1 payload: "Exif\0\0" + TIFF.
  if (end - start < 14) {
    return null;
  }
  if (header[start] != 0x45 ||
      header[start + 1] != 0x78 ||
      header[start + 2] != 0x69 ||
      header[start + 3] != 0x66 ||
      header[start + 4] != 0 ||
      header[start + 5] != 0) {
    return null;
  }
  final tiff = start + 6;
  final little = header[tiff] == 0x49 && header[tiff + 1] == 0x49;
  final big = header[tiff] == 0x4D && header[tiff + 1] == 0x4D;
  if (!little && !big) {
    return null;
  }
  int u16(int offset) {
    if (little) {
      return header[offset] | (header[offset + 1] << 8);
    }
    return (header[offset] << 8) | header[offset + 1];
  }

  int u32(int offset) {
    if (little) {
      return header[offset] |
          (header[offset + 1] << 8) |
          (header[offset + 2] << 16) |
          (header[offset + 3] << 24);
    }
    return (header[offset] << 24) |
        (header[offset + 1] << 16) |
        (header[offset + 2] << 8) |
        header[offset + 3];
  }

  if (u16(tiff + 2) != 42) {
    return null;
  }
  final ifd = tiff + u32(tiff + 4);
  if (ifd + 2 > end) {
    return null;
  }
  final count = u16(ifd);
  for (var n = 0; n < count; n++) {
    final entry = ifd + 2 + n * 12;
    if (entry + 12 > end) {
      return null;
    }
    if (u16(entry) != 0x0112) {
      continue;
    }
    final type = u16(entry + 2);
    final countField = u32(entry + 4);
    if (countField < 1) {
      return null;
    }
    // SHORT / USHORT: value is inline in the 4-byte field.
    if (type == 3) {
      return u16(entry + 8);
    }
    return null;
  }
  return null;
}
