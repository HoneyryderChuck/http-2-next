## 0.3.0

No significant API changes. The main "features" are the RBS type signatures for the library modules.

## 0.2.6

* feature: Connection#max_streams=(int); this way one can set the max number of streams, thereby bypassing the limits established in the handshake. A lot of servers treat MAX_CONCURRENT_STREAMS not as the limit of allowed streams, but the number of inflight streams. By setting this to Float::INFINITY, users can take advantage of it.

## 0.2.5

* bugfix: fixed bookkeeping of recently-closed streams.

## 0.2.4

* bugfix: wrong window update accounting check causing random flow control errors.

## 0.2.3

* bugfix: allow stream to send empty end-stream DATA frame even if remote window is exhausted.
* avoid needless header downcase calls.
* using class_eval instead of define_method for performant lookups.

## 0.2.2

* hotfix: the connection window was being updated when receiving WINDOW_UPDATEs for a stream.

## 0.2.1

* updated syntax to be ruby 2.7 compliant and warning free

## 0.2.0

* support for the ORIGIN frame

## 0.1.2

* bugfix: do not update connection remote window on SETTINGS frame (aka the Cloudfront issue)

## 0.1.1

* fixing pseudo headers verification
* do not close stream when receiving frames from streams we've refused locally

## 0.1.0

* first release
* change namespace to move away from forked project
* make it fully compliant with h2spec
* allow frame size negotiation
