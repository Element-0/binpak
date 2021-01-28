import ./nolockstream

type
  BinaryIOKind* {.pure.} = enum
    bio_input
    bio_output
  BinaryIO*[bio: static BinaryIOKind] = ref object
    stream*: NoLockStream

  BinaryInput* = BinaryIO[bio_input]
  BinaryOutput* = BinaryIO[bio_output]

proc init*(_: type BinaryInput, text: string): BinaryInput {.noSideEffect, gcsafe, locks: 0.} =
  new result
  result.stream.init text

proc init*(_: type BinaryOutput): BinaryOutput {.noSideEffect, gcsafe, locks: 0.} =
  new result

proc data*(self: BinaryOutput): string = self.stream.data