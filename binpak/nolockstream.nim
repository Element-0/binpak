## String stream that no locks
## Internal usage

type NoLockStream* = object
  buf: string
  pos: int

func init*(stream: var NoLockStream, str: string) =
  stream.buf = str
  stream.pos = 0

func data*(self: NoLockStream): string = self.buf

func seek*(str: var NoLockStream, off: int) =
  ## unsafe seek
  str.pos += off

func remainBytes*(stream: NoLockStream): int = stream.buf.len - stream.pos

template remainOpenArray*(str: NoLockStream): openarray[byte] =
  str.buf.toOpenArrayByte(str.pos, str.buf.high)

func atEnd*(str: NoLockStream): bool = str.remainBytes == 0

func read*[T](str: var NoLockStream, desc: typedesc[T]): T =
  if sizeof(T) > str.remainBytes:
    raise newException(EOFError, "target type is too large")
  copyMem(addr result, addr str.buf[str.pos], sizeof T)
  str.seek sizeof T

func readBuffer*(str: var NoLockStream, buffer: var openarray[byte]) =
  if buffer.len > str.remainBytes:
    raise newException(EOFError, "target buffer is too large")
  copyMem(addr buffer, addr str.buf[str.pos], buffer.len)
  str.seek buffer.len

func readBuffer*(str: var NoLockStream, buffer: var string) =
  if buffer.len > str.remainBytes:
    raise newException(EOFError, "target buffer is too large")
  if buffer.len > 0:
    copyMem(addr buffer[0], addr str.buf[str.pos], buffer.len)
    str.seek buffer.len

func write*[T](str: var NoLockStream, data: T) =
  let oldpos = str.buf.len
  setLen(str.buf, oldpos + sizeof T)
  copyMem(addr str.buf[oldpos], unsafeAddr data, sizeof T)
  str.pos = str.buf.len - 1

func writeBuffer*(str: var NoLockStream, buffer: openarray[byte]) =
  let oldpos = str.buf.len
  setLen(str.buf, oldpos + buffer.len)
  copyMem(addr str.buf[oldpos], unsafeAddr buffer, buffer.len)
  str.pos = str.buf.len - 1

func writeBuffer*(str: var NoLockStream, buffer: string) =
  let oldpos = str.buf.len
  setLen(str.buf, oldpos + buffer.len)
  copyMem(addr str.buf[oldpos], unsafeAddr buffer[0], buffer.len)
  str.pos = str.buf.len - 1
