import ./types, ./nolockstream

type
  HasOp = concept l, var v
    BinaryOutput <~ l
    BinaryInput ~> v

template `<~>`*[bio: static BinaryIOKind, T: HasOp](io: BinaryIO[bio], x: T) =
  when bio == bio_input:
    mixin `~>`
    io ~> x
  elif bio == bio_output:
    mixin `<~`
    io <~ x

func `<<-`*[T](desc: typedesc[T], data: string): T {.inline.} =
  let inp = BinaryInput.init(data)
  inp <~> result
  if not inp.stream.atEnd():
    raise newException(ValueError, "expect EOF")

func `~>$`*[T](target: T): string {.inline.} =
  let oup = BinaryOutput.init()
  oup <~> target
  oup.data()
