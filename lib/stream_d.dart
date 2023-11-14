library stream_d;
import 'dart:async';
import 'package:flutter/foundation.dart';

/// **[Check the full documentation on GitHub](https://github.com/RodrigoBertotti/stream_d)**
class StreamD<T> extends Stream<T>{
  final Stream<T> _stream;
  late final StackTrace _stackTrace;

  StreamD(this._stream) {
    _stackTrace = StackTrace.current;
    assert(_stream is! StreamD);
  }

  @override
  bool get isBroadcast => _stream.isBroadcast;

  /// Useful for StreamBuilder only, use [listenD] instead.
  @override @Deprecated("Internal usage only, please call [listenD] instead")
  StreamSubscription<T> listen(void Function(T event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    print(_stackTrace);

    // Throwing this error to avoid the weird error "Bad state: Stream has already been listened to."
    // TODO: fork from dart async package?

    if (kDebugMode && !StackTrace.current.toString().contains("package:flutter/")) {
      throw "[StreamD] Do not call listen, please call listenD(..) instead. If you still want to use listen(..), please use the default Dart Stream";
    }
    throw "[StreamD] StreamBuilder does not support StreamD, please use the default Dart Stream instead";
  }

  StreamSubscriptionD<T> listenD(void Function(T event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    void Function()? userOnDone = onDone;
    final List<void Function()> onDoneList = [];

    onDoneHandler() {
      if (userOnDone != null) {
        userOnDone!();
        userOnDone = null;
      }
      for (final onDone in onDoneList) {
        onDone();
      }
      onDoneList.clear();
    }
    final subscription = _stream.listen(onData, onDone: onDoneHandler, cancelOnError: cancelOnError, onError: onError);

    return StreamSubscriptionD<T>(
      subscription: subscription,
      cancel: () {
        onDoneHandler();
        return subscription.cancel();
      },
      onDone: (onDone) {
        userOnDone = onDone;
      },
      addOnDone: (handler) => onDoneList.add(handler),
      removeOnDone: (handler) => onDoneList.remove(handler),
    );
  }

  @override
  Stream<T> asBroadcastStream(
      {void onListen(StreamSubscription<T> subscription)?,
        void onCancel(StreamSubscription<T> subscription)?}) {
    return _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Stream<T> where(bool test(T event)) {
    return _stream.where(test);
  }

  @override
  Stream<S> map<S>(S convert(T event)) {
    return _stream.map(convert);
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> convert(T event)) {
    return _stream.asyncMap(convert);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? convert(T event)) {
    return _stream.asyncExpand(convert);
  }

  @override
  Stream<T> handleError(Function onError, {bool test(error)?}) {
    return _stream.handleError(onError, test: test);
  }

  @override
  Stream<S> expand<S>(Iterable<S> convert(T element)) {
    return _stream.expand(convert);
  }

  @override
  Future pipe(StreamConsumer<T> streamConsumer) {
    return _stream.pipe(streamConsumer);
  }

  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) {
    return _stream.transform(streamTransformer);
  }

  @override
  Future<T> reduce(T combine(T previous, T element)) {
    return _stream.reduce(combine);
  }

  @override
  Future<S> fold<S>(S initialValue, S combine(S previous, T element)) {
    return _stream.fold(initialValue, combine);
  }

  @override
  Future<String> join([String separator = ""]) {
    return _stream.join(separator);
  }

  @override
  Future<bool> contains(Object? needle) {
    return _stream.contains(needle);
  }

  @override
  Future<void> forEach(void action(T element)) {
    return _stream.forEach(action);
  }

  @override
  Future<bool> every(bool test(T element)) {
    return _stream.every(test);
  }

  @override
  Future<bool> any(bool test(T element)) {
    return _stream.any(test);
  }

  @override
  Future<int> get length {
    return _stream.length;
  }

  @override
  Future<bool> get isEmpty {
    return _stream.isEmpty;
  }

  @override
  Stream<R> cast<R>() => _stream.cast();

  @override
  Future<List<T>> toList() {
    return _stream.toList();
  }

  @override
  Future<Set<T>> toSet() {
    return _stream.toSet();
  }

  @override
  Future<E> drain<E>([E? futureValue]) {
    return _stream.drain(futureValue);
  }

  @override
  Stream<T> take(int count) {
    return _stream.take(count);
  }

  @override
  Stream<T> takeWhile(bool test(T element)) {
    return _stream.takeWhile(test);
  }

  @override
  Stream<T> skip(int count) {
    return _stream.skip(count);
  }

  @override
  Stream<T> skipWhile(bool test(T element)) {
    return _stream.skipWhile(test);
  }

  @override
  Stream<T> distinct([bool equals(T previous, T next)?]) {
    return _stream.distinct(equals);
  }

  @override
  Future<T> get first {
    return _stream.first;
  }

  @override
  Future<T> get last {
    return _stream.last;
  }

  @override
  Future<T> get single {
    return _stream.single;
  }

  @override
  Future<T> firstWhere(bool test(T element), {T orElse()?}) {
    return _stream.firstWhere(test, orElse: orElse);
  }

  @override
  Future<T> lastWhere(bool test(T element), {T orElse()?}) {
    return _stream.lastWhere(test, orElse: orElse);
  }

  @override
  Future<T> singleWhere(bool test(T element), {T orElse()?}) {
    return _stream.singleWhere(test, orElse: orElse);
  }

  @override
  Future<T> elementAt(int index) {
    return _stream.elementAt(index);
  }

  @override
  Stream<T> timeout(Duration timeLimit, {void onTimeout(EventSink<T> sink)?}) {
    return _stream.timeout(timeLimit, onTimeout: onTimeout);
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
