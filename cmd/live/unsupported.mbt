///|
#cfg(not(any(target="native", target="wasm")))
fn main {
  abort("Live SDK example requires --target wasm or --target native")
}
