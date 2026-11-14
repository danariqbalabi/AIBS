import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../core/theme/aibs_tokens.dart';
import '../widgets/aibs_widgets.dart';
import 'photo_upload.dart';

Future<Uint8List?> captureBrowserPhoto(BuildContext context) =>
    Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const _BrowserCameraPage()),
    );

class _BrowserCameraPage extends StatefulWidget {
  const _BrowserCameraPage();
  @override
  State<_BrowserCameraPage> createState() => _BrowserCameraPageState();
}

class _BrowserCameraPageState extends State<_BrowserCameraPage> {
  final _video = web.HTMLVideoElement()
    ..autoplay = true
    ..muted = true
    ..playsInline = true;
  web.MediaStream? _stream;
  String? _error;
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _video.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'contain';
    _start();
  }

  Future<void> _start() async {
    try {
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              video: {
                'facingMode': {'ideal': 'environment'},
              }.jsify()!,
              audio: false.toJS,
            ),
          )
          .toDart;
      if (!mounted) {
        for (final track in stream.getTracks().toDart) {
          track.stop();
        }
        return;
      }
      _stream = stream;
      _video.srcObject = stream;
      await _video.play().toDart;
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Kamera belum bisa dibuka. Izinkan kamera di pengaturan browser, atau pilih foto dari galeri.',
        );
      }
    }
  }

  Future<void> _capture() async {
    if (!_ready || _busy || _video.videoWidth == 0) return;
    setState(() => _busy = true);
    try {
      final scale = _video.videoWidth > 1600 ? 1600 / _video.videoWidth : 1.0;
      final canvas = web.HTMLCanvasElement()
        ..width = (_video.videoWidth * scale).round()
        ..height = (_video.videoHeight * scale).round();
      (canvas.getContext('2d') as web.CanvasRenderingContext2D).drawImage(
        _video,
        0,
        0,
        canvas.width,
        canvas.height,
      );
      final bytes = preparePhotoUpload(
        base64Decode(canvas.toDataURL('image/jpeg', 0.85.toJS).split(',').last),
      );
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Foto belum berhasil diambil. Coba lagi atau pilih dari galeri.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final track
        in _stream?.getTracks().toDart ?? <web.MediaStreamTrack>[]) {
      track.stop();
    }
    _video.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kamera makanan')),
    body: Column(
      children: [
        Expanded(
          child: HtmlElementView.fromTagName(
            tagName: 'div',
            onElementCreated: (element) =>
                (element as web.HTMLDivElement).append(_video),
          ),
        ),
        if (!_ready && _error == null) const LinearProgressIndicator(),
        Padding(
          padding: AibsSpace.bottomActions,
          child: Column(
            children: [
              if (_error != null) Text(_error!),
              AibsPrimaryButton(
                label: _busy ? 'Mengambil foto...' : 'Ambil foto',
                onPressed: _ready && !_busy ? _capture : null,
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali ke pilihan foto'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
