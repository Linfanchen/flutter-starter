# Flutter Starter

用 `flutter-starter` 选择起步模板，生成可以独立维护的标准 Flutter 应用。

[工程标准与演进路线](#工程标准与演进路线)涵盖业务分层、模板契约、验证门禁和实施顺序。

## 快速开始

安装 Flutter stable，把 Flutter SDK 的 `bin` 加入 `PATH`，然后运行 `flutter doctor`。CLI 需要 Dart 3.6 或更新版本。Windows 可以先用 Web 和 Chrome 验证，创建 Android 版本时再配置 Android 工具链。[Flutter 安装说明](https://docs.flutter.dev/install/manual)

在本仓库根目录激活 CLI。将 Dart 的 Pub 缓存 `bin` 加入 `PATH`。Windows 默认路径是 `%LOCALAPPDATA%\Pub\Cache\bin`。[Dart 命令激活说明](https://dart.dev/tools/pub/cmd/pub-global)

```powershell
dart pub global activate --source path tooling/flutter_starter
flutter-starter list
```

切换到你存放产品项目的目录，再创建 App。

```powershell
flutter-starter create my_app --template base --org com.example --platforms web --verify
cd my_app
flutter run -d chrome
```

`base` 提供基础首页与浅色、深色主题。`content` 提供文章列表与详情。`shop`、`character` 和 `course` 带独立的业务页面和本地示例数据。

```powershell
flutter-starter create my_shop --template shop --verify
flutter-starter create my_story --template character --verify
flutter-starter create my_course --template course --verify
```

- `shop` 从商品列表进入详情，加购后可调整数量、核对总价，并完成演示订单。重新打开应用后可恢复购物车，商品价格取自当前目录。
- `character` 从角色列表进入角色详情，再开始或继续剧情。角色目录和剧情状态分别由 ViewModel 管理，故事数据经过 DTO、Entity、Domain 分层；不同角色独立保存进度，失效场景回到故事开头。剧情数据位于 `lib/features/character/data/`。
- `course` 提供课程列表、课时目录和文字课时。标记完成后会保存进度，再次进入可继续第一节未完成的课时。

`content` 可以用 `--dart-define=CONTENT_API_BASE_URL=https://example.com/api/` 切换到远端。应用会请求 `GET /api/articles`，接口返回 JSON 数组，每项包含字符串 `id`、`title` 和 `body`。在应用组装入口切换 Repository，业务页面共用同一套领域模型。

`course` 可以用 `--dart-define=COURSE_API_BASE_URL=https://example.com/api/` 切换到远端。应用请求 `GET /api/courses`，接口返回课程数组，每项包含字符串 `id`、`title`、`description` 和 `lessons` 数组。每个课时包含字符串 `id`、`title` 和 `body`。保持课程与课时 ID 稳定，以便恢复本地进度。

`content` 和 `course` 共用配置解析。`APP_ENV` 支持 `dev`（默认）、`staging` 和 `prod`。`APP_USE_SAMPLE_DATA` 默认随 API 地址自动选择数据源，设为 `true` 可强制使用示例，设为 `false` 需要提供有效地址。配置错误会指出需要修改的键。

```powershell
flutter-starter create reader_app --template content --org com.example --platforms android,web --verify
```

默认生成 `base` 和 Web。`--verify` 会在生成过程中执行 `flutter analyze` 和 `flutter test`。需要构建 Web 产物时，在生成的项目目录运行 `flutter build web`。应用可以从该目录执行 `git init`，自行管理版本历史。

本地激活的命令会从当前 Starter checkout 读取模板。生成项目会带上自己需要的源码与依赖声明，移动目录后可重新运行 `flutter pub get`。

## 目录与扩展方式

```text
flutter-starter/
├── packages/starter_network/  # 模板共用的 JSON HTTP / SSE 客户端
├── packages/starter_storage/  # 按业务模板需要安装的本地键值存储
├── packages/starter_sync/     # 本地优先同步、游标和离线回退
├── packages/starter_realtime/ # 可选实时事件、Reducer 和重连状态机
├── packages/starter_database/ # 可选 Drift 数据库与迁移入口
├── packages/starter_config/   # 环境、API 地址和示例数据开关校验
├── packages/starter_auth/     # 会话生命周期与凭证存储接口
├── templates/base/           # 通用应用入口、主题及首页
├── templates/content/        # 覆盖首页并增加文章 Feature
├── templates/shop/           # 商品目录与购物车
├── templates/character/      # 角色选择与分支剧情
├── templates/course/         # 在线课程、课时学习和进度
└── tooling/flutter_starter/  # 调用 flutter create 并安装模板
```

生成项目的 `lib/app/` 负责组装应用，`lib/features/` 放产品业务。`packages/starter_network/` 是从 Starter 复制来的版本快照，使用项目内的相对路径依赖。已有产品可按自己的节奏合入基座更新。

所有模板继承 `lib/shared/starter_ui.dart`，共用主题构造、间距、加载和消息状态。`base` 首页的 **Open session demo** 可演示本地登录、重新打开页面恢复会话和退出。演示使用内存凭证；对接真实身份服务时，向 `SessionManager` 注入相应平台的凭证存储实现。

产品的 Repository 可以从 `starter_network` 导入 `ApiClient`。例如用 `https://example.com/api/` 作为 `baseUrl`，用 `client.get('articles')` 获取 JSON，再由产品代码转换为 `Article`。在创建客户端的对象释放时调用 `client.close()`。如需真实联网，按目标平台配置权限，Web 接口还需要允许相应来源的跨源请求。[Flutter 网络请求文档](https://docs.flutter.dev/cookbook/networking/fetch-data)

SSE 用 `client.openSse('events', lastEventId: lastSeenId)` 订阅。返回 `SseEvent` 和 `SseRetry`，调用方保存最近事件 ID、决定何时重连，并负责把事件数据映射成业务模型。取消订阅会中止客户端请求。服务端任务的停止应由业务接口处理。可用 `SseMethod.post` 加 JSON `body` 建立需要请求参数的流。

可通过 `onDiagnostic` 接收请求编号、方法、协议、状态码、耗时和错误分类。诊断事件省略 URL、请求头、响应内容和原始异常。在 `packages/starter_network` 目录执行 `dart pub get` 和 `dart test` 可运行网络包测试。

`starter_storage` 提供异步 `StringStore`、平台适配 `PreferencesStringStore` 和测试用 `MemoryStringStore`。键名、格式版本和恢复规则由各业务模块维护。此类平台偏好适合可恢复的轻量数据。令牌和真实订单应由专门的凭证存储或后端管理。[shared_preferences 文档](https://pub.dev/packages/shared_preferences)

`starter_sync` 提供不绑定数据库的同步协调：先读取 Feature 自己的本地快照，再单飞刷新远端；支持游标分页、Feature 自定义合并规则、离线回退和本地修改队列。刷新失败时有快照则返回可用的过期数据，并保留错误用于诊断。课程模板已接入 DTO → Entity → Mapper → Domain、版本化课程目录快照和离线回退。大量查询、分页和复杂迁移出现后，再为具体产品选择 Drift 等数据库。

`starter_database` 是 Drift 基座，只维护同步元数据、快照存储和数据库生命周期；课程模板已声明并可通过 `TemplateHome(database: ...)` 注入它，默认仍使用 `StringStore`，因此不会在启动时强制打开 SQLite。产品自己的表、Entity 和迁移应放在产品或 Feature 数据库中。

`starter_realtime` 是可选实时基座，负责事件信封、连接状态、Reducer、事件 ID 去重、序列重排、事件日志持久化/回放、最后事件恢复和有界重连。`RealtimeSession` 将业务状态与连接生命周期分离。SSE/WebSocket 的具体 Transport 由产品注入，业务事件解释和状态模型仍归 Feature 所有。

使用存储基座的 `shop`、`character` 和 `course` 模板需要 Flutter 3.41 或更新版本。调试 Web 恢复行为时，使用固定的 `--web-port`，让重启前后访问同一来源。

## 工程标准与演进路线

目标是从同一仓库生成独立产品。一次模板发布使用同一版公共包，产品在自己的 `lib/features/` 开发业务并主动选择基座升级。以下标准适用于新代码与新模板，现有模板按后面的实施顺序对齐。

### 参考项目与采用决策

参考以下固定提交。两个项目的源码用于研究，引用或引入其源码、资源前按对应许可证单独审查。

| 参考 | 从源码看到的做法 | 在 Flutter Starter 中的决策 |
|---|---|---|
| Flutter Compass 的应用组装 | 开发入口组装本地 Repository，Staging 入口组装远端 Repository，两个入口复用同一个应用。测试可替换数据源。 [环境入口与依赖组装](https://github.com/flutter/samples/tree/a5bccd247163b1017d2eb9320cf3b94a95ccfb5e/compass_app/app/lib) | 保留一个标准 `main.dart`。在 `lib/app/` 使用 `starter_config` 选择示例或远端实现，并从构造函数注入。页面与校验逻辑可以在测试中替换依赖。 |
| Flutter Compass 的预订流程 | `HomeViewModel` 负责加载和删除反馈。`Command` 管理执行、结果和重复触发；远端 Repository 负责 API 模型转换，跨多个 Repository 的创建规则由 Use Case 处理。 [预订范例](https://github.com/flutter/samples/blob/a5bccd247163b1017d2eb9320cf3b94a95ccfb5e/compass_app/app/lib/ui/home/view_models/home_viewmodel.dart) · [创建用例](https://github.com/flutter/samples/blob/a5bccd247163b1017d2eb9320cf3b94a95ccfb5e/compass_app/app/lib/domain/use_cases/booking/booking_create_use_case.dart) | 采用单向数据流和明确的异步状态。域模型与契约归各自 Feature。简单页面保留局部状态；需要共享、重试协调或生命周期管理时才提取 ViewModel。 |
| Very Good CLI 的生成流程 | 子命令接收参数，模板声明生成资源及生成后动作，生成器工厂可注入测试。Flutter 模板在生成后单独解析依赖。 [生成子命令](https://github.com/VeryGoodOpenSource/very_good_cli/blob/7a9beda63cef8d393b0e464bfba95a2b04756cb7/lib/src/commands/create/commands/create_subcommand.dart) · [Flutter 模板处理](https://github.com/VeryGoodOpenSource/very_good_cli/blob/7a9beda63cef8d393b0e464bfba95a2b04756cb7/lib/src/commands/create/templates/very_good_core/very_good_core_template.dart) | 保留官方 `flutter create` 和当前覆盖机制。把模板注册、参数校验、生成步骤和进程执行拆成可独立测试的职责。需要复杂变量、资源分发或 Feature 生成时再评估 Mason。 |
| Very Good CLI 的产物测试 | E2E 先在临时目录生成真实 app，再在输出目录运行检查，并报告子进程结果。 [Flutter 应用 E2E](https://github.com/VeryGoodOpenSource/very_good_cli/blob/7a9beda63cef8d393b0e464bfba95a2b04756cb7/e2e/test/commands/create/flutter_app/core_test.dart) | 把独立生成和构建作为发布门禁。优先覆盖生成失败、依赖裁剪与各产品关键流程；覆盖率用于发现缺口。 |

### 应用架构规范

生成项目维持 Flutter 标准根目录。`lib/app/` 负责应用组装、主题、环境和全局路由，`lib/shared/` 放无业务依赖的 UI，`lib/features/<feature>/` 管理该业务的页面、领域模型和数据适配。公共包通过 `package:starter_…/starter_….dart` 公开稳定入口，`lib/src/` 由包内部使用。

| 职责 | 标准 |
|---|---|
| 页面与状态 | 页面消费展示状态、转发操作。单页简单查询可用 `FutureBuilder` 并持有同一个 Future；筛选、续学、提交或跨页面共享等复杂状态由 ViewModel 或明确的状态所有者管理。异步页面分别处理加载、空、成功和失败，写操作明确处理重复提交、退出后的回调及重试。 |
| 领域与应用用例 | `domain/` 放业务模型、规则与 Repository 契约，依赖纯 Dart 和领域允许的公共契约。写一个业务名能解释的 Use Case 来协调多个 Repository 或封装可复用的复杂规则。页面目录可沿用 `pages/`，出现 ViewModel 时放入本 Feature 的 `presentation/`。 |
| Repository 与数据适配 | Repository 接口面向业务语义。HTTP、SSE、平台存储以及 JSON 校验留在数据层。DTO 映射为领域模型后交给上层，失败由展示层映射成用户可用的提示。持久化键名和版本归 Feature。 |
| 组装与资源所有权 | 在 `lib/app/` 决定示例、远端、测试替身的绑定，并释放自己创建的客户端与订阅。局部状态用 Flutter 自带机制；需要跨页面依赖与状态协调时按 ADR-008 采用 Riverpod，统一在组装边界注入。 |
| 模块独立 | Feature 依赖公共基座和自身契约，跨 Feature 协作由应用层编排，公开传递业务 ID 或事件。凭证的生命周期归会话服务；普通偏好只存可恢复的非敏感数据。 |

`course` 可作为第一条纵向参考。课程组装入口选择示例或远端 Repository；远端实现把 JSON 转成 `Course` 和 `Lesson`；课程进度保存课时 ID，恢复时匹配最新课时目录。目录加载和课程详情的续学状态由本 Feature 的 ViewModel 管理：页面只渲染状态并转发操作，保存采用单飞请求、乐观更新和失败重试，且异步回调不会触碰已销毁页面。商城的价格与购物车规则、角色扮演的场景规则同样留在各自 Feature。

### 模板与生成器契约

基础模板提供共用入口、主题、状态组件及默认首页。所选业务模板提供自己的首页组装、Feature 文件和主流程测试。生成项目使用自身 `packages/` 的相对路径，独立解析依赖并提交自己的锁文件。母仓库下的 `open/` 仅供参考，生成器和产物的依赖来源是模板、公共包及声明的外部依赖。

当前模板、依赖与最小验收如下。所有列出的模板都带 `starter_network`；下表列出额外基座。

| 模板 | 额外基座 | 最小业务流程 |
|---|---|---|
| `base` | `starter_auth` | 首屏启动，内存会话登录、恢复与退出 |
| `content` | `starter_config` | 示例目录、详情、远端错误后重试 |
| `shop` | `starter_storage` | 商品详情、加购、购物车恢复、演示下单 |
| `character` | `starter_storage`、`starter_database` | 角色选择、剧情分支、进度恢复、可选 Drift 存储 |
| `course` | `starter_config`、`starter_storage`、`starter_sync` | 选课、完成课时、缓存目录、离线回退、远端错误后重试 |

当前 CLI 支持临时目录生成和 `--verify`。[类型化模板注册表](tooling/flutter_starter/lib/src/template_registry.dart)是 `list` 和 `create` 的共同来源，记录模板、所需包、SDK 下限、可生成平台和覆盖规则。业务模板可替换约定的 `lib/app/template_home.dart` 与入口测试。生成器通过 YAML 编辑合并 `pubspec.yaml` 依赖并保留 Flutter 工程的 SDK 声明。SDK 下限仍由生成项目的依赖解析执行，注册表用于失败提示。

生成顺序固定为**输入与资源校验 → 临时目录调用 `flutter create` → 叠加模板与复制依赖 → `flutter pub get` → 按需验证 → 同卷移动到目标路径**。输入错误给出失败原因和可用选项。子进程失败报告阶段、命令、退出状态和相关输出；验证失败时清理生成器创建的暂存内容。生成的环境值从编译配置和应用接口读取，模板参数只接收可以公开的设置。

### 验证标准与实施顺序

| 验证层 | 合并或发布前应验证 |
|---|---|
| 公共包和业务单测 | 校验输入、数据映射、失效存档、状态转移和关键规则。通过内存实现、固定响应及可控时钟覆盖正常与失败分支。 |
| 页面测试 | 关键用户流程可用，至少覆盖主要成功路径和真实失败恢复动作。样例流程在无产品后端时能运行。 |
| CLI 测试 | 参数解析、模板选择、目标冲突、生成失败清理与文件覆盖规则可独立验证。通过可注入进程执行器模拟 Flutter 命令及失败。 |
| 生成项目 E2E | 对五个模板逐一生成，确认模板变量已替换、产物只包含相应业务和声明的公共包。将产物复制到无法访问母仓库的路径，重新执行 `flutter pub get`，再跑格式检查、`flutter analyze`、`flutter test` 和 `flutter build web`。Android 与 iOS 的支持状态随各自构建记录更新。 |

当前 `--verify` 执行静态分析和测试。格式与目标平台构建是独立验收步骤。核心公开接口写英文 DartDoc，关键规则、生命周期和失败恢复用英文行内注释说明原因。对外接口变更同时更新调用方、测试和模板使用说明。

在母仓库根目录运行全量 Web 验收：

```powershell
dart run tooling/flutter_starter/tool/template_smoke.dart
```

[验收脚本](tooling/flutter_starter/tool/template_smoke.dart)会记录 Flutter 版本和每个模板的结果。它把生成项目复制到新的临时路径，重新解析依赖并检查模板隔离、格式、分析、测试和 Web 产物。失败时输出阶段与命令，并保留临时目录供排查。

[GitHub Actions 工作流](.github/workflows/template-smoke.yml)固定 Flutter 3.50.1，由第一项任务生成项目并上传验证包，第二项任务只下载该验证包，在未检出母仓库的 runner 上重新解析、测试和构建。

在 `tooling/flutter_starter/` 下运行 `dart pub get` 和 `dart test`，可用 Fake Flutter 进程执行器单独测试参数、文件覆盖、目标冲突和失败后清理。CI 在生成模板前运行这些单测。五模板冒烟保留独立的预期依赖清单。

按以下顺序落地：

1. **固定生成回归。** 五模板 Web 验收使用上面的脚本与 CI 工作流。日常修改模板或公共包时先跑这组门禁。
2. **收敛生成器。** 模板注册表、参数校验、项目生成和进程执行已经拆分，现有 `flutter-starter create` 命令和参数继续适用。CLI 单测与五模板冒烟共同验证生成行为。
3. **用业务变化验证分层。** `course` 已用目录 ViewModel、详情 ViewModel 和可替换存储验证状态所有权、重复提交防护、失败重试与销毁后的异步安全。已有 `shop`、`character` 和 `content` 随实际业务改动逐步对齐。
4. **按产品需求扩展平台能力。** 有分享链接时增加基于业务 ID 的深链；选定身份服务后补真实认证、平台凭证和会话守卫；稳定后再考虑更复杂的生成工具和发布模式。

长期设计见 [Flutter Starter 架构文档](docs/Flutter_Starter_Architecture.md)。
