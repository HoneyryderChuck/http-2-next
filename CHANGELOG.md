## 0.1.0

* first release
* change namespace to move away from forked project
* make it fully compliant with h2spec
* allow frame size negotiation

## 0.1.1

* fixing pseudo headers verification
* do not close stream when receiving frames from streams we've refused locally

## 0.1.2

* bugfix: do not update connection remote window on SETTINGS frame (aka the Cloudfront issue)

## 0.2.0

* support for the ORIGIN frame

## 0.2.1

* updated syntax to be ruby 2.7 compliant and warning free

## 0.2.2

* hotfix: the connection window was being updated when receiving WINDOW_UPDATEs for a stream.

## 0.2.3

* bugfix: allow stream to send empty end-stream DATA frame even if remote window is exhausted.
* avoid needless header downcase calls.
* using class_eval instead of define_method for performant lookups.