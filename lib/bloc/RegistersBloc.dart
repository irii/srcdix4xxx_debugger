import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:srcdix4xxx_debugger/bloc/CommunicatorBloc.dart';
import 'package:srcdix4xxx_debugger/registers.dart';

abstract class RegisterState {
  final Map<int, int>? values;
  final Map<int, RegType>? description;

  RegisterState(this.values, this.description);
}

class RegisterEmptyState extends RegisterState {
  RegisterEmptyState() : super(null, null);
}

class RegisterChangedState extends RegisterState {
  RegisterChangedState(super.values, super.description);
}

class RegisterLoadingState extends RegisterState {
  RegisterLoadingState(super.values, super.description);
}

abstract class RegisterEvent {}

class RegisterReadEvent extends RegisterEvent {
  final List<int>? registers;
  RegisterReadEvent({this.registers});
}

class RegisterCommandEvent extends RegisterEvent {
  final int register;
  final int value;
  RegisterCommandEvent(this.register, this.value);
}

class RegisterWriteEvent extends RegisterEvent {
  final List<int>? registers;
  RegisterWriteEvent({this.registers});
}

class RegisterChangeEvent extends RegisterEvent {
  final Map<int, int> values;
  final bool instantUpdate;

  RegisterChangeEvent(this.values, this.instantUpdate);
}

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final CommunicatorBloc _communicatorBloc;

  RegisterBloc(this._communicatorBloc) : super(RegisterEmptyState()) {
    on<RegisterChangeEvent>(_onRegisterChangeEvent);
    on<RegisterReadEvent>(_onRegisterReadAllEvent);
    on<RegisterWriteEvent>(_onRegisterWriteAllEvent);
    on<RegisterCommandEvent>(_onRegisterCommandEvent);

    _communicatorBloc.stream.listen((event) {
      add(RegisterReadEvent());
    });
  }

  void _onRegisterCommandEvent(RegisterCommandEvent event, Emitter<RegisterState> emit) async {
    final communicatorState = _communicatorBloc.state.current;
    if (communicatorState == null) return;

    emit(RegisterLoadingState(communicatorState.deviceValues, communicatorState.deviceInfo.registers));
    await communicatorState.writeToDevice(event.register, event.value, false);
    emit(RegisterChangedState(communicatorState.deviceValues, communicatorState.deviceInfo.registers));
  }

  void _onRegisterReadAllEvent(RegisterReadEvent event, Emitter<RegisterState> emit) async {
    final communicatorState = _communicatorBloc.state.current;
    if (communicatorState == null) return;

    emit(RegisterLoadingState(communicatorState.deviceValues, communicatorState.deviceInfo.registers));
    await communicatorState.readAll(event.registers);
    emit(RegisterChangedState(Map.from(communicatorState.deviceValues), communicatorState.deviceInfo.registers));
  }

  void _onRegisterWriteAllEvent(RegisterWriteEvent event, Emitter<RegisterState> emit) async {
    final communicatorState = _communicatorBloc.state.current;
    if (communicatorState == null) return;

    emit(RegisterLoadingState(communicatorState.deviceValues, communicatorState.deviceInfo.registers));
    await communicatorState.writeAll(event.registers);
    await communicatorState.readAll(event.registers);
    emit(RegisterChangedState(communicatorState.deviceValues, communicatorState.deviceInfo.registers));
  }

  void _onRegisterChangeEvent(RegisterChangeEvent event, Emitter<RegisterState> emit) async {
    final communicatorState = _communicatorBloc.state.current;
    if (communicatorState == null) return;

    for (var entry in event.values.entries) {
      communicatorState.deviceValues[entry.key] = entry.value;
    }

    if (event.instantUpdate) {
      emit(RegisterLoadingState(communicatorState.deviceValues, communicatorState.deviceInfo.registers));
      await communicatorState.writeAll(event.values.keys.toList());
    }

    emit(RegisterChangedState(communicatorState.deviceValues, communicatorState.deviceInfo.registers));
  }
}