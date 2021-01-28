import std/[streams, varints]
import ./types, ./nolockstream

template genForNumber(T: typed) =
  func `~>`*(io: BinaryInput, x: var T) {.inline.} =
    x = io.stream.read(T)
  func `<~`*(io: BinaryOutput, x: T) {.inline.} =
    io.stream.write(x)

genForNumber(uint8)
genForNumber(uint16)
genForNumber(uint32)
genForNumber(uint64)
genForNumber(int8)
genForNumber(int16)
genForNumber(int32)
genForNumber(int64)

func `~>`*(io: BinaryInput, x: var uint) {.inline.} =
  var ret: uint64
  io.stream.seek readVu64(io.stream.remainOpenArray, ret)
  x = uint ret
func `<~`*(io: BinaryOutput, x: uint) {.inline.} =
  var buffer: array[maxVarIntLen, byte]
  let len = writeVu64(buffer, uint64 x)
  io.stream.writeBuffer(buffer.toOpenArray(0, len - 1))

func `~>`*(io: BinaryInput, x: var int) {.inline.} =
  var ret: uint
  io ~> ret
  x = int decodeZigzag ret
func `<~`*(io: BinaryOutput, x: int) {.inline.} =
  io <~ uint encodeZigzag x

func `~>`*(io: BinaryInput, x: var bool) {.inline.} =
  var ret: uint8
  io ~> ret
  x = ret != 0
func `<~`*(io: BinaryOutput, x: bool) {.inline.} =
  io <~ (if x: 1'u8 else: 0'u8)
