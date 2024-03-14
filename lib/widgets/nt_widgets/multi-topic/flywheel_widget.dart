import 'dart:math';

import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';
import 'package:transitioned_indexed_stack/transitioned_indexed_stack.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'package:elastic_dashboard/services/nt_connection.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_toggle_switch.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class BasicFlywheelModel extends NTWidgetModel {
  @override
  String type = FlywheelViewWidget.widgetType;

  get angleTopic => '$topic/Angler Position';

  get goalAngleTopic => '$topic/Angler Setpoint';

  get pidDoneTopic => '$topic/Angler PID Done';

  get bflywheelVelocityTopic => '$topic/Bottom Flywheel Velocity';

  get tflywheelVelocityTopic => '$topic/Top Flywheel Velocity';

  get tflywheelSetpointTopic => '$topic/Top Flywheel Setpoint';

  get bflywheelSetpointTopic => '$topic/Bottom Flywheel Setpoint';

  bool _showRotation = true;

  String _rotationUnit = 'Radians';

  BasicFlywheelModel({
    required super.topic,
    bool showRotation = true,
    String rotationUnit = 'Radians',
    super.period,
    super.dataType,
  })  : _rotationUnit = rotationUnit,
        _showRotation = showRotation,
        super();

  BasicFlywheelModel.fromJson({required Map<String, dynamic> jsonData})
      : super.fromJson(jsonData: jsonData) {
    _showRotation = tryCast(jsonData['show_rotation']) ?? true;
    _rotationUnit = tryCast(jsonData['rotation_unit']) ?? 'Degrees';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'show_rotation': _showRotation,
      'rotation_unit': _rotationUnit,
    };
  }

  @override
  List<Widget> getEditProperties(BuildContext context) {
    return [
      Center(
        child: DialogToggleSwitch(
          initialValue: _showRotation,
          label: 'Show Rotation',
          onToggle: (value) {
            showRotation = value;
          },
        ),
      ),
      const SizedBox(height: 5),
      const Text('Rotation Unit'),
      StatefulBuilder(builder: (context, setState) {
        return Column(
          children: [
            ListTile(
              title: const Text('Radians'),
              dense: true,
              leading: Radio(
                value: 'Radians',
                groupValue: _rotationUnit,
                onChanged: (value) {
                  rotationUnit = 'Radians';

                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Degrees'),
              dense: true,
              leading: Radio(
                value: 'Degrees',
                groupValue: _rotationUnit,
                onChanged: (value) {
                  rotationUnit = 'Degrees';

                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Rotations'),
              dense: true,
              leading: Radio(
                value: 'Rotations',
                groupValue: _rotationUnit,
                onChanged: (value) {
                  rotationUnit = 'Rotations';

                  setState(() {});
                },
              ),
            ),
          ],
        );
      }),
    ];
  }

  @override
  List<Object> getCurrentData() {
    double anglerAngle =
        tryCast(ntConnection.getLastAnnouncedValue(angleTopic)) ?? 0.0;

    double anglerGoal =
        tryCast(ntConnection.getLastAnnouncedValue(goalAngleTopic)) ?? 0.0;

    bool anglerAtGoal =
        tryCast(ntConnection.getLastAnnouncedValue(pidDoneTopic)) ?? false;

    double tflywheelVelocity =
        tryCast(ntConnection.getLastAnnouncedValue(tflywheelVelocityTopic)) ??
            0.0;

    double bflywheelVelocity =
        tryCast(ntConnection.getLastAnnouncedValue(bflywheelVelocityTopic)) ??
            0.0;

    double bflywheelSetpoint =
        tryCast(ntConnection.getLastAnnouncedValue(bflywheelSetpointTopic)) ??
            0.0;

    double tflywheelSetpoint =
        tryCast(ntConnection.getLastAnnouncedValue(tflywheelSetpointTopic)) ??
            0.0;

    return [
      anglerAngle,
      anglerGoal,
      anglerAtGoal,
      tflywheelVelocity,
      bflywheelVelocity,
      tflywheelSetpoint,
      bflywheelSetpoint,
    ];
  }

  get showRotation => _showRotation;

  set showRotation(value) {
    _showRotation = value;
    refresh();
  }

  get rotationUnit => _rotationUnit;

  set rotationUnit(value) {
    _rotationUnit = value;
    refresh();
  }
}

class FlywheelViewWidget extends NTWidget {
  static const String widgetType = 'Flywheel System';

  const FlywheelViewWidget({super.key}) : super();

  @override
  Widget build(BuildContext context) {
    BasicFlywheelModel model = cast(context.watch<NTWidgetModel>());

    return StreamBuilder(
      stream: model.multiTopicPeriodicStream,
      builder: (context, snapshot) {
        double anglerAngle1 =
            tryCast(ntConnection.getLastAnnouncedValue(model.angleTopic)) ??
                0.0;

        double anglerGoal =
            tryCast(ntConnection.getLastAnnouncedValue(model.goalAngleTopic)) ??
                0.0;

        bool anglerAtGoal =
            tryCast(ntConnection.getLastAnnouncedValue(model.pidDoneTopic)) ??
                false;

        double topflyWheelVelocity = tryCast(ntConnection
                .getLastAnnouncedValue(model.tflywheelVelocityTopic)) ??
            0.0;

        double botflyWheelVelocity = tryCast(ntConnection
                .getLastAnnouncedValue(model.bflywheelVelocityTopic)) ??
            0.0;

        double botflyWheelSetpoint = tryCast(ntConnection
                .getLastAnnouncedValue(model.bflywheelSetpointTopic)) ??
            0.0;

        double topflyWheelSetpoint = tryCast(ntConnection
                .getLastAnnouncedValue(model.tflywheelSetpointTopic)) ??
            0.0;

        if (model.rotationUnit == 'Degrees') {
          anglerAngle1 = radians(anglerAngle1);
          anglerGoal = radians(anglerGoal);
        } else if (model.rotationUnit == 'Rotations') {
          anglerAngle1 *= 2 * pi;
          anglerGoal *= 2 * pi;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            double sideLength =
                min(constraints.maxWidth, constraints.maxHeight) * 0.9;
            return Column(
              children: [
                const SizedBox(height: 2.5),
                const Text('Visualizer'),
                const SizedBox(height: 10),
                Transform.rotate(
                  angle: (model.showRotation) ? -anglerAngle1 : 0.0,
                  child: SizedBox(
                    width: sideLength,
                    height: sideLength,
                    child: CustomPaint(
                      painter: DualFlywheelAnglerPainter(
                        flywheelAngle: -anglerAngle1,
                        topflywheelVelocity: topflyWheelVelocity,
                        bottomflyhweelVelocity: botflyWheelVelocity,
                        targetAngle: -anglerGoal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Text('Top Flywheel Setpoint'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade700,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          topflyWheelSetpoint.toStringAsPrecision(3),
                          maxLines: 1,
                          showCursor: true,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.5),
                Row(
                  children: [
                    const Text('Top Flywheel Velocity'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade700,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          topflyWheelVelocity.toStringAsPrecision(3),
                          maxLines: 1,
                          showCursor: true,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.5),
                Row(
                  children: [
                    const Text('Bottom Flywheel Setpoint'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade700,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          botflyWheelSetpoint.toStringAsPrecision(3),
                          maxLines: 1,
                          showCursor: true,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.5),
                Row(
                  children: [
                    const Text('Bottom Flywheel Velocity'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade700,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          botflyWheelVelocity.toStringAsPrecision(3),
                          maxLines: 1,
                          showCursor: true,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.5),
                Row(
                  children: [
                    const Text('Angler Angle'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade700,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          anglerAngle1.toStringAsPrecision(4),
                          maxLines: 1,
                          showCursor: true,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.5),
                Row(
                  children: [
                    const Text('Angler Setpoint'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade700,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          anglerGoal.toStringAsPrecision(3),
                          maxLines: 1,
                          showCursor: true,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class DualFlywheelAnglerPainter extends CustomPainter {
  final double flywheelAngle;
  final double topflywheelVelocity;
  final double bottomflyhweelVelocity;
  final double targetAngle;

  const DualFlywheelAnglerPainter({
    required this.flywheelAngle,
    required this.topflywheelVelocity,
    required this.bottomflyhweelVelocity,
    required this.targetAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double flywheelScale = 0.2; // Adjust flywheel size
    const double gapSize = 0.35; // Adjust gap between flywheels
    const double axisWidth = 5.0; // Adjust axis line width

    drawFlywheel(
        canvas,
        size * flywheelScale,
        Offset(size.width / 2,
            size.height * (1 - flywheelScale - gapSize / 2.0) / 2));

    drawFlywheel(
        canvas,
        size * flywheelScale,
        Offset(size.width / 2,
            size.height * (1 + flywheelScale + gapSize / 2.0) / 2));

    //Bottom
    drawFlywheelMotionArrow(
        canvas,
        size * flywheelScale,
        Offset(size.width / 2,
            size.height * (1 - flywheelScale - gapSize / 2.0) / 2),
        topflywheelVelocity);

    drawFlywheelMotionArrow(
        canvas,
        size * flywheelScale,
        Offset(size.width / 2,
            size.height * (1 + flywheelScale + gapSize / 2.0) / 2),
        bottomflyhweelVelocity);

    ///Goal line
    /*
    canvas.drawLine(
      Offset(size.width / 2, 0), // Start at the same center point
      Offset(
        size.width / 2 +
            cos(targetAngle - flywheelAngle) * // Adjust based on angle
                (min(size.width, size.height) /
                    2), // Adjust length based on radius
        size.height / 2 +
            sin(targetAngle - flywheelAngle) * // Adjust based on angle
                (min(size.width, size.height) /
                    2), // Adjust length based on radius
      ),
      Paint()
        ..color = Colors.red // Set color to red
        ..strokeWidth = axisWidth * 0.5, // Adjust line width
    );
    */

    // Draw fixed axis (green line)
    canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        Paint()
          ..color = const Color.fromARGB(255, 0, 0, 0)
          ..strokeWidth = axisWidth);
  }

  void drawFlywheel(Canvas canvas, Size size, Offset offset) {
    final double radius = min(size.width, size.height) / 2;
    Paint flywheelPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(offset, radius, flywheelPaint);
  }

  void drawFlywheelMotionArrow(
      Canvas canvas, Size size, Offset offset, double velocity_) {
    final double radius = min(size.width, size.height) / 2;
    const double arrowAngle = 0.0;
    const double minArrowBase = 6;
    const double maxArrowBase = 12;

    Paint arrowPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    Paint anglePaint = Paint()
      ..strokeWidth = 4
      ..color = const Color.fromARGB(255, 54, 244, 67)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Flywheel vector arrow
    if (velocity_.abs() >= 0.05) {
      double arrowAngle = this.flywheelAngle;

      arrowAngle *= -1;

      if (velocity_ < 0) {
        arrowAngle -= pi;
      }

      double arrowLength = (velocity_.abs() / 67.0)
          .clamp(-100, 100); // Adjust scaling factor as needed
      double arrowBase = (arrowLength / 3.0).clamp(minArrowBase, maxArrowBase);

      canvas.drawLine(
          offset,
          offset +
              Offset(
                  arrowLength * cos(arrowAngle), arrowLength * sin(arrowAngle)),
          arrowPaint);
      drawArrowHead(canvas, offset, arrowLength * cos(arrowAngle),
          arrowLength * sin(arrowAngle), arrowAngle, arrowBase, arrowPaint);

      drawThickArrowheadInCircle(
          canvas, offset, radius * 1.2, radius * 1.2, arrowAngle, anglePaint);
    } else {
      // Draw an X to indicate no motion
      drawX(canvas, offset, radius, anglePaint);
    }
  }

  void drawThickArrowheadInCircle(Canvas canvas, Offset circleCenter,
      double circleRadius, double width, double angle, Paint paint) {
    // Option 1 for adjusted angle (no rotation)
    // final double adjustedAngle = angle + pi - pi;

    // Option 2 for adjusted angle (add pi)
    final double adjustedAngle = angle + pi;

    // Calculate arrow tip coordinates with full width
    final double tipX =
        circleCenter.dx + cos(adjustedAngle) * (-circleRadius + width / 2);
    final double tipY =
        circleCenter.dy + sin(adjustedAngle) * (-circleRadius + width / 2);

    // Define path for arrowhead
    final Path arrowPath = Path()
      ..moveTo(circleCenter.dx + width / 2 * cos(adjustedAngle - pi / 3),
          circleCenter.dy + width / 2 * sin(adjustedAngle - pi / 3))
      ..lineTo(tipX, tipY)
      ..lineTo(circleCenter.dx + width / 2 * cos(adjustedAngle + pi / 3),
          circleCenter.dy + width / 2 * sin(adjustedAngle + pi / 3))
      ..close();

    canvas.drawPath(arrowPath, paint);
  }

  void drawArrowHead(Canvas canvas, Offset center, double tipX, double tipY,
      double arrowAngle, double base, Paint arrowPaint) {
    Path arrowPath = Path()
      ..moveTo(center.dx + tipX - base * cos(arrowAngle),
          center.dy + tipY - base * sin(arrowAngle))
      ..lineTo(center.dx + tipX, center.dy + tipY)
      ..lineTo(center.dx + tipX - base * cos(arrowAngle + pi),
          center.dy + tipY - base * sin(arrowAngle + pi));

    canvas.drawPath(arrowPath, arrowPaint);
  }

  void drawX(Canvas canvas, Offset offset, double radius, Paint xPaint) {
    canvas.drawLine(offset + Offset(radius / 2, radius / 2) * 0.75,
        offset - Offset(radius / 2, radius / 2) * 0.75, xPaint);
    canvas.drawLine(offset - Offset(-radius / 2, radius / 2) * 0.75,
        offset + Offset(-radius / 2, radius / 2) * 0.75, xPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
