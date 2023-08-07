import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';

class SshI2C {

  final String ipOrDnsAddress;
  final int? port;
  final String username;
  final String? password;
  final int bus;

  SshI2C({
    required this.ipOrDnsAddress,
    required this.username,
    required this.bus,
    this.port,
    this.password,
  });

  Future<SSHClient> getClient() async {
    return SSHClient(
      await SSHSocket.connect('raspberrypi', port ?? 22),
      username: username,
      onPasswordRequest: password != null ? (() => password) : null,
    );
  }

  Future<int> setAndGet(int device, int address, int value, bool readBack) async {
    final client = await getClient();
    try {
      return await setAndGetC(client, device, address, value, readBack);
    } finally {
      client.close();
    }
  }
  Future<int> setAndGetC(SSHClient client, int device, int address,
      int value, bool readBack) async {
    final writeCommand =
        "/sbin/i2cset -y $bus 0x${device.toRadixString(16)} 0x${address.toRadixString(16)} 0x${value.toRadixString(16)}";
    final writeResponse = await client.run(writeCommand, runInPty: true);
    if (writeResponse.isNotEmpty) {
      return value;
      //throw Exception(utf8.decode(writeResponse));
    }

    if (!readBack) {
      return value;
    }

    final readCommand =
        "/sbin/i2cget -y $bus 0x${device.toRadixString(16)} 0x${address.toRadixString(16)}";
    final readResponse = await client.run(readCommand, runInPty: true);
    final readResponseText = utf8.decode(readResponse);

    try {
      return int.parse(readResponseText.substring(2), radix: 16);
    } catch (e) {
      throw Exception(readResponseText);
    }
  }

  Future<void> resetDeviceC(SSHClient client, int device) async {
    // Page 1
    await client
        .run("/sbin/i2cset -y $bus 0x${device.toRadixString(16)} 0x7F 0x00");
    // Reset 1
    await client
        .run("/sbin/i2cset -y $bus 0x${device.toRadixString(16)} 0x01 0x80");
  }

  Future<void> resetDevice(int device) async {
    final client = await getClient();
    try {
      await resetDeviceC(client, device);
    } finally {
      client.close();
    }
  }
  Future<Map<int, int>> readRegistersC(SSHClient client, int device, Iterable<int> registers) async {
    final responseMap = <int, int>{};
    try {
      for (var e in registers) {
        final command = "/sbin/i2cget -y $bus 0x${device.toRadixString(16)} 0x${e.toRadixString(16)}";
        final response = await client.run(command, runInPty: true);

        try {
          int value = int.parse(utf8.decode(response).substring(2), radix: 16);
          responseMap[e] = value;
        } catch (e) {
          print("ERROR: ${utf8.decode(response).substring(2)}");
          // throw Exception(utf8.decode(response));
        }
      }
    } finally {
      client.close();
    }

    return responseMap;
  }

  Future<Map<int, int>> readRegisters(int device, Iterable<int> registers) async {
    final client = await getClient();
    try {
      return await readRegistersC(client, device, registers);
    } finally {
      client.close();
    }
  }


  Future<Map<int, int>> writeAll(SSHClient client, int device, Map<int, int> registers, bool readBack) async {
    try {
      for (var e in registers.entries) {
        final newValue = await setAndGetC(client, device, e.key, e.value, readBack);
        registers[e.key] = newValue;
      }

      return registers;
    } finally {
      client.close();
    }
  }

}