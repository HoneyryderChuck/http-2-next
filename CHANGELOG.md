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