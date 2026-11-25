import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:animetint/controller/settings_provider.dart';
import 'package:material_ui/material_ui.dart';

class ProceduralFilmGrain extends StatefulWidget {
  final double intensity;
  final double scale;
  final bool animate;
  final GrainBlendMode blendMode;

  const ProceduralFilmGrain({
    super.key,
    required this.intensity,
    required this.scale,
    required this.animate,
    required this.blendMode,
  });

  @override
  State<ProceduralFilmGrain> createState() => _ProceduralFilmGrainState();
}

class _ProceduralFilmGrainState extends State<ProceduralFilmGrain>
    with SingleTickerProviderStateMixin {
  ui.Image? _noiseTile;
  late final AnimationController _ticker;
  final Random _rng = Random();
  Offset _jitterOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _generateNoiseTile();
    // 24fps celluloid film cadence
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 42),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && widget.animate) {
        setState(() {
          _jitterOffset = Offset(
            _rng.nextDouble() * 256,
            _rng.nextDouble() * 256,
          );
        });
        _ticker.forward(from: 0);
      }
    });

    if (widget.animate) _ticker.forward();
  }

  @override
  void didUpdateWidget(covariant ProceduralFilmGrain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ticker.isAnimating) {
      _ticker.forward(from: 0);
    } else if (!widget.animate && _ticker.isAnimating) {
      _ticker.stop();
      _jitterOffset = Offset.zero;
    }
  }

  Future<void> _generateNoiseTile() async {
    const int size = 256;
    final Uint8List pixels = Uint8List(size * size * 4);
    final Random rand = Random(42);

    for (int i = 0; i < pixels.length; i += 4) {
      // Gaussian-like distribution for organic film grain rather than harsh TV static
      final double n = (rand.nextDouble() + rand.nextDouble() - 1.0);
      final int lum = n > 0 ? 255 : 0;
      final int alpha = (n.abs() * 255).clamp(0, 255).toInt();

      pixels[i] = lum; // R
      pixels[i + 1] = lum; // G
      pixels[i + 2] = lum; // B
      pixels[i + 3] = alpha;
    }

    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      pixels,
    );
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: size,
      height: size,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frame = await codec.getNextFrame();

    if (mounted) {
      setState(() => _noiseTile = frame.image);
    }
  }

  BlendMode _mapBlendMode(GrainBlendMode mode) {
    switch (mode) {
      case GrainBlendMode.softLight:
        return BlendMode.softLight;
      case GrainBlendMode.overlay:
        return BlendMode.overlay;
      case GrainBlendMode.multiply:
        return BlendMode.multiply;
      case GrainBlendMode.screen:
        return BlendMode.screen;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _noiseTile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_noiseTile == null || widget.intensity <= 0.001) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _FilmGrainPainter(
        tile: _noiseTile!,
        intensity: widget.intensity,
        scale: widget.scale,
        offset: _jitterOffset,
        blendMode: _mapBlendMode(widget.blendMode),
      ),
      size: Size.infinite,
    );
  }
}

class _FilmGrainPainter extends CustomPainter {
  final ui.Image tile;
  final double intensity;
  final double scale;
  final Offset offset;
  final BlendMode blendMode;

  _FilmGrainPainter({
    required this.tile,
    required this.intensity,
    required this.scale,
    required this.offset,
    required this.blendMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Matrix4 matrix =
        Matrix4.identity()
          ..translateByDouble(offset.dx, offset.dy, 0.0, 1.0)
          ..scaleByDouble(scale, scale, 1.0, 1.0);

    final Paint paint =
        Paint()
          ..shader = ImageShader(
            tile,
            TileMode.repeated,
            TileMode.repeated,
            matrix.storage,
          )
          ..color = Colors.white.withValues(alpha: intensity)
          ..blendMode = blendMode
          ..filterQuality = FilterQuality.low;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _FilmGrainPainter old) =>
      old.intensity != intensity ||
      old.scale != scale ||
      old.offset != offset ||
      old.blendMode != blendMode ||
      old.tile != tile;
}
