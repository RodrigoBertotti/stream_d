## v0.3.0
* `listen` method is disabled, because it may give an 
`Bad state: Stream has already been listened to.` error on a StreamBuilder.

## v0.2.1
* "description" update on pubspec.yaml

## v0.2.0
* Fixes and adjustments
* `closeAll` method removed

## v0.1.0
* Refactoring: the result of `listenD(..)` is an instance of `StreamSubscriptionD`, in `StreamSubscriptionD`
  you can add onDone listeners with `addOnDone(...)`
* README file was updated

## v0.0.2
* README file was updated

## v0.0.1
* First release

