# StreamD

Stream that triggers the `onDone` event handler even when `cancel()` is called from a subscription.
You can also add multiple `onDone` listeners.
`StreamD` is a wrapper on the default Dart Stream, with an additional `listenD` method,
but `StreamD` doesn't work as `StreamBuilder` parameter.

## About StreamD

There's a minor hassle when managing Dart Streams:
- the `onDone` event handler is not triggered when `cancel()` is called from a `StreamSubscription`,
so it may be tricky to identify the exact moment when a `StreamSubscription` became no longer active if
we don't have access to its `StreamController` on a specific layer of the App.

The solution when calling `listenD`
- `onDone` event handler is always triggered once the stream is no longer active, even when `cancel()` is called from a `StreamSubscription`.

`StreamD` also allows you to add a listener with `addOnDone` that won't replace the previous `onDone` callback.

## Comparison

```dart
final controller1 = StreamController();
final defaultStream = controller1.stream;
final defaultStreamSubscription = defaultStream.listen((event) {});
defaultStreamSubscription.onDone(() {
print("(2) Default Stream: onDone was triggered!");
});
print("(1) Default Stream: let's call cancel() on the subscription...");
defaultStreamSubscription.cancel();

final controller2 = StreamController();
final streamD = StreamD(controller2.stream);
final StreamSubscriptionD streamSubscriptionD = streamD.listenD((event) {});
streamSubscriptionD.addOnDone(() {
print("(2) With StreamD: onDone was triggered!");
});
print("(1) With StreamD: let's call cancel() on the subscription...");
streamSubscriptionD.cancel();
```
### Output:

    (1) Default Stream: let's call cancel() on the subscription...
    (1) With StreamD: let's call cancel() on the subscription...
    (2) With StreamD: onDone was triggered!

### :warning: Limitation

**StreamD doesn't work as StreamBuilder parameter**, so calling `listen(..)` will give you an error,
please use `listenD(..)` instead or use the default Dart Stream.

## Getting started

    dependencies:
      flutter:
        sdk: flutter
            
        # Add this line:
        stream_d: ^0.3.0

### Initializing a StreamD

```dart
final streamD = StreamD(stream);
```

### Listening
```dart
final StreamSubscriptionD subscription = streamD.listenD((event) {
    print(event);
});
```
### Adding onDone listener to a subscription
```dart
final StreamSubscriptionD subscription = streamD.listenD((event) {});
subscription.addOnDone(() {
    print("onDone was called!");
});
```

## License

[MIT](LICENSE)

## Contacting me

📧 rodrigo@wisetap.com
