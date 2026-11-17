///|
#cfg(not(target="wasm"))
fn main {
  abort(
    "HTTP smoke currently requires --target wasm; native adapter verification remains pending",
  )
}
