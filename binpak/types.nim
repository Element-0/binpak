import std/streams

type
  BinaryIOKind* {.pure.} = enum
    bio_input
    bio_output
  BinaryIO*[bio: static BinaryIOKind] = object
    stream*: StringStream

  BinaryInput* = BinaryIO[bio_input]
  BinaryOutput* = BinaryIO[bio_output]

proc init*(_: type BinaryInput, text: string): BinaryInput =
  result.stream = newStringStream text

proc init*(_: type BinaryOutput): BinaryOutput =
  result.stream = newStringStream ""

proc data*(self: BinaryOutput): string = self.stream.data