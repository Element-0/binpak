type smallstr* = ref object
  raw*: array[255, byte]
  len*: uint8

converter toString*(s: smallstr): string =
  result = newString(s.len)
  if s.len > 0:
    copyMem(result.cstring, s.raw.addr, s.len)

converter toSmallString*(s: string): smallstr =
  new result
  if s.len > int uint8.high:
    raise newException(RangeDefect, "invalid smallstr")
  result.len = uint8 s.len
  if s.len > 0:
    copyMem(result.raw.addr, s.cstring, s.len)

template ss*(x: string): smallstr =
  toSmallString(x)

template toOpenArray*(s: smallstr): openarray[byte] =
  s.raw.toOpenArray(0, s.len)