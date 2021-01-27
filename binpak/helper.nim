import ./types

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
