import 'dart:ffi';

import 'package:flutter/material.dart';

typedef void BitMaskChangeCallback(int register, int oldValue, int newValue);

class BitMask extends StatelessWidget {
  const BitMask(
      {super.key,
      required this.label,
      required this.changeCallback,
      required this.register,
      required this.value,
      required this.enabled
      });

  final BitMaskChangeCallback? changeCallback;
  final String? label;
  final int register;
  final int value;
  final bool enabled;

  bool _checkBit(int value, int bit) {
    return (value & (1 << bit)) != 0;
  }

  int _setBit(int value, int position, bool high) {
    int b = high ? 1 : 0;
    int mask = 1 << position;
    return ((value & ~mask) | (b << position));
  }

  Widget _getCheckBoxColumn(int bit) {
    var readValue = value;
    return Column(
      children: [
        Text("Bit $bit"),
        Checkbox(
            value: _checkBit(readValue, bit),
            onChanged: enabled && changeCallback != null && changeCallback != null
                ? (enabled) => changeCallback!(register, readValue,
                    _setBit(readValue, bit, enabled ?? false))
                : null)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const padding = 20.0;
    return Card(
        child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.data_array),
          title: Text(label != null
              ? "$label (0x${register.toRadixString(16).padLeft(2, "0").toUpperCase()})"
              : "Register: 0x${register.toRadixString(16).padLeft(2, "0").toUpperCase()}"),
          subtitle: Text("Value: 0x${value.toRadixString(16).padLeft(2, "0").toUpperCase()}"),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
          child: Row(
            children: <Widget>[
              _getCheckBoxColumn(7),
              const SizedBox(
                width: padding,
              ),
              _getCheckBoxColumn(6),
              const SizedBox(
                width: padding,
              ),
              _getCheckBoxColumn(5),
              const SizedBox(
                width: padding,
              ),
              _getCheckBoxColumn(4),
              const SizedBox(
                width: padding,
              ),
              _getCheckBoxColumn(3),
              const SizedBox(
                width: padding,
              ),
              _getCheckBoxColumn(2),
              const SizedBox(
                width: padding,
              ),
              _getCheckBoxColumn(1),
              const SizedBox(
                width: padding,
              ),
              _getCheckBoxColumn(0),
            ],
          ),
        )
      ],
    ));
  }
}
