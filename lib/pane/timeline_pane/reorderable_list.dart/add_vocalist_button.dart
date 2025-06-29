import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

class AddVocalistButton extends StatefulWidget {
  final double width;
  final double height;

  AddVocalistButton({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key) { }

  @override
  AddVocalistButtonState createState() => AddVocalistButtonState();
}

class AddVocalistButtonState extends State<AddVocalistButton> {
  bool _selected = false;

  @override
  void initState() {
    super.initState();
  }

  void changeColor() {
    _selected = !_selected;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: (){}, child: const Text("+ Vocalist"),);
  }
}

/*
  Widget cellVocalistPanel(int index) {
    final Map<VocalistID, Vocalist> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap.map;
    final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];
    final String vocalistName = vocalistColorMap.values.toList()[index].name;
    if (edittingVocalistIndex == index) {
      final TextEditingController controller = TextEditingController(text: vocalistName);
      oldVocalistValue = vocalistName;
      return TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          edittingVocalistIndex = -1;
          final TimingService timingService = ref.read(timingMasterProvider);
          if (value == "") {
            timingService.removeVocalistByName(oldVocalistValue);
          } else if (oldVocalistValue != value) {
            cursorBlinker.restartCursorTimer();
            timingService.changeVocalistName(oldVocalistValue, value);
          }
          setState(() {});
        },
      );
    } else {
      final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
      final List<VocalistID> selectingVocalist = timelinePaneProvider.selectingVocalist;

      return LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (TapDownDetails details) {
              if (selectingVocalist.contains(vocalistID)) {
                selectingVocalist.remove(vocalistID);
              } else {
                selectingVocalist.add(vocalistID);
              }
              setState(() {});
            },
            onDoubleTap: () async {
              List<String> oldVocalistNames = vocalistName.split(", ");
              List<String> newVocalistNames = await displayTextFieldDialog(context, oldVocalistNames);
              for (int i = 0; i < oldVocalistNames.length; i++) {
                String oldName = oldVocalistNames[i];
                String newName = newVocalistNames[i];
                final TimingService timingService = ref.read(timingMasterProvider);
                if (newName == "") {
                  timingService.removeVocalistByName(oldName);
                } else if (oldName != newName) {
                  timingService.changeVocalistName(oldName, newName);
                }
              }
            },
            child: CustomPaint(
              size: Size(135, constraints.maxHeight),
              painter: RectanglePainter(
                rect: Rect.fromLTRB(0.0, 0.0, 135, constraints.maxHeight),
                sentence: vocalistName,
                color: Color(vocalistColorMap[vocalistID]!.color),
                isSelected: selectingVocalist.contains(vocalistID),
                borderLineWidth: 1.0,
              ),
            ),
          );
        },
      );
    }
  }
*/