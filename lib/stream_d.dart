library stream_d;
import 'dart:async';
import 'package:flutter/foundation.dart';

/// **[Check the full documentation on GitHub](https://github.com/RodrigoBertotti/StreamD)**
///
///The problem with default streams:
/// - the default [onDone] event handler is not triggered when [cancel] is called from a [StreamSubscription],
/// so it may be tricky to identify the exact moment when a [StreamSubscription] became no longer active if
/// we don't have access to its [StreamController] on a specific layer of the App.
///
/// The solution when calling [listenD]
/// - [onDone] event handler is always triggered once the stream is no longer active, even when [cancel] is called from a [StreamSubscription].
///
/// [StreamD] also allows you to add a listener with [addOnDone] that won't replace the previous [onDone] callback
/// and you can also close all [StreamSubscription] by calling [closeAll].
///
/// It's important to call these methods when using [StreamD]:
/// - call [listenD], not [listen]
/// - call [addOnDone], not [onDone]
class StreamD<T> extends Stream<T>{
  late final StreamController<T> _controller;
  final List<void Function()> _onCloseSubscriptionCallbacks = [];

  StreamD({required StreamController<T> controller}) {
    _controller = controller;
    _initMyStream();
  }

  StreamD.broadcast({required StreamController<T> controller}) { // TODO: check
    _controller = controller;
    _initMyStream();
  }

  bool _initialized = false;
  void _initMyStream() {
    if (!_initialized) {
      _initialized = true;
      final externalOnCancelCtrl = _controller.onCancel ?? () {};
      _controller.onCancel = () { // called only when no stream is listening (in case it's broadcast)
        _listeners--;
        Future.delayed(const Duration(milliseconds: 50), () { //delay for firestore
          for (final onClose in List.from(_onCloseSubscriptionCallbacks)) {
            onClose();
          }
          _onCloseSubscriptionCallbacks.clear();
          externalOnCancelCtrl();
        });
      };
    }
  }

  /// Closes all subscriptions
  void closeAll () {
    _controller.close();
  }

  StreamD.fromStream(Stream<T> stream) {
    assert(stream is! StreamD, "This stream already emits onDone() events once subscription.cancel() is called");
    StreamSubscription<T>? streamSubscription;
    onListen() {
      if (streamSubscription != null) {
        if (kDebugMode) print("[StreamD] streamSubscription is not null");
        return;
      }
      streamSubscription = stream.listen((event) {
        _controller.add(event);
      }, onDone: () { // in the default stream, onDone will not be called when cancel() is called
        streamSubscription = null;
        _controller.close();
      });
      _onCloseSubscriptionCallbacks.add(streamSubscription!.cancel);
    }
    onCancel() { // on close controller
      Future.delayed(const Duration(milliseconds: 30), () {  // delay for firestore
        streamSubscription?.cancel();
        streamSubscription = null;
      });
    }
    _controller = stream.isBroadcast ? StreamController.broadcast(onListen: onListen, onCancel: onCancel) : StreamController(onListen: onListen, onCancel: onCancel);
    _initMyStream();
  }

  @override
  bool get isBroadcast => _controller.stream.isBroadcast;

  /// Useful for StreamBuilder only, use [listenD] instead.
  @override @Deprecated("Internal usage only, please call [listenD] instead")
  StreamSubscriptionD<T> listen(void Function(T event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    if (kDebugMode && !StackTrace.current.toString().contains("package:flutter/")) {
      if (kDebugMode) print("[StreamD] ⚠️ You are calling listen(..) but it's for internal usage only, please call listenD(..) instead");
    }
    _listeners++;
    return _listenImp(onData, triggerOnDoneFromCancelCall: false, onDone: onDone, cancelOnError: cancelOnError, onError: onError);
  }

  int _listeners = 0;
  StreamSubscriptionD<T> listenD(void Function(T event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    _listeners++;
    return _listenImp(onData, triggerOnDoneFromCancelCall: true, onDone: onDone, cancelOnError: cancelOnError, onError: onError);
  }

  StreamSubscriptionD<T> _listenImp(void Function(T event)? onData, {required bool triggerOnDoneFromCancelCall, Function? onError, void Function()? onDone, bool? cancelOnError}) {
    assert(!_controller.isClosed, "This stream is no longer active");

    late final StreamSubscription<T> subscription;
    final List<void Function()> onDoneListForCurrentSubscription = [];
    void Function()? onDoneHandler = onDone;

    bool closed = false;
    Future<void> closeThis() async {
      if (closed){
        return;
      }
      _onCloseSubscriptionCallbacks.remove(closeThis);
      closed = true;

      Future.delayed(const Duration(milliseconds: 35), subscription.cancel);

      for (final handler in List.from(onDoneListForCurrentSubscription)) {
        handler();
      }

      // e.g. if is not coming from a stream builder, call onDoneHandler
      if (triggerOnDoneFromCancelCall) {
        onDoneHandler?.call();
      }

      if (!isBroadcast) {
        Future.delayed(const Duration(milliseconds: 100), () { // to avoid: "Bad state: Cannot add event after closing"
          if (_listeners == 0) {
            _controller.close();
          }
        });
      }
    }
    _onCloseSubscriptionCallbacks.add(closeThis);
    subscription = _controller.stream.listen(onData, onError: onError, onDone: closeThis, cancelOnError: cancelOnError);

    return StreamSubscriptionD<T>(
      subscription: subscription,
      cancel: closeThis,
      onDone: (handler) => onDoneHandler = handler,
      addOnDone: (handler) => onDoneListForCurrentSubscription.add(handler),
      removeOnDone: (handler) => onDoneListForCurrentSubscription.remove(handler),
    );
  }



  @override
  Stream<T> asBroadcastStream(
      {void onListen(StreamSubscription<T> subscription)?,
        void onCancel(StreamSubscription<T> subscription)?}) {
    return _controller.stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Stream<T> where(bool test(T event)) {
    return _controller.stream.where(test);
  }

  @override
  Stream<S> map<S>(S convert(T event)) {
    return _controller.stream.map(convert);
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> convert(T event)) {
    return _controller.stream.asyncMap(convert);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? convert(T event)) {
    return _controller.stream.asyncExpand(convert);
  }

  @override
  Stream<T> handleError(Function onError, {bool test(error)?}) {
    return _controller.stream.handleError(onError, test: test);
  }

  @override
  Stream<S> expand<S>(Iterable<S> convert(T element)) {
    return _controller.stream.expand(convert);
  }

  @override
  Future pipe(StreamConsumer<T> streamConsumer) {
    return _controller.stream.pipe(streamConsumer);
  }

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    return _controller.stream.transform(streamTransformer);
  }

  @override
  Future<T> reduce(T combine(T previous, T element)) {
    return _controller.stream.reduce(combine);
  }

  @override
  Future<S> fold<S>(S initialValue, S combine(S previous, T element)) {
    return _controller.stream.fold(initialValue, combine);
  }

  @override
  Future<String> join([String separator = ""]) {
    return _controller.stream.join(separator);
  }

  @override
  Future<bool> contains(Object? needle) {
    return _controller.stream.contains(needle);
  }

  @override
  Future<void> forEach(void action(T element)) {
    return _controller.stream.forEach(action);
  }

  @override
  Future<bool> every(bool test(T element)) {
    return _controller.stream.every(test);
  }

  @override
  Future<bool> any(bool test(T element)) {
    return _controller.stream.any(test);
  }

  @override
  Future<int> get length {
    return _controller.stream.length;
  }

  @override
  Future<bool> get isEmpty {
    return _controller.stream.isEmpty;
  }

  @override
  Stream<R> cast<R>() => _controller.stream.cast();

  @override
  Future<List<T>> toList() {
    return _controller.stream.toList();
  }

  @override
  Future<Set<T>> toSet() {
    return _controller.stream.toSet();
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
    return _controller.stream.drain(futureValue);
  }

  @override
  Stream<T> take(int count) {
    return _controller.stream.take(count);
  }

  @override
  Stream<T> takeWhile(bool test(T element)) {
    return _controller.stream.takeWhile(test);
  }

  @override
  Stream<T> skip(int count) {
    return _controller.stream.skip(count);
  }

  @override
  Stream<T> skipWhile(bool test(T element)) {
    return _controller.stream.skipWhile(test);
  }

  @override
  Stream<T> distinct([bool equals(T previous, T next)?]) {
    return _controller.stream.distinct(equals);
  }

  @override
  Future<T> get first {
    return _controller.stream.first;
  }

  @override
  Future<T> get last {
    return _controller.stream.last;
  }

  @override
  Future<T> get single {
    return _controller.stream.single;
  }

  @override
  Future<T> firstWhere(bool test(T element), {T orElse()?}) {
    return _controller.stream.firstWhere(test, orElse: orElse);
  }

  @override
  Future<T> lastWhere(bool test(T element), {T orElse()?}) {
    return _controller.stream.lastWhere(test, orElse: orElse);
  }

  @override
  Future<T> singleWhere(bool test(T element), {T orElse()?}) {
    return _controller.stream.singleWhere(test, orElse: orElse);
  }

  @override
  Future<T> elementAt(int index) {
    return _controller.stream.elementAt(index);
  }

  @override
  Stream<T> timeout(Duration timeLimit, {void onTimeout(EventSink<T> sink)?}) {
    return _controller.stream.timeout(timeLimit, onTimeout: onTimeout);
  }

}

/// Remember to
/// - call [addOnDone], not [onDone]
class StreamSubscriptionD<T> implements StreamSubscription<T> {
  late final Future<void> Function() _cancel;
  late final StreamSubscription<T> _subscription;
  late final void Function(void Function()? handleDone) _onDone;
  late final void Function(void Function() handleDone) _addOnDone;
  late final void Function(void Function() handleDone) _removeOnDone;


  StreamSubscriptionD({
    required Future<void> Function() cancel,
    required void Function(void Function()? handleDone) onDone,
    required void Function(void Function() handleDone) addOnDone,
    required void Function(void Function() handleDone) removeOnDone,
    required StreamSubscription<T> subscription,
  }) {
    _subscription = subscription;
    _cancel = cancel;
    _onDone = onDone;
    _addOnDone = addOnDone;
    _removeOnDone = removeOnDone;
  }

  @override
  Future<void> cancel() {
    return _cancel();
  }

  @override @Deprecated("Internal usage only, please call [addOnDone] instead")
  /// Useful for StreamBuilder only, use [addOnDone] instead.
  void onDone(void Function()? handleDone) {
    if (kDebugMode && !StackTrace.current.toString().contains("package:flutter/")) {
      if (kDebugMode) print("[StreamSubscriptionD] ⚠️ You are calling onDone(..) but it's for internal usage only, please use addOnDone(..) instead");
    }
    return _onDone(handleDone);
  }

  /// Adds a new done event handler of this subscription without removing the others.
  /// [handleDone] is triggered even when the [cancel] is called
  void addOnDone(void Function() handleDone) {
    return _addOnDone(handleDone);
  }

  void removeOnDone(void Function() handleDone) {
    return _removeOnDone(handleDone);
  }

  @override
  void onData(void Function(T data)? handleData) {
    return _subscription.onData(handleData);
  }

  @override
  void onError(Function? handleError) {
    return _subscription.onError(handleError);
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    return _subscription.pause(resumeSignal);
  }

  @override
  void resume() {
    return _subscription.resume();
  }

  @override
  bool get isPaused {
    return _subscription.isPaused;
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    return _subscription.asFuture(futureValue);
  }
}
