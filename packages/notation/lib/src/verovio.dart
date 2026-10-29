import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Raised when Verovio can't load or draw a piece; [message] carries its log.
class NotationException implements Exception {
  const NotationException(this.message);

  final String message;

  @override
  String toString() => 'NotationException: $message';
}

typedef _CtorPathC = Pointer<Void> Function(Pointer<Utf8>);
typedef _CtorC = Pointer<Void> Function();
typedef _VoidPtrC = Void Function(Pointer<Void>);
typedef _VoidPtr = void Function(Pointer<Void>);
typedef _StrC = Pointer<Utf8> Function(Pointer<Void>);
typedef _BoolStrC = Bool Function(Pointer<Void>, Pointer<Utf8>);
typedef _BoolStr = bool Function(Pointer<Void>, Pointer<Utf8>);
typedef _IntC = Int32 Function(Pointer<Void>);
typedef _Int = int Function(Pointer<Void>);
typedef _SvgC = Pointer<Utf8> Function(Pointer<Void>, Int32, Bool);
typedef _Svg = Pointer<Utf8> Function(Pointer<Void>, int, bool);
typedef _LogC = Void Function(Bool);
typedef _Log = void Function(bool);

/// One Verovio toolkit over its C interface (`tools/c_wrapper.h`). Not thread safe: keep
/// each instance on the isolate that opened it.
class Verovio {
  Verovio._(this._toolkit, DynamicLibrary lib)
    : _destructor = lib.lookupFunction<_VoidPtrC, _VoidPtr>(
        'vrvToolkit_destructor',
      ),
      _getVersion = lib.lookupFunction<_StrC, _StrC>('vrvToolkit_getVersion'),
      _getLog = lib.lookupFunction<_StrC, _StrC>('vrvToolkit_getLog'),
      _setOptions = lib.lookupFunction<_BoolStrC, _BoolStr>(
        'vrvToolkit_setOptions',
      ),
      _loadData = lib.lookupFunction<_BoolStrC, _BoolStr>(
        'vrvToolkit_loadData',
      ),
      _getPageCount = lib.lookupFunction<_IntC, _Int>(
        'vrvToolkit_getPageCount',
      ),
      _renderToSvg = lib.lookupFunction<_SvgC, _Svg>('vrvToolkit_renderToSVG');

  /// Opens a toolkit reading its fonts from [resourcePath] (the unpacked data folder), or
  /// with no fonts at all when it is null (enough for [version]).
  factory Verovio.open(String? resourcePath) {
    final lib = DynamicLibrary.open('libverovio.so');
    lib.lookupFunction<_LogC, _Log>('enableLogToBuffer')(true);
    final Pointer<Void> toolkit;
    if (resourcePath == null) {
      toolkit = lib.lookupFunction<_CtorC, _CtorC>(
        'vrvToolkit_constructorNoResource',
      )();
    } else {
      final path = resourcePath.toNativeUtf8();
      try {
        toolkit = lib.lookupFunction<_CtorPathC, _CtorPathC>(
          'vrvToolkit_constructorResourcePath',
        )(path);
      } finally {
        calloc.free(path);
      }
    }
    if (toolkit == nullptr) {
      throw const NotationException('Verovio did not start');
    }
    return Verovio._(toolkit, lib);
  }

  final Pointer<Void> _toolkit;
  final _VoidPtr _destructor;
  final _StrC _getVersion;
  final _StrC _getLog;
  final _BoolStr _setOptions;
  final _BoolStr _loadData;
  final _Int _getPageCount;
  final _Svg _renderToSvg;

  String get version => _getVersion(_toolkit).toDartString();

  /// Draws [data] (MusicXML) with [optionsJson] and returns one SVG per page.
  List<String> render(String data, String optionsJson) {
    final options = optionsJson.toNativeUtf8();
    final input = data.toNativeUtf8();
    try {
      if (!_setOptions(_toolkit, options)) {
        throw NotationException(
          'Options refused: ${_getLog(_toolkit).toDartString()}',
        );
      }
      if (!_loadData(_toolkit, input)) {
        throw NotationException(_getLog(_toolkit).toDartString());
      }
      final count = _getPageCount(_toolkit);
      final pages = [
        for (var page = 1; page <= count; page++)
          _renderToSvg(_toolkit, page, false).toDartString(),
      ];
      // A cut-off file loads without complaint and draws an empty page; treat a drawing
      // with no notes as a failure so the app falls back to the scanned music.
      if (!pages.any((svg) => svg.contains('class="note"'))) {
        throw NotationException(
          'Nothing to draw: ${_getLog(_toolkit).toDartString()}',
        );
      }
      return pages;
    } finally {
      calloc.free(options);
      calloc.free(input);
    }
  }

  void dispose() => _destructor(_toolkit);
}
