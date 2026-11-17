///|
#cfg(not(target="js"))
fn main {
  abort(
    "Differential supervisor currently uses the JS target; other backends have separate official conformance reports",
  )
}
