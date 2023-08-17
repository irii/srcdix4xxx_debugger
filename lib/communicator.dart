import 'package:dartssh2/dartssh2.dart';
import 'package:srcdix4xxx_debugger/registers.dart';
import 'package:srcdix4xxx_debugger/ssh_i2c.dart';

abstract class Communicator {
  final int deviceId;
  final Device deviceInfo;
  final Map<int, int> deviceValues = {};

  Communicator({
    required this.deviceInfo,
    required this.deviceId
  }) {
    for (var entry in deviceInfo.registers.entries) {
      deviceValues[entry.key] = 0x00;
    }
  }

  Future command(RegCommand command, int? overwriteValue) async {
    final value = overwriteValue ?? command.value;
    await writeToDevice(command.register, value, false);
  }

  Future readAll(List<int>? registers) async {
    final readRegisters = registers ?? deviceInfo.registers.entries.where((element) => element.value.canRead).map((e) => e.key);
    final response = await readAllFromDevice(readRegisters);

    for(var entry in response.entries) {
      deviceValues[entry.key] = entry.value;
    }
  }

  Future writeAll(List<int>? registers) async {
    final affectedRegisters = registers ?? deviceInfo.registers.entries.where((element) => element.value.canWrite).map((e) => e.key);

    final writeRegisters = Map.fromEntries(affectedRegisters.map((e) => MapEntry(e, deviceValues[e] ?? 0x00)));
    final response = await writeAllToDevice(writeRegisters, false);

    for(var entry in response.entries) {
      deviceValues[entry.key] = entry.value;
    }

    await readAll(registers);
  }

  Future write(int register) {
    return writeToDevice(register, deviceValues[register] ?? 0x00, false);
  }

  Future read(int register) async {
    final newValue = await readFromDevice(register);
    deviceValues[register] = newValue;
    return newValue;
  }

  Future<int> readFromDevice(int register);
  Future writeToDevice(int register, int value, bool readBack);

  Future<Map<int, int>> readAllFromDevice(Iterable<int> registers);
  Future writeAllToDevice(Map<int, int> registers, bool readBack);
}

class SshI2cCommunicator extends Communicator {
  final SshI2C sshI2C;
  final int device;

  SshI2cCommunicator(this.sshI2C, this.device, {required super.deviceInfo, required super.deviceId});

  SSHClient? _client;

  Future<SSHClient> getClient() async {
    var client = _client;
    if (client != null && !client.isClosed) {
      return client;
    }

    _client = client = await sshI2C.getClient();
    return client;
  }

  @override
  Future<Map<int, int>> readAllFromDevice(Iterable<int> registers) async {
    final client = await getClient();
    return await sshI2C.readRegistersC(client, device, registers);
  }

  @override
  Future<int> readFromDevice(int register) async {
    final client = await getClient();
    final data = await sshI2C.readRegistersC(client, device, [register]);
    return data[register]!;
  }

  @override
  Future<Map<int, int>> writeAllToDevice(Map<int, int> registers, bool readBack) async {
    final client = await getClient();
    return await sshI2C.writeAll(client, device, registers, readBack);
  }

  @override
  Future<int> writeToDevice(int register, int value, bool readBack) async {
    final client = await getClient();
    final data = await sshI2C.writeAll(client, device, {
      register: value
    }, readBack);

    return data[register]!;
  }

}

class StubCommunicator extends Communicator {
  StubCommunicator({required super.deviceInfo, required super.deviceId});

  @override
  Future<Map<int, int>> readAllFromDevice(Iterable<int> registers) async {
    return Map.from(deviceValues);
  }

  @override
  Future<int> readFromDevice(int register) async {
    return deviceValues[register] ?? 0x00;
  }

  @override
  Future<Map<int, int>> writeAllToDevice(Map<int, int> registers, bool readBack) async {
    for (var entry in registers.entries) {
      deviceValues[entry.key] = entry.value;
    }

    return Map.from(registers);
  }

  @override
  Future<int> writeToDevice(int register, int value, bool readBack) async {
    deviceValues[register] = value;
    return value;
  }

}