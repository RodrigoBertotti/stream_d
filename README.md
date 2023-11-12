# StreamD

Stream that triggers the `onDone` event handler even when `cancel()` is called from a subscription.
You can also add multiple `onDone` listeners and close all subscriptions from the stream.
`StreamD` is based on the default Dart Stream.

## About StreamD

The problem with default streams:
- the default `onDone` event handler is not triggered when `cancel()` is called from a `StreamSubscription`,
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
final StreamD = StreamD(controller: controller2);
final StreamDSubscription = streamD.listenD((event) {});
StreamDSubscription.addOnDone(() {
  print("(2) With StreamD: onDone was triggered!");
});
print("(1) With StreamD: let's call cancel() on the subscription...");
StreamDSubscription.cancel();
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
        stream_d: ^0.0.2

### Initializing a StreamD

You can either initialize a Stream from a controller in case you have access to it, or from a Stream (e.g. from Firebase)

#### Initializing StreamD from a controller
```dart
final controller = StreamController();
final streamD = StreamD(controller: controller);
```
#### Initializing StreamD from a stream
```dart
final stream = firestore.collection("messages").doc(conversationId).snapshots();
final streamD = StreamD.fromStream(stream);
```
## Usage

### Listening
```dart
final subscription = streamD.listenD((event) {
    print(event);
});
```
### Adding onDone listener to a subscription
```dart
final subscription = streamD.listenD((event) {});
subscription.addOnDone(() {
    print("onDone was called!");
});
```
### In case you want to close all subscriptions
```dart
streamD.close();
```
### Avoid calling listen and onDone from StreamD

It's important to call these methods when using `StreamD`:
- **call listenD**, not `listen`
- **call addOnDone**, not `onDone`

`listen` and `onDone` are available for `StreamBuilder` internal usage only, so
if you want to still use them, please use the default `Stream` instead.

## License

[MIT](LICENSE)

## Contacting me

📧 rodrigo@wisetap.com
