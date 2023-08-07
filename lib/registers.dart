class Registers {
  static final Map<int, String> _SRC4392 = {
    0x03: "Port A Control Register 1",
    0x04: "Port A Control Register 2",
    0x05: "Port B Control Register 1",
    0x06: "Port B Control Register 2",
    0x07: "Transmitter Control Register 1",
    0x08: "Transmitter Control Register 2",
    0x09: "Transmitter Control Register 3",
    0x0D: "Receiver Control Register 1",
    0x0E: "Receiver Control Register 2",
    0x0F: "Receiver PLL1 Configuration Register 1",
    0x10: "Receiver PLL1 Configuration Register 2",
    0x11: "Receiver PLL1 Configuration Register 3",
    0x13: "Receiver Status Register 1 (Read-Only)",
    0x14: "Receiver Status Register 2 (Read-Only)",
    0x15: "Receiver Status Register 3 (Read-Only)",
    0x2D: "SRC Control Register 1",
    0x2E: "SRC Control Register 2",
    0x2F: "SRC Control Register 3",
    0x30: "SRC Control Register 3",
    0x31: "SRC Control Register 3"
  };

  static final List<RegCommand> _SRC4392Commands = [
    RegCommand("Power ON", 0x01, 0x3F, false),
    RegCommand("Power OFF", 0x01, 0x30, false),
    RegCommand("RESET", 0x01, 0x80, false)
  ];

  static Device _createSrcDixDevice(String label, Iterable<MapEntry<int, String>> registers, List<RegCommand> commands) {
    final registersF = registers.map((e) => MapEntry(
        e.key, RegType(
        register: e.key,
        label: e.value,
        canRead: !e.value.contains("Command"),
        canWrite: !e.value.contains("Read-Only"))
    ));
    return Device(label, Map.fromEntries(registersF), commands);
  }

  static final Device DEV_SRC4392 = _createSrcDixDevice("SRC4392", _SRC4392.entries, _SRC4392Commands);
  static final Device DEV_DIX4192 = _createSrcDixDevice("DIX4192", _SRC4392.entries.where((element) => !element.value.toUpperCase().startsWith("SRC")), _SRC4392Commands);
}

class RegCommand {
  final String label;

  final int register;
  final int value;

  final bool canRead;

  final List<String>? arguments;

  RegCommand(this.label, this.register, this.value, this.canRead, {this.arguments});
}

class Device {
  final String label;
  final Map<int, RegType> registers;
  final List<RegCommand> commands;

  Device(this.label, this.registers, this.commands);
}

class RegType {
  final int register;

  final bool canRead;
  final bool canWrite;

  final String label;

  RegType({
    required this.register,
    required this.label,
    required this.canRead,
    required this.canWrite
  });
}