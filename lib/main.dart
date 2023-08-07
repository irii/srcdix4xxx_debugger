import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:srcdix4xxx_debugger/bit_mask.dart';
import 'package:srcdix4xxx_debugger/bloc/CommunicatorBloc.dart';
import 'package:srcdix4xxx_debugger/bloc/RegistersBloc.dart';
import 'package:srcdix4xxx_debugger/communicator.dart';
import 'package:srcdix4xxx_debugger/registers.dart';
import 'package:srcdix4xxx_debugger/ssh_i2c.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final CommunicatorBloc communicatorBloc = CommunicatorBloc();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRC/DIX4xxx I2C',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(),
        useMaterial3: true,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<CommunicatorBloc>.value(value: communicatorBloc),
          BlocProvider<RegisterBloc>.value(value: RegisterBloc(communicatorBloc))
        ],
        child: const MyHomePage(title: 'SRC/DIX4xxx I2C')
      )
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SshI2C sshI2C = SshI2C(ipOrDnsAddress: "raspberrypi", username: "irii", password: "Test", bus: 5);

  bool instantUpdate = false;
  bool readOnly = false;

  String filter = "";

  int device = 0x70;

  void changeDevice(BuildContext context, int deviceAddress, Device? device) {
    this.device = deviceAddress;
    if (device == null) {
      BlocProvider
          .of<CommunicatorBloc>(context)
          .add(CommunicatorChangeEvent(null));

      return;
    }

    final communicator = SshI2cCommunicator(sshI2C, deviceAddress, deviceInfo: device);
    BlocProvider
        .of<CommunicatorBloc>(context)
        .add(CommunicatorChangeEvent(communicator));
  }

  @override
  initState() {
    super.initState();
  }

  Widget _commandsPopupButton(BuildContext context) {
    return BlocBuilder<CommunicatorBloc, CommunicatorState>(
        builder: (context, state) {
          if (state.current == null) {
            return Container();
          }

          final entries = state.current!.deviceInfo.commands.map((e) => PopupMenuItem<RegCommand>(
            value: e,
            child: Text(e.label),
          )).toList();

          return PopupMenuButton<RegCommand>(
              child: const Row(
                children: [Icon(Icons.keyboard_command_key), Text("Commands")],
              ),
              itemBuilder: (context) => entries
          );
        }
    );
  }

  Iterable<RegType> _filter(Iterable<RegType> input) {
    if (filter.isNotEmpty) {
      final search = filter.toUpperCase();
      input = input.where((element) => "${element.label} 0X${element.register.toRadixString(16)}".toUpperCase().contains(search));
    }

    if (readOnly) {
      input = input.where((element) => !element.canWrite && element.canRead);
    }

    return input;
  }

  Widget _registers(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
        builder: (context, state) {
          if (state.values == null || state.description == null) {
            return const Text("Not Connected.");
          }

          final registers = _filter(state.description!.values);

          return Wrap(
            children: registers.map((e) => Container(
              alignment: Alignment.center,
              height: 150,
              width: 500,
              child: BitMask(
                  enabled: state is! RegisterLoadingState,
                  label: e.label,
                  changeCallback: e.canWrite ? (register, oldV, newV) => {
                    BlocProvider.of<RegisterBloc>(context).add(RegisterChangeEvent({
                      register: newV
                    }, instantUpdate))
                  } : null,
                  register: e.register,
                  value: state.values![e.register] ?? 0x00),
            ))
                .toList(),
          );
        }
    );
  }
  
  Widget _selectDeviceDropdown(BuildContext context) {
    return BlocBuilder<CommunicatorBloc, CommunicatorState>(
        builder: (context, state) {
          return DropdownButton<Device>(
            value: state.current?.deviceInfo,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (Device? value) {
              changeDevice(context, device, value);
            },
            items: [
              DropdownMenuItem<Device>(
                value: Registers.DEV_SRC4392,
                child: const Text("SRC4392"),
              ),
              DropdownMenuItem<Device>(
                value: Registers.DEV_DIX4192,
                child: const Text("DIX4192"),
              )
            ],
          );
        }
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          BlocBuilder<RegisterBloc, RegisterState>(builder: (context, state) {
            final loading = state is RegisterLoadingState;
            return loading ? const CircularProgressIndicator() : Container();
          }),
          const VerticalDivider(),
          _selectDeviceDropdown(context),
          const VerticalDivider(),
          SizedBox(
            width: 50,
            child: TextFormField(
              initialValue: device.toRadixString(16),
              decoration: const InputDecoration.collapsed(hintText: 'Address'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (value) {
                setState(() {
                  device = int.parse(value, radix: 16);
                });
              },
            ),
          ),
          const VerticalDivider(),
          const Text("Read-Only"),
          Checkbox(
              value: readOnly,
              onChanged: (v) => setState(() {
                    readOnly = v ?? false;
                  })),
          const VerticalDivider(),
          SizedBox(
            width: 200,
            child: TextField(
              decoration: const InputDecoration.collapsed(
                  hintText: 'Register Search...'),
              onChanged: (value) {
                setState(() {
                  filter = value;
                });
              },
            ),
          ),
          const VerticalDivider(),
          const Text("Instant Update: "),
          Switch(
              value: instantUpdate,
              onChanged: (v) => setState(() {
                    instantUpdate = v;
                  })),
          const VerticalDivider(),
          TextButton.icon(onPressed: () {BlocProvider.of<RegisterBloc>(context).add(RegisterReadEvent());}, icon: const Icon(Icons.upload), label: Text("Write")),
          TextButton.icon(onPressed: () {BlocProvider.of<RegisterBloc>(context).add(RegisterWriteEvent());}, icon: const Icon(Icons.download), label: Text("Read")),
          const VerticalDivider(),
          _commandsPopupButton(context)
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
            child: Container(
                alignment: Alignment.topCenter,
                width: MediaQuery.of(context).size.width,
                child: _registers(context))),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
