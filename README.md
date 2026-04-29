# 保健箱月檢查系統 - 部署說明

## 系統架構

```
├── public/
│   └── index.html        ← 公開填寫表單（無需帳密，任何人可填）
├── admin/
│   └── index.html        ← 後台管理（管理員帳密登入）
├── sql/
│   └── schema.sql        ← 資料庫建置腳本
└── README.md
```

## 部署步驟（建議：Supabase + Vercel，全免費）

---

### 第一步：建立 Supabase 資料庫

1. 前往 https://supabase.com 建立免費帳號
2. 點 **New Project**，填寫專案名稱與密碼
3. 等待專案建立完成（約 1 分鐘）
4. 進入 **SQL Editor**，貼上 `sql/schema.sql` 全部內容，點 **Run**
5. 取得以下兩個值（Settings > API）：
   - `Project URL`：形如 `https://xxxx.supabase.co`
   - `anon key`：公開 key，用於前台
   - `service_role key`：管理 key，只用於後台（勿公開）

---

### 第二步：設定金鑰

編輯以下兩個檔案，找到頂部的設定區塊並填入：

**public/index.html**（前台，只需 anon key）：
```javascript
const SUPABASE_URL = 'https://你的專案ID.supabase.co';
const SUPABASE_ANON_KEY = '你的 anon key';
```

**admin/index.html**（後台，需要 service_role key）：
```javascript
const SUPABASE_URL = 'https://你的專案ID.supabase.co';
const SUPABASE_ANON_KEY = '你的 anon key';
const SUPABASE_SERVICE_KEY = '你的 service_role key';
```

> ⚠️ 注意：service_role key 擁有完整資料庫權限，**絕對不要**放在公開前台頁面。
> 後台 admin/ 資料夾建議設定存取限制（如 Vercel 的 Password Protection 功能）。

---

### 第三步：部署到 Vercel（免費）

1. 前往 https://vercel.com 建立免費帳號
2. 安裝 Vercel CLI：`npm i -g vercel`
3. 在 healthbox/ 目錄執行：
   ```bash
   vercel
   ```
4. 依提示設定：
   - Framework: **Other**
   - Root directory: `./`（預設）
5. 部署完成後取得兩個網址：
   - `https://你的專案.vercel.app/` → 前台填寫表單
   - `https://你的專案.vercel.app/admin/` → 後台管理

**或直接拖曳上傳（不需 CLI）：**
前往 https://vercel.com/new → Import → 上傳 zip 檔案

---

### 第四步：設定 Supabase CORS

在 Supabase > Settings > API > CORS Allowed Origins 加入：
```
https://你的專案.vercel.app
```

---

## 預設管理員帳號

| 帳號 | 密碼 |
|------|------|
| admin | admin1234 |

> ⚠️ 請在第一次登入後立即至「管理員帳號」頁面建立新帳號，並停用預設帳號！

---

## 功能說明

### 前台（public/index.html）
- 任何人可以直接填寫，**不需要帳號**
- 選擇保健箱地點、填寫日期（預設今天）
- 每個品項選擇「✔ 正常」或「✘ 異常」
- 異常時展開填寫：實際數量、更換品項、新有效期限、說明
- 電子簽名（手寫或觸控）
- 填寫時間自動記錄（需求 5）
- 送出後資料儲存至 Supabase

### 後台（admin/index.html）
- 管理員帳密登入（bcrypt 加密）
- **儀表板**：本月統計、異常品項數、最近記錄
- **檢查記錄**：依保健箱/月份篩選、查看簽名、匯出 CSV
- **保健箱管理**：新增/停用保健箱
- **品項管理**：各保健箱品項清單、設定有效期限（快到期自動紅色警示）
- **管理員帳號**：建立帳號（bcrypt 加密）、停用帳號
- **批次匯入**：上傳 CSV 匯入歷史記錄

---

## CSV 批次匯入格式

用於匯入掃描 PDF 轉換的歷史資料：

```csv
box_name,inspection_date,inspector_name,item_no,item_name,result,actual_quantity,updated_item,new_expiry_date,abnormal_notes
保健箱A,2025-01-25,郭永利,1,生理食鹽水(20ML),normal,,,,
保健箱A,2025-01-25,郭永利,5,OK繃,abnormal,7片,OK繃,,數量不足
```

- `result`：`normal`（正常）或 `abnormal`（異常）
- 同一個保健箱+同一日期的記錄視為同一次檢查
- 後台可下載範本 CSV

---

## 常見問題

**Q：填寫人不需要帳號，那要怎麼知道是誰填的？**
A：透過電子簽名識別。簽名圖片儲存在資料庫，後台可查看每筆記錄的簽名。

**Q：品項有效期限快到了，系統會提醒嗎？**
A：後台「品項管理」頁面，距有效期限 30 天內的品項會標紅色警示。未來可擴充 Email 通知功能。

**Q：支援手機填寫嗎？**
A：支援。電子簽名使用觸控事件，在手機上可用手指或觸控筆簽名。

**Q：資料如何備份？**
A：Supabase 免費方案每日自動備份 7 天。可定期從後台匯出 CSV 自行保存。

---

## 技術規格

- **前端**：純 HTML + CSS + JavaScript（無框架依賴）
- **資料庫**：Supabase（PostgreSQL）
- **認證**：bcryptjs 密碼雜湊
- **電子簽名**：HTML Canvas API
- **部署**：Vercel（靜態網站托管）
- **費用**：Supabase 免費方案 + Vercel 免費方案 = 每月 $0
