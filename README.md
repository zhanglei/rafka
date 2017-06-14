# rafka - Kafka with a Redis API

Rafka acts a gateway service and exposes Kafka using the Redis protocol.

## Status

This project is under heavy development and the [protocol](https://github.skroutz.gr/skroutz/rafka/wiki/Protocol) is still in draft version.

Why rafka?
----------
- Hide Kafka low-level details from the application & provide sane defaults.
- Use a Redis client instead of a Kafka client. This particularly useful
  in languages that lack a proper Kafka driver or do not provide
  concurrency primitives to implement buffering & other optimizations.

Dependencies
------------
- `golang-github-confluentinc-confluent-kafka-go-dev` (go librdkafka bindings)
- `golang-github-urfave-cli-dev`

Installation
------------

```shell
$ apt-get install golang librdkafka-dev
$ go get -u golang.skroutz.gr/skroutz/rafka
```




Protocol
--------------
Rafka exposes a Redis protocol and tries to keep Redis semantics where
possible. We also try to design the protocol in a way that Rafka can be
replaced by a plain Redis instance so that it's easier to test client code and
libraries.





Consumer
--------
Kafka is designed in a way that each consumer represents a worker processing
Kafka messages, that worker sends heartbeats and is depooled from its group
when it misbehaves. Those semantics are preserved in `rafka` by using
**stateful connections**. In `rafka` a connection is tied with a set of Kafka
consumers.  Consumers are not shared between connections and, once the
connection closes, the consumers are destroyed too.

Each connection first needs to identify itself by using `client setname
<group.id>:<name>` and then it can begin processing messages by issuing `blpop`
calls on the desired topics. Each message should be explicitly acknowledged
so it can be commited to Kafka. Acks are `rpush`ed to the special `acks` key.




Producer
--------
Each client connection to Rafka is tied to a single Producer.
Producers are not shared between connections and once the connection closes, its
Producer is also destroyed.

Producers can immediately begin producing using `RPUSHX`, without having to call
`CLIENT SETNAME` first.

Since the produced messages are buffered in Rafka and are eventually flushed
to Kafka (eg. when the client connection is closed), `DUMP` can also be used to
force a synchronous flush of the messages.



API
---------------
Generic commands:
- `PING`

## Producer
Commands:
- `RPUSHX topics:<topic> <message>`: produce a message
- `DUMP <timeoutMs>`: flushes the messages to Kafka. This is a blocking operation, it returns until all buffered messages are flushed or the timeout exceeds

Example using Redis:
```
rpushx topics:greetings "hello there!"
```





## Consumer
Commands:
- `CLIENT SETNAME <group.id>:<name>`: sets the consumer's group & name
- `CLIENT GETNAME`
- `BLPOP topics:<topic> <timeoutMs>`: consumes the next message from <topic>
- `RPUSH acks <topic>:<partition>:<offset>`: commit the offset for the given topic/partition

Example using Redis:
```
127.0.0.1:6380> client setname myapp:a-consumer
"OK"
127.0.0.1:6380> blpop topics:greetings 1000
1) "topic"
2) "greetings"
3) "partition"
4) (integer) 2
5) "offset"
6) (integer) 10
7) "value"
8) "hello there!"
# ... do some work with the greeting...
127.0.0.1:6380> rpush acks greetings:2:10
"OK"
```

Usage
-----

```shell
$ vim kafka.cfg # Add brokers
$ go build && ./rafka -k ./kafka.cfg

```

TODO
----
- Investigate a slow consumer scenario
- Implement a thin Ruby Client on top of Redis
- Proper tests
