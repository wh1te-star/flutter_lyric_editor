import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    await tester.takeScreenshot(name: "my-screenshot-1"); // 👈

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    await tester.takeScreenshot(name: "my-screenshot-2"); // 👈

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

extension WidgetTesterScreenshot on WidgetTester {
  Future<void> takeScreenshot({required String name}) async {
    final liveElement = binding.rootElement!;

    late final Uint8List bytes;
    await binding.runAsync(() async {
      final image = await _captureImage(liveElement);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return 'Could not take screenshot';
      }
      bytes = byteData.buffer.asUint8List();
      image.dispose();
    });

    final directory = Directory('./screenshots');
    if (!directory.existsSync()) {
      directory.createSync();
    }
    File('./screenshots/$name.png').writeAsBytesSync(bytes);
  }

  Future<ui.Image> _captureImage(Element element) async {
    assert(element.renderObject != null);
    var renderObject = element.renderObject!;
    while (!renderObject.isRepaintBoundary) {
      renderObject = renderObject.parent! as RenderObject;
    }
    assert(!renderObject.debugNeedsPaint);

    final layer = renderObject.debugLayer! as OffsetLayer;
    final image = await layer.toImage(renderObject.paintBounds);

    if (element.renderObject is RenderBox) {
      final expectedSize = (element.renderObject as RenderBox?)!.size;
      if (expectedSize.width != image.width ||
          expectedSize.height != image.height) {
        final el = element.toStringShort();
        // ignore: avoid_print
        print(
          'Warning: The screenshot captured of $el is '
          'larger (${image.width}, ${image.height}) than '
          '$el (${expectedSize.width}, ${expectedSize.height}) itself.\n'
          'Wrap the $el in a RepaintBoundary to be able to capture only that layer.',
        );
      }
    }

    return image;
  }
}