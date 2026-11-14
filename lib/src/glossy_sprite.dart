import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Complete, transparent 4-column source sheet exported by the asset pipeline.
/// This is an artwork candidate; displaying it does not imply visual approval.
@immutable
class GlossySpriteSpec {
  const GlossySpriteSpec({
    required this.assetPath,
    required this.frames,
    required this.columns,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameDurationMs,
    required this.loop,
  })  : assert(frames > 0),
        assert(columns > 0),
        assert(frameWidth > 0),
        assert(frameHeight > 0),
        assert(frameDurationMs > 0);

  final String assetPath;
  final int frames;
  final int columns;
  final int frameWidth;
  final int frameHeight;
  final int frameDurationMs;
  final bool loop;

  static const dogRecovering = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/dog/recovering/sheet.png',
    frames: 12,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 130,
    loop: false,
  );

  static const dogFocus = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/dog/focus/sheet.png',
    frames: 12,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 135,
    loop: false,
  );

  static const dogStudy = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/dog/study/sheet.png',
    frames: 12,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 140,
    loop: false,
  );

  static const dogDone = GlossySpriteSpec(
    assetPath: 'assets/characters-v2/dog/done/sheet.png',
    frames: 12,
    columns: 4,
    frameWidth: 256,
    frameHeight: 256,
    frameDurationMs: 125,
    loop: false,
  );
}

/// Pure frame indexing: one-shot progress 1.0 holds the final pose.
int glossyFrameIndex(double progress, int frames) {
  assert(frames > 0);
  if (!progress.isFinite || progress <= 0) return 0;
  if (progress >= 1) return frames - 1;
  return (progress * frames).floor();
}

/// Paints only the selected PNG atlas rectangle. Never paints a background,
/// panel or simulated checkerboard: source alpha is preserved on the canvas.
/// The controller respects TickerMode and MediaQuery.disableAnimations.
class GlossySprite extends StatefulWidget {
  const GlossySprite({
    super.key,
    required this.spec,
    required this.semanticLabel,
    this.size = 112,
  }) : assert(size > 0);

  final GlossySpriteSpec spec;
  final String semanticLabel;
  final double size;

  @override
  State<GlossySprite> createState() => _GlossySpriteState();
}

class _GlossySpriteState extends State<GlossySprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _atlas;
  String? _error;
  bool _reducedMotion = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
    );
    _loadSheet();
  }

  Duration get _duration =>
      Duration(milliseconds: widget.spec.frames * widget.spec.frameDurationMs);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced == _reducedMotion) return;
    _reducedMotion = reduced;
    if (reduced) {
      _controller.stop();
      _controller.value = 1; // final calm pose, no flashing or movement
    } else if (_atlas != null) {
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant GlossySprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = _duration;
    if (widget.spec.assetPath != oldWidget.spec.assetPath) {
      _loadSheet();
    } else if (widget.spec.frames != oldWidget.spec.frames ||
        widget.spec.frameDurationMs != oldWidget.spec.frameDurationMs ||
        widget.spec.loop != oldWidget.spec.loop) {
      _play();
    }
  }

  Future<void> _loadSheet() async {
    final generation = ++_loadGeneration;
    _controller.stop();
    _atlas?.dispose();
    _atlas = null;
    _error = null;
    ui.Image? decoded;
    try {
      final bytes = await rootBundle.load(widget.spec.assetPath);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      try {
        final frame = await codec.getNextFrame();
        decoded = frame.image;
      } finally {
        codec.dispose();
      }
      final spec = widget.spec;
      final rows = (spec.frames + spec.columns - 1) ~/ spec.columns;
      if (decoded.width != spec.columns * spec.frameWidth ||
          decoded.height != rows * spec.frameHeight) {
        throw StateError('Sprite geometry does not match metadata');
      }
      if (!mounted || generation != _loadGeneration) {
        decoded.dispose();
        return;
      }
      setState(() => _atlas = decoded);
      _play();
    } catch (_) {
      decoded?.dispose();
      if (mounted && generation == _loadGeneration) {
        setState(() => _error = 'Không tải được hoạt ảnh.');
      }
    }
  }

  void _play() {
    _controller.stop();
    if (_reducedMotion) {
      _controller.value = 1;
    } else if (widget.spec.loop) {
      _controller.repeat(from: 0);
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    ++_loadGeneration;
    _controller.dispose();
    _atlas?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: _error != null
            ? Center(child: Text(_error!, textAlign: TextAlign.center))
            : _atlas == null
                ? const SizedBox.shrink()
                : RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CustomPaint(
                        painter: _GlossySpritePainter(
                          atlas: _atlas!,
                          spec: widget.spec,
                          frame: glossyFrameIndex(
                            _controller.value,
                            widget.spec.frames,
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _GlossySpritePainter extends CustomPainter {
  const _GlossySpritePainter({
    required this.atlas,
    required this.spec,
    required this.frame,
  });

  final ui.Image atlas;
  final GlossySpriteSpec spec;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final col = frame % spec.columns;
    final row = frame ~/ spec.columns;
    final source = Rect.fromLTWH(
      col * spec.frameWidth.toDouble(),
      row * spec.frameHeight.toDouble(),
      spec.frameWidth.toDouble(),
      spec.frameHeight.toDouble(),
    );
    final dest = Offset.zero & size;
    canvas.drawImageRect(
      atlas,
      source,
      dest,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _GlossySpritePainter oldDelegate) =>
      oldDelegate.atlas != atlas ||
      oldDelegate.frame != frame ||
      oldDelegate.spec != spec;
}
