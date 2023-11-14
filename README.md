# StreamD

Stream that triggers the `onDone` event handler even when `cancel()` is called from a subscription.
You can also add multiple `onDone` listeners.
`StreamD` is a wrapper on the default Dart Stream, but with an additional `listenD` method.

## About StreamD

The minor hassle with default Dart Streams:
- the `onDone` event handler is not triggered when `cancel()` is called from a `StreamSubscription`,
so it may be tricky to identify the exact moment when a `StreamSubscription` became no longer active if
we don't have access to its `StreamController` on a specific layer of the App.

The solution when calling `listenD`
- `onDone` event handler is always triggered once the stream is no longer active, even when `cancel()` is called from a `StreamSubscription`.

`StreamD` also allows you to add a listener with `addOnDone` that won't replace the previous `onDone` callback
and you can also close all `StreamSubscription` by calling `closeAll`

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

## Getting started

    dependencies:
      flutter:
        sdk: flutter
            
        # Add this line:
        stream_d: ^0.2.1

### Initializing a StreamD

```dart
final streamD = StreamD(stream);
```
## Usage

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

### Avoid calling listen and onDone from StreamD

It's important to call these methods when using `StreamD` and `StreamSubscriptionD`:
- **call listenD**, not `listen`
- **call addOnDone**, not `onDone`

`listen` and `onDone` are available for `StreamBuilder` internal usage only, so
if you want to still use them, please use the default Dart `Stream` instead.

## License

[MIT](LICENSE)

## Contacting me

📧 rodrigo@wisetap.com
