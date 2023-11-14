import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_d/stream_d.dart';

void main() {
  test('listenD should emit the event', () {
    final controller = StreamController();
    final streamD = StreamD(controller.stream);
    streamD.listenD(expectAsync1((event) => expect(event, "hello")));
    controller.add("hello");
  });

  test('StreamD: onDone() should be triggered when cancel() is called', () {
    final controller = StreamController();
    final streamD = StreamD(controller.stream);
    final subscription = streamD.listenD((event) {});
    subscription.addOnDone(expectAsync0(() => expect('1','1')));
    subscription.addOnDone(expectAsync0(() => expect('2','2')));
    subscription.addOnDone(expectAsync0(() => expect('3','3')));
    subscription.cancel();
  });


  test('StreamD: onDone() should be triggered even if more than one subscription is active', () async {
    final controller = StreamController.broadcast();
    final streamD = StreamD(controller.stream);
    bool sub1Called = false;
    final sub1 = streamD.listenD((event) {sub1Called = true;});
    final sub2 = streamD.listenD(expectAsync1((event) => expect(event, "event for sub 2")));
    sub1.addOnDone(expectAsync0(() => expect('1','1')));
    sub1.cancel();
    await Future.delayed(const Duration(milliseconds: 200));
    controller.add("event for sub 2");
    await Future.delayed(const Duration(milliseconds: 200));
    expect(sub1Called, false);
  });

  test('StreamD: onDone() should be triggered when cancel() is called', () async {
    final controller = StreamController();
    final streamD = StreamD(controller.stream);
    final subscription = streamD.listenD(expectAsync1((event) => expect(event, "hello")));
    controller.add("hello");
    subscription.addOnDone(expectAsync0(() => expect('1','1')));
    subscription.addOnDone(expectAsync0(() => expect('2','2')));
    subscription.addOnDone(expectAsync0(() => expect('3','3')));
    await Future.delayed(const Duration(milliseconds: 100));
    subscription.cancel();
  });

  test('StreamD from broadcast stream: onDone() should be triggered when controller.close() is called', () {
    final controller = StreamController.broadcast();
    final streamD = StreamD(controller.stream);
    final sub1 = streamD.listenD(expectAsync1((event) => expect(event, "hello")));
    final sub2 = streamD.listenD(expectAsync1((event) => expect(event, "hello")));
    final sub3 = streamD.listenD(expectAsync1((event) => expect(event, "hello")));
    controller.add("hello");
    sub1.addOnDone(expectAsync0(() => expect('1','1')));
    sub2.addOnDone(expectAsync0(() => expect('2','2')));
    sub3.addOnDone(expectAsync0(() => expect('3','3')));
    controller.close();
  });
}
