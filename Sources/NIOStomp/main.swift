//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import NIOCore
import NIOPosix

enum STOMPCommand: String {
    case connect = "CONNECT"
    case connected = "CONNECTED"
    case send = "SEND"
    case subscribe = "SUBSCRIBE"
    case unsubscribe = "UNSUBSCRIBE"
    case ack = "ACK"
    case nack = "NACK"
    case begin = "BEGIN"
    case commit = "COMMIT"
    case abort = "ABORT"
    case disconnect = "DISCONNECT"
    case message = "MESSAGE"
    case receipt = "RECEIPT"
    case error = "ERROR"
}

private final class STOMPOutboundHandler: ChannelOutboundHandler {
    typealias OutboundIn = STOMPCommand
    typealias OutboundOut = ByteBuffer

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let command = unwrapOutboundIn(data)
        let frame = """
        \(command.rawValue)
        accept-version:1.2
        login:guest
        passcode:guest

        \0
        """

        let buffer = context.channel.allocator.buffer(string: frame)
        context.write(wrapOutboundOut(buffer), promise: promise)
    }
}

private final class STOMPInboundHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer

    private func printByte(_ byte: UInt8) {
        #if os(Android)
        print(Character(UnicodeScalar(byte)),  terminator:"")
        #else
        fputc(Int32(byte), stdout)
        #endif
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = self.unwrapInboundIn(data)
        while let byte: UInt8 = buffer.readInteger() {
            printByte(byte)
        }
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.close(promise: nil)
    }
}


let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let bootstrap = ClientBootstrap(group: group)
    // Enable SO_REUSEADDR.
    .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    .channelInitializer { channel in
        channel.pipeline.addHandler(STOMPInboundHandler()).flatMap {
            channel.pipeline.addHandler(STOMPOutboundHandler())
        }
    }
defer {
    try! group.syncShutdownGracefully()
}

// First argument is the program path
let arguments = CommandLine.arguments
let arg1 = arguments.dropFirst().first
let arg2 = arguments.dropFirst(2).first

let defaultHost = "::1"
let defaultPort = 61613

enum ConnectTo {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

let connectTarget: ConnectTo
switch (arg1, arg1.flatMap(Int.init), arg2.flatMap(Int.init)) {
case (.some(let h), _ , .some(let p)):
    /* we got two arguments, let's interpret that as host and port */
    connectTarget = .ip(host: h, port: p)
case (.some(let portString), .none, _):
    /* couldn't parse as number, expecting unix domain socket path */
    connectTarget = .unixDomainSocket(path: portString)
case (_, .some(let p), _):
    /* only one argument --> port */
    connectTarget = .ip(host: defaultHost, port: p)
default:
    connectTarget = .ip(host: defaultHost, port: defaultPort)
}

let channel = try { () -> Channel in
    switch connectTarget {
    case .ip(let host, let port):
        return try bootstrap.connect(host: host, port: port).wait()
    case .unixDomainSocket(let path):
        return try bootstrap.connect(unixDomainSocketPath: path).wait()
    }
}()

try! channel.writeAndFlush(STOMPCommand.connect).wait()

_ = readLine()

// EOF, close connect
try! channel.close().wait()

print("NIOStomp client disconnected")
