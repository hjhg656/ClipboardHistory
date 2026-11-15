# 剪贴板历史 ClipboardHistory

iOS 端剪贴板历史 App：App 打开时自动读取剪贴板，文字、图片、链接都存下来，按时间倒序排列，可以搜索、筛选、点一下复制回去，图片还能存到相册。数据只存在本机，不上传。

## 功能

- 打开 App / 回到 App 时自动读一次剪贴板，前台运行时每 1 秒检查一次
- 文字、图片、链接三种类型分别保存、筛选
- 重复内容自动去重（同一条不会存两遍）
- 列表左滑复制回剪贴板，右滑删除；详情页可复制文字、保存图片到相册、在 Safari 打开链接
- 搜索历史记录
- 全部数据存在本机 SwiftData 数据库，不联网

## iOS 限制（先说清楚）

- **后台监听做不到**：iOS 不给后台 App 访问剪贴板。App 退到后台就停了，只有打开着的时候才“实时”保存。这是系统限制，不是代码问题，正规上架 App 都一样。
- **第一次会弹授权**：iOS 16+ 第一次读取剪贴板时，系统会问你要不要允许，点“允许”之后才能正常读。
- 想在复制的瞬间就存下来（不用先打开 App），需要另外加“分享扩展”：在别的 App 里点分享 → 选这个 App 即可保存。那个是下一个版本可以加的东西。

## 怎么跑起来

环境：Mac + Xcode 15 或更新，iOS 17 或更新的真机（剪贴板在模拟器上不好测，建议真机）。

1. 直接双击 `ClipboardHistory.xcodeproj` 打开工程（不用再新建项目、不用再拖文件）
2. 选中项目 → Target → Signing & Capabilities：
   - Team 选你自己的 Apple ID（免费个人账号就行）
   - Bundle Identifier 把默认的 `com.example.ClipboardHistory` 改成你自己的，比如 `com.你的名字.ClipboardHistory`（必须是全网唯一的）
3. 插上 iPhone，顶部设备栏选你的手机，点 Run（▶），第一次弹“允许粘贴”时点允许；去别的 App 复制一段文字、一张图或一个链接，再切回这个 App，就出现在列表里了

## 打包成 IPA

1. 顶部设备栏不要选手机，选 **Any iOS Device (arm64)**
2. 菜单 Product → Archive，等编译完成，自动弹出 Organizer
3. 点 Distribute App → 选 **Development**（装到自己的设备上）→ 一路 Next → Export，得到 `.ipa` 文件
4. 安装这个 IPA：把手机连上 Mac，在 Xcode 的 Window → Devices and Simulators 里把 IPA 拖到手机上；或者用 Apple Configurator、AltStore 安装

注意：
- 免费个人账号签名的 App **7 天过期**，过期后要重新打包安装，里面的历史记录会跟着丢（因为 App 被删了重装）。想长期用、不过期，需要付费的 Apple Developer 账号（99 美元/年）。
- IPA 只能装在你自己的设备上，不能直接发给别人装（别人的设备要先在你的开发者账号里登记）。

## 没有 Mac 怎么办

没有 Mac 也能拿到 IPA：用 GitHub 免费的 macOS 云机器编译，再用 AltStore 免费签名装到手机上。需要一台 Windows 电脑做一次首次安装（之后续签可以只用 WiFi）。

**第一步：让 GitHub 帮你编译（免费）**

1. 注册一个 GitHub 账号（github.com），新建一个仓库（建议选 Public 公开，免费额度最宽松）
2. 把这个压缩包解压，把里面的所有文件（包括 `.github` 这个隐藏文件夹）都传到仓库里
   - 网页上传：仓库页面点 Add file → Upload files，把解压出来的文件全选拖进去
3. 打开仓库顶部的 **Actions** 标签页 → 左边选 **Build IPA** → 点 **Run workflow** → 再点一次 Run workflow
4. 等几分钟，状态变绿之后，点进去页面最下面 **Artifacts** 里的 `ClipboardHistory-unsigned-ipa` 下载，解压得到 `ClipboardHistory-unsigned.ipa`
   - 注意：这个 IPA 是**未签名**的，不能直接装，必须走下一步

**第二步：用 AltStore 签名安装（免费）**

1. Windows 电脑上装 [AltServer](https://altstore.io/)（官网免费下载），手机用数据线连电脑
2. 手机上先装好 AltStore（AltServer 右下角图标 → Install AltStore → 选你的手机，按提示输 Apple ID 和密码——这是你自己的 Apple ID，只发给苹果做签名，不会上传到别处）
3. 手机上打开 AltStore → My Apps → 点 + → 选刚才那个 `.ipa` 文件，AltStore 会用你的 Apple ID 免费签名并安装
4. 装好后打开 App，第一次弹“允许粘贴”时点允许，就能用了

**续签：** 免费签名 7 天过期。手机和电脑连同一个 WiFi、电脑上 AltServer 开着时，AltStore 会自动在后台续签，不用重新安装。过期前记得让手机和电脑在同一 WiFi 下待一会儿。

如果连 Windows 电脑也没有，那真机上就装不了未上架的 App，只能等有电脑的时候再弄，或者去 App Store 找现成的剪贴板 App。

## 文件说明

```
ClipboardHistory/
├── ClipboardHistoryApp.swift        App 入口，建 SwiftData 数据库，启动监听
├── Models/
│   └── ClipboardItem.swift         一条记录的数据模型（文字/图片/链接）
├── Services/
│   └── PasteboardMonitor.swift     剪贴板监听：前台轮询 + 回到前台读取 + 去重保存
└── Views/
    ├── ContentView.swift           主界面：列表、搜索、筛选、左滑复制、右滑删除
    └── ItemDetailView.swift        详情页：复制文字、保存图片、打开链接
```

## 下一步可以加的

- 分享扩展（Share Extension）：不用打开 App 也能保存
- iCloud 同步：多台设备共享同一份历史
- 按 App 来源分类、导出为文本/CSV
