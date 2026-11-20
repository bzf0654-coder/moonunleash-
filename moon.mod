// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "moonunleash/sdk"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/bzf0654-coder/moonunleash-"

license = "Apache-2.0"

keywords = [ "unleash", "feature-flags", "sdk", "rollout" ]

preferred_target = "wasm"

description = "MoonBit-native Unleash evaluation core and explicitly scoped server-side SDK"

import {
  "moonbitlang/regexp@0.3.7",
}
