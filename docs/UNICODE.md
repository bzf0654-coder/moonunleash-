# Unicode 分桶裁决：UTF8 字节 Golden，不冒充 Node6.12.2 全量兼容

## 结论与边界

SDK 的明确策略是：对 `group + ":" + stickyId` **不作 Unicode 归一化**，编码为 UTF8，执行 MurmurHash3 x86_32，得到完整无符号 32 位值，再计算 `hash % scale + 1`。rollout 使用 seed=0、scale=100；全局权重变体使用 seed=86028157、scale=1000。本轮只加独立证据与回归，不改 SDK 算法。

**这不是冻结 Node oracle 的 Unicode parity pass。** 未修改的 `unleash-client@6.12.2` 原48例仍然28匹配、20失配。保留这一兼容例外，不改输入、不换 oracle、不重写首份报告、不从 MoonBit 输出反推 Golden。

Node 路径把原始 JS 字符串交给 `murmurhash3js@3.0.1`：其 x86_32 每个 UTF16 code unit 只取 `charCodeAt(i) & 0xff`，长度也按 code unit 计数；这**既不是 UTF8，也不是 UTF16LE**。因此非 ASCII 的 groupId、用作变体组的 featureName，以及 sticky ID 都可能改变结果。仅限制 userId 为 ASCII 并不足以保证 parity；所有实际参与 hash 的组成部分均须满足共同 ASCII 范围。28个最终结果相同并不等于完整 hash 相同，其中12个 default-strategy Boolean 根本不做 hash。

NFC `é`（U+00E9；UTF8 `c3a9`）与 NFD `é`（U+0065 U+0301；`65cc81`）刻意视作不同输入；emoji/非BMP 使用真实 UTF8 字节而非 UTF16 低字节。本轮冻结策略只覆盖 well-formed Unicode 字符串；独立工具在编码前拒绝孤立 surrogate，**不据此声称 SDK 对 malformed UTF16 已有相同拒绝行为**。

## 固定规范依据与裁定范围

固定 [client-spec README](https://github.com/Unleash/client-specification/blob/9ef6efa01feabeb699857192ad8106fd7d990235/README.md#L4-L6) 要求预设 feature/context 的跨平台预期；其 [18号 UTF8 名称用例](https://github.com/Unleash/client-specification/blob/9ef6efa01feabeb699857192ad8106fd7d990235/specifications/18-utf8-flag-names.json) 两项均为 default 策略、空 context、Boolean=true，未执行 hash。该固定22套、README和所附 contracts 中未找到明确的 Unicode→hash bytes 编码条款或可区分编码的分桶向量。这个结论仅针对所核验固定基线，不声称所有上游文档永远没有规定。

UTF8 选择另有官方仓库实现先例：Rust SDK0.15.0 的[发布包 VCS 身份](https://docs.rs/crate/unleash-api-client/0.15.0/source/.cargo_vcs_info.json) 对应提交 `637ca15c8a8567e3ffcf269626ab26b3a84315df`；其 [strategy.rs:123–153](https://github.com/Unleash/unleash-rust-sdk/blob/637ca15c8a8567e3ffcf269626ab26b3a84315df/src/strategy.rs#L123-L153) 将 `format!("{}:{}", group, identifier)` 交给 Cursor/Murmur3，采用相同 seed0/86028157 与 `% modulus + 1`。Rust1.74 的 [String::AsRef<[u8]>](https://github.com/rust-lang/rust/blob/1.74.0/library/alloc/src/string.rs#L2597-L2601) 取 UTF8 bytes，[Cursor::Read](https://github.com/rust-lang/rust/blob/1.74.0/library/std/src/io/cursor.rs#L315-L324) 读取这些字节；路径不做 NFC/NFD 归一化。这里只引用行为，不复制实现；[SDK 原 Apache-2.0 许可](https://raw.githubusercontent.com/Unleash/unleash-rust-sdk/637ca15c8a8567e3ffcf269626ab26b3a84315df/LICENSE)。

**裁定：固定规范未明确裁定 Unicode hash 编码；本实现明确选择无归一化 UTF8，经双独立字节参考验证，并与此固定 Rust 实现一致。Node6.12.2 的原20差异作为已解释的兼容例外保留，不称其违反已统一的 Unicode 编码规范。** Rust 先例与独立 hash 证明不冒充对整个 Rust SDK 的差分验证。

## 独立参考链与供应链

独立环境由 [package manifest](<../tools/hash-reference/package.json>)、[npm configuration](<../tools/hash-reference/.npmrc>) 和 [独立锁文件](<../tools/hash-reference/pnpm-lock.yaml>) 定义；不复用或修改 [旧 oracle 锁文件](<../tools/reference/pnpm-lock.yaml>)。

| 用途 | 固定包 | 实现及注意事项 |
|---|---|---|
| 主参考 | murmur3hash-wasm@1.0.1 | Hyperdivision 的**手写 WAT**，不是 C/Rust 编译物；依据 Appleby x86_32；输入 Uint8Array/Buffer，内嵌预编译 Wasm，同步 Module/Instance，无 native addon 或安装期编译。返回 signed i32，必须先 `>>> 0`。 |
| 第二参考 | murmur-32@1.0.0 | LinusU 独立 JS `Math.imul`/fmix 实现，使用 ArrayBuffer 字节入口，完全不经 pid。它会原地修改完整输入字，故每次/每个 seed 都复制成新的精确长度 ArrayBuffer。返回4字节 ArrayBuffer，按本机 UInt32 解码；工具明确要求 LE host。 |
| 主参考依赖 | nanoassert@2.0.0 | ISC；断言辅助。 |
| 第二参考依赖 | fmix@1.0.0；encode-utf8@2.0.0 | MIT；正常 Golden 仅使用明确字节入口，不使用后者的字符串编码分支。 |

[参考适配器及 provenance](<../tools/hash-reference/reference.mjs>) 对每个完整 uint32 严格比较两实现，**不只比较 modulo 之后的桶**；任何不一致立即失败。调用者验证 seed 为0..0xffffffff整数，限制开发参考输入≤65536字节（Wasm一页内存）；后者是参考工具限制，不是新增 SDK 输入限制。

[供应链审计工具](<../tools/hash-reference/audit-packages.mjs>) 从固定 npm registry 读取五包的精确版本 metadata，核对 gitHead/license/完整 SRI，实际下载 tarball 并计算 SHA512 SRI；再把安装文件逐一同 SRI 验证过的归档内容比较。关键实现、内嵌 Wasm、WAT、发布测试及依赖实现 SHA256 均冻结在 [Golden provenance](<../artifacts/unicode-verdict.golden.v1.json>)，归档 SHA256 和执行结果在 [供应链审计](<../artifacts/unicode-verdict.supply-chain.json>)。安装、审计均不运行生命周期脚本。

许可证现状见 [许可证记录](<../third_party/hash-reference/README.md>)：ISC两包和 fmix 的完整发布许可证已原样保存；murmur-32 与 encode-utf8 的 metadata 声明 MIT，但精确版本 tarball 未含完整 LICENSE，固定提交的 `license` / `LICENSE` URL 也均404。这里只诚实记录缺口，不伪造 copyright/year；未在仓库中 vendoring 这两包实现源。

### 固定源码来源

- [主参考 index](https://raw.githubusercontent.com/hyperdivision/murmur3hash-wasm/0f042767dea6a467cf451b95bdc6c7a3f5834dfd/index.js)、[手写 WAT](https://raw.githubusercontent.com/hyperdivision/murmur3hash-wasm/0f042767dea6a467cf451b95bdc6c7a3f5834dfd/murmur3.wat)、[发布测试](https://raw.githubusercontent.com/hyperdivision/murmur3hash-wasm/0f042767dea6a467cf451b95bdc6c7a3f5834dfd/test.js)。
- [第二参考实现](https://raw.githubusercontent.com/LinusU/murmur-32/56279a399bcda62c8d67b75b76dc0c74bb063327/index.js)、[发布测试](https://raw.githubusercontent.com/LinusU/murmur-32/56279a399bcda62c8d67b75b76dc0c74bb063327/test.js)。
- [Appleby 原始 x86_32](https://raw.githubusercontent.com/aappleby/smhasher/61a0530f28277f2e850bfc39600ce61d02b518de/src/MurmurHash3.cpp)，主参考 WAT 明确引用该版本。
- [冻结 Unleash Node util](https://raw.githubusercontent.com/Unleash/unleash-client-node/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/strategy/util.ts)、[pid 精确版本metadata](https://registry.npmjs.org/murmurhash3js/3.0.1)。它们只解释旧 oracle，不是独立 UTF8 Golden 来源。

## 冻结内容与顺序

[裁决程序](<../tools/unicode-verdict.mjs>) 按以下顺序运行：

1. 验证原 fixtures 全部内容 SHA、冻结语料 seed/构造器/输入 SHA、原报告与旧锁不变。
2. 执行两参考自己的发布向量：Wasm发布测试29次 hash断言；JS发布8个字符串向量，再用显式 UTF8→新 ArrayBuffer 字节入口重跑同8个向量。这里只执行 hash断言，不声称运行了上游 formatter/TypeScript 检查；以小型 test-runner shim 避免额外安装 devDependencies。
3. 另做40项跨参考字节检查（seed=0/1/86028157/0xffffffff，空、NUL、高位、完整块及尾长0..3），加2项固定 ASCII 锚点。
4. 仅从双参考一致的**显式 UTF8 bytes、seed、完整 uint32**构造并先冻结 [Golden](<../artifacts/unicode-verdict.golden.v1.json>)。此时尚未导入/评估 Node oracle，也未运行或读取候选 MoonBit 输出。之后读回磁盘 Golden 再生成回归。
5. 从 Golden 生成 [两项稳定白盒测试](<../unicode_generated_wbtest.mbt>)：72个文本×两 seed＝144个完整 hash断言；真实公开 `Snapshot::parse` / `Context::parse` / `evaluate` / `get_variant` 执行原48个及新增64个API决策，共112例。API预期不是运行 Moon 后抄下来的。
6. 最后才加载**未修改** Node6.12.2 oracle，重放原48例，核对其 `node` 字段与 [首份差分报告](<../artifacts/differential.initial.v1.json>) 完全一致。另将明确构造的 UTF16低字节序列送入两独立字节参考，逐条解释 Node桶及结果；这条 legacy 支线不参与 UTF8 Golden。
7. 保留 [首份裁决](<../artifacts/unicode-verdict.initial.v1.json>) 与 [当前冻结裁决](<../artifacts/unicode-verdict.json>)，每例均含完整 hash输入、字节hex、长度、seed、uint32、桶、预期/Node实际及原因。

新增64例专门隔离非ASCII groupId、非ASCII featureName、NFC/NFD、非BMP：八个 feature×四个 userId×Boolean/variant；其中含 ASCII sticky ID 配非ASCII group/feature。primitive 再补充空串、ASCII、NUL、冒号及两个Unicode base加0..3个ASCII尾字节，覆盖有完整块时的四种尾长。

默认程序只读验证，缺产物或发现漂移即失败。显式 `--generate` **仅初始化缺失文件**，已有 Golden/裁决不同仍然失败，不能用重生成清除首败。JSON内容仅容忍CRLF/LF差别；Moon代码按词法token核对，保留字符串与 raw JSON 的内容，仅容忍 formatter 空白/尾逗号，不忽略数值、断言或字段改变。

[验证器负向测试](<../tools/hash-reference/test-verifier.mjs>) 所有破坏只在内存中发生，不写或临时篡改任何 Frozen/Moon 文件；12项拒绝检查包括 hash常量、API预期、API调用、断言删除、非法seed、超长字节、错误输入类型和孤立surrogate，另有2项纯格式容忍检查和输入不被JS参考破坏的检查。默认验证前后三份Frozen JSON的hash/mtime均不变。

## 原20处差异逐项解释

`R`=feature `unicode-rollout`，其阈值为37/100；`V`=feature `全局变体-ø`，control/treatment边界为250/1000。完整case IDs和所有48例在 [裁决](<../artifacts/unicode-verdict.json>)。下表每一行对应一个原始失败；没有合并删除14个 rollout/传播失败。

| i / userId | feature / kind | UTF8桶 / Node低字节桶 | UTF8预期 → Node6.12.2实际；原因 |
|---|---|---:|---|
| 0 / 用户甲 | R / boolean | 41 / 12 | false → true；跨37阈值 |
| 0 / 用户甲 | R / variant | 41 / 12 | feature_enabled false → true；传播上一条，name都为disabled、enabled都false |
| 1 / 用户乙 | R / boolean | 41 / 30 | false → true；跨37阈值 |
| 1 / 用户乙 | R / variant | 41 / 30 | feature_enabled false → true；传播上一条 |
| 3 / é (NFD) | R / boolean | 58 / 18 | false → true；跨37阈值 |
| 3 / é (NFD) | R / variant | 58 / 18 | feature_enabled false → true；传播上一条 |
| 3 / é (NFD) | V / variant | 248 / 996 | control → treatment；跨250边界，Node另有blue payload |
| 5 / φriend | V / variant | 49 / 902 | control → treatment；跨250边界，Node另有blue payload |
| 6 / مرحبا | R / boolean | 92 / 29 | false → true；跨37阈值 |
| 6 / مرحبا | R / variant | 92 / 29 | feature_enabled false → true；传播上一条 |
| 6 / مرحبا | V / variant | 84 / 519 | control → treatment；跨250边界，Node另有blue payload |
| 7 / नमस्ते | R / boolean | 20 / 49 | true → false；跨37阈值 |
| 7 / नमस्ते | R / variant | 20 / 49 | feature_enabled true → false；传播上一条 |
| 7 / नमस्ते | V / variant | 124 / 409 | control → treatment；跨250边界，Node另有blue payload |
| 9 / 東京 | R / boolean | 22 / 95 | true → false；跨37阈值 |
| 9 / 東京 | R / variant | 22 / 95 | feature_enabled true → false；传播上一条 |
| 9 / 東京 | V / variant | 172 / 512 | control → treatment；跨250边界，Node另有blue payload |
| 11 / 🌍 | R / boolean | 4 / 74 | true → false；跨37阈值 |
| 11 / 🌍 | R / variant | 4 / 74 | feature_enabled true → false；传播上一条 |
| 11 / 🌍 | V / variant | 175 / 988 | control → treatment；跨250边界，Node另有blue payload |

合计 **7 rollout Boolean + 7 feature_enabled传播 + 6 weighted variant = 20**。六个 weighted变体两端的 `enabled`/`feature_enabled` 都为true；差异为名称与仅 treatment 持有的 `{type:"string",value:"blue"}` payload。原 `é`、`😊`、NUL、`ø` 等最终决策碰巧匹配，也不能据此声称 hash/encoding一致。

例：`共享组-🌍:用户甲` 的UTF8 hex为 `e585b1e4baabe7bb842df09f8c8d3ae794a8e688b7e794b2`，24字节，seed0完整uint32=1483014240，桶41；legacy低字节hex为 `71abc42d3c0d3a283732`，10字节，完整uint32=3785767911，桶12。完整值及长度已证明差异发生在编码入口，而不是用最终Boolean猜测。此前 UTF8→Latin1 pid桥的48/48只属于机制诊断，不被用作本轮 Golden 或完整兼容证据。

## 可复现命令（PowerShell；从仓库根目录运行）

以下使用实际核验的 Node24.13.1、pnpm11.28.5。只影响当前进程环境，不改全局配置；不启动服务，不运行Moon。

```powershell
$node = 'E:\node.exe'
$pnpm = "C:\Users\f'b'z\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\pnpm\bin\pnpm.mjs"
$ref = 'D:\D盘zcode\moonunleash\tools\hash-reference'
$env:PATH = 'E:\;' + $env:PATH
$env:CI = 'true'
$env:XDG_STATE_HOME = "$ref\.data"
& $node --version
& $node $pnpm --version
& $node $pnpm --dir $ref install --frozen-lockfile --ignore-scripts --node-linker=hoisted "--store-dir=$ref\.pnpm-store" "--cache-dir=$ref\.cache"
& $node tools/hash-reference/selftest.mjs
& $node tools/hash-reference/audit-packages.mjs
& $node tools/unicode-verdict.mjs
& $node tools/hash-reference/test-verifier.mjs
```

仅首次创建缺失证据时使用以下命令；正常复核不需要：

```powershell
& $node tools/unicode-verdict.mjs --generate
& $node tools/hash-reference/audit-packages.mjs --record
```

### 本轮执行记录（保留首次环境异常/失败）

- 首次安装：在独立目录执行 `install --ignore-scripts --node-linker=hoisted`，安装五包成功，但 pnpm11未按旧式配置读取局部store键，警告后用了共享 `D:\.pnpm-store\v11`。未改全局配置；不删除这个未知归属共享store。
- 第一次隔离重试：`install --force --frozen-lockfile --ignore-scripts --node-linker=hoisted --store-dir=<local> --cache-dir=<local> --state-dir=<local>` **exit1**，报 `Unknown option: 'state-dir'`；此时未开始重装。保留这次失败，不冒充首次成功。
- 修正：去掉不支持的CLI flag，以当前进程 `XDG_STATE_HOME` 配置state，保留明确绝对 `--store-dir` / `--cache-dir`，加 `--force` 重装成功。pnpm记录确认store为项目内 `.pnpm-store\v11`；五包安装均 `--ignore-scripts`，无生命周期构建。
- 双参考自测：29+8+8个发布hash断言、40额外字节交叉检查、2固定ASCII锚点，全部通过。重复运行不改变Frozen。
- `--generate` 首次冻结成功后，默认只读复核通过；72 primitive文本/144完整hash、112 API预期、原20 Node失配分类均稳定。
- 供应链网络审计五包全部通过：精确gitHead/license/SRI、下载归档SHA512、已安装关键源码一致；缺失的两份完整MIT许可证单独记录，不夸大。
- 负向/格式/只读/输入复制检查通过：12拒绝、2格式容忍、3份Frozen JSON hash/mtime不变。
- Unicode证据子任务**未运行 Moon编译、测试、formatter 或 info**。生成源码冻结后已交Root集中编译/格式化；实际Moon后端结果由集成报告给出，本文件的Node通过不替代Moon测试。

### 不变身份

- 原语料 `inputSha256`：`7d801d96ca2820e8ed81e850d2d22c221374dcdd10e985a1ec4b80bf10ed93a8`。
- [原首份报告](<../artifacts/differential.initial.v1.json>) 与 [原当前报告](<../artifacts/differential.json>) SHA256均为 `6f6f9eba3ce515a4a7eef4c36cd201f9f27d51622cc978ea5e2b3976281cef6d`。
- [旧oracle锁](<../tools/reference/pnpm-lock.yaml>) SHA256：`18f136de5c0b1044e1a713e1ec516ff2b9e8801905efa2be2c847e09e27907b9`。
- [独立Golden](<../artifacts/unicode-verdict.golden.v1.json>) SHA256：`cedb1ab11e87318093a69ab1a6430d8df4559b4a5d22c972b2d6c54fdeec8de1`。其内容在读取任何Moon候选输出前已冻结；没有将旧桥报告或候选输出当作Golden。
