# NIOStomp

Example of an interaction with a [STOMP](https://stomp.github.io) server based on [SwiftNIO](https://github.com/apple/swift-nio). Currently, this is **NOT** a usable STOMP client library, but only a trivial example upon which such library could be built.

# How to run?

Install a STOMP server, for example [RabbitMQ](https://www.rabbitmq.com) with a STOMP plugin. You can easily install it on macOS with [Homebrew](http://brew.sh):

```
brew install rabbitmq
rabbitmq-plugins enable rabbitmq_stomp
```

Run the server in background:

```
brew services start rabbitmq 
```

Start the client in the clone of this repository:

```
swift run NIOStomp
```

You should see something close to this output if the connection was established successfully:

```
CONNECTED
server:RabbitMQ/3.9.14
session:session-odhuI6DKb7XDvM7VApcPPQ
heart-beat:0,0
version:1.2
```
