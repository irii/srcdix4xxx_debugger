import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:srcdix4xxx_debugger/communicator.dart';

abstract class CommunicatorState {
  final Communicator? current;

  CommunicatorState(this.current);
}

class CommunicatorEmptyState extends CommunicatorState {
  CommunicatorEmptyState() : super(null);
}

class CommunicatorChangedState extends CommunicatorState {
  CommunicatorChangedState(super.current);
}


abstract class CommunicatorEvent {}

class CommunicatorChangeEvent extends CommunicatorEvent {
  final Communicator? communicator;
  CommunicatorChangeEvent(this.communicator);
}

class CommunicatorBloc extends Bloc<CommunicatorEvent, CommunicatorState> {
  CommunicatorBloc() : super(CommunicatorEmptyState()) {
    on<CommunicatorChangeEvent>(_onCommunicatorChangeEvent);
  }

  void _onCommunicatorChangeEvent(CommunicatorChangeEvent event, Emitter<CommunicatorState> emit) async {
    emit(CommunicatorChangedState(event.communicator));
  }
}