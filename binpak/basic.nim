import std/[streams, varints]
import ./types

template genForNumber(T: typed) =
  proc `~>`*(io: BinaryInput, x: var T) {.inline.} =
    x = io.stream.`read T`()
  proc `<~`*(io: BinaryOutput, x: T) {.inline.} =
    io.stream.write(x)

genForNumber(uint8)
genForNumber(uint16)
genForNumber(uint32)
genForNumber(uint64)
genForNumber(int8)
genForNumber(int16)
genForNumber(int32)
genForNumber(int64)

template stealStringStream(s: StringStream): openarray[byte] =
  let pos {.gensym.} = s.getPosition()
  s.data.toOpenArrayByte(pos, high(s.data))

proc `~>`*(io: BinaryInput, x: var uint) {.inline.} =
  var ret: uint64
  let len = readVu64(stealStringStream(io.stream), ret)
  io.stream.setPosition(io.stream.getPosition + len)
  x = uint ret
proc `<~`*(io: BinaryOutput, x: uint) {.inline.} =
  var buffer: array[maxVarIntLen, byte]
  let len = writeVu64(buffer, uint64 x)
  io.stream.writeData(buffer.addr, len)

proc `~>`*(io: BinaryInput, x: var int) {.inline.} =
  var ret: uint
  io ~> ret
  x = int decodeZigzag ret
proc `<~`*(io: BinaryOutput, x: int) {.inline.} =
  io <~ uint encodeZigzag x

proc `~>`*(io: BinaryInput, x: var bool) {.inline.} =
  var ret: uint8
  io ~> ret
  x = ret != 0
proc `<~`*(io: BinaryOutput, x: bool) {.inline.} =
  io <~ (if x: 1'u8 else: 0'u8)
