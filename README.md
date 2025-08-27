# Better Notch

🚀 一款 macOS 菜單列工具，靈感來自 [NotchDrop](https://github.com/Lakr233/NotchDrop)，
並在此基礎上新增了分頁切換與更多功能。

## ✨ 功能特色
- 🔹 **分頁切換**：支援左右滑動切換不同工具頁面（AirDrop、Media、Calendar ...）。
- 🔹 **自訂點點指示器**：顯示當前分頁，固定在標題右側。
- 🔹 **模組化架構**：新增功能時只需建立新的分頁 View 並註冊即可。
- 🔹 **拖放開啟**：拖曳檔案到劉海區域可自動打開工具面板。

## 🛠️ 開發進度
- [x] 重構分頁架構
- [x] 分頁指示點與標題整合
- [ ] Media 工具功能
- [ ] Calendar 工具功能
- [ ] 其他更多自訂工具

## 📦 安裝方式
專案仍在開發中，目前僅支援從 Xcode Build。
未來會提供 release dmg。

```bash
git clone https://github.com/你的帳號/BetterNotch.git
cd BetterNotch
open NotchDrop.xcodeproj
🧑‍💻 貢獻
歡迎 fork 與發 PR！
如果有新點子，可以直接開 issue 討論。
📄 授權
本專案基於 MIT License。
原始專案版權：© 2024 Lakr Aream
修改版權：© 2025 SAI T


## 🔀 Branching Workflow

本專案採用簡化的 Git Flow，確保 **main 永遠穩定**，功能開發則在獨立分支進行。

             +-------------------+
             |       main        |   ← 永遠保持穩定，可編譯可演示
             +-------------------+
                      ▲
                      |  PR (合併穩定版本)
                      |
             +-------------------+
             |       dev         |   ← 開發整合，功能測試場
             +-------------------+
               ▲       ▲
               |       |
PR (小功能)    |       |   PR (小功能)
               |       |
   +----------------+  +----------------+
   | feature/media  |  | feature/paging |
   +----------------+  +----------------+

### 🔹 分支角色
- **main**  
  - 穩定分支  
  - 永遠可 demo、可回退  
  - 已設保護規則，不能直接 push，必須透過 PR

- **dev**  
  - 開發整合分支  
  - 功能分支先合併到這裡  
  - 驗證穩定後再合併到 main

- **feature/**  
  - 單一功能分支（例：`feature/media-page`）  
  - 從 dev 切出 → 開發 → 測試 → PR → dev

### 🔹 Commit 規範
- `feat: ...` 新功能  
- `fix: ...` 修 bug  
- `refactor: ...` 重構  
- `docs: ...` 文件（README、LICENSE 等）  
- `chore: ...` 其他雜項  

---
