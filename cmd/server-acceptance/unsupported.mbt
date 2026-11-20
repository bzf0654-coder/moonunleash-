///|
#cfg(not(any(target="native", target="wasm")))
fn main {
  abort("Real server acceptance requires --target wasm or --target native")
}
