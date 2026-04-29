-- ============================================================
-- 保健箱管理系統 - Supabase Schema
-- 請在 Supabase Dashboard > SQL Editor 執行此檔案
-- ============================================================

-- 1. 保健箱地點/管理單位
CREATE TABLE IF NOT EXISTS boxes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,           -- 保健箱名稱/地點
  location text,                -- 詳細位置說明
  manager_name text,            -- 管理人姓名
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- 2. 保健箱物品主檔（可動態新增品項）
CREATE TABLE IF NOT EXISTS items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  box_id uuid REFERENCES boxes(id) ON DELETE CASCADE,
  item_no integer NOT NULL,     -- 項次
  name text NOT NULL,           -- 名稱
  base_quantity text NOT NULL,  -- 基本數量描述
  expiry_date date,             -- 有效期限
  expiry_notes text,            -- 有效期限備註
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- 3. 每月檢查記錄主表
CREATE TABLE IF NOT EXISTS inspections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  box_id uuid REFERENCES boxes(id) ON DELETE CASCADE,
  inspection_date date NOT NULL,          -- 檢查日期
  inspector_name text,                     -- 檢查人姓名（補充用）
  signature_data text,                     -- 電子簽名 base64
  notes text,                              -- 備註
  submitted_at timestamptz DEFAULT now(),  -- 填寫時間戳記（需求5）
  client_ip text,                          -- 來源 IP（可選）
  user_agent text                          -- 裝置資訊（可選）
);

-- 4. 每月檢查明細（每個品項的結果）
CREATE TABLE IF NOT EXISTS inspection_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid REFERENCES inspections(id) ON DELETE CASCADE,
  item_id uuid REFERENCES items(id),
  item_name text NOT NULL,       -- 冗餘儲存，防止品項被刪除後遺失記錄
  result text NOT NULL,          -- 'normal'=正常(V) / 'abnormal'=異常(X)
  actual_quantity text,          -- 實際數量（異常時填寫）
  updated_item text,             -- 更新品項名稱（異常時填寫）
  new_expiry_date date,          -- 更新後有效期限
  abnormal_notes text            -- 異常備註
);

-- 5. 管理者帳號
CREATE TABLE IF NOT EXISTS admins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text UNIQUE NOT NULL,
  password_hash text NOT NULL,   -- bcrypt hash
  display_name text,
  is_active boolean DEFAULT true,
  last_login timestamptz,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- Row Level Security (RLS) 設定
-- ============================================================

-- 開啟 RLS
ALTER TABLE boxes ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- 公開填寫表單：任何人可讀取 boxes 和 items（不需登入）
CREATE POLICY "Public read boxes" ON boxes FOR SELECT USING (is_active = true);
CREATE POLICY "Public read items" ON items FOR SELECT USING (is_active = true);

-- 公開填寫表單：任何人可新增檢查記錄
CREATE POLICY "Public insert inspections" ON inspections FOR INSERT WITH CHECK (true);
CREATE POLICY "Public insert inspection_items" ON inspection_items FOR INSERT WITH CHECK (true);

-- 管理者：完整存取（使用 service_role key，在後台頁面使用）
CREATE POLICY "Admin full access boxes" ON boxes FOR ALL USING (true);
CREATE POLICY "Admin full access items" ON items FOR ALL USING (true);
CREATE POLICY "Admin full access inspections" ON inspections FOR ALL USING (true);
CREATE POLICY "Admin full access inspection_items" ON inspection_items FOR ALL USING (true);
CREATE POLICY "Admin full access admins" ON admins FOR ALL USING (true);

-- ============================================================
-- 初始資料：預設保健箱（依 PDF 內容）
-- ============================================================

INSERT INTO boxes (name, location, manager_name) VALUES
  ('保健箱 A', '請填寫地點', '管理人A'),
  ('保健箱 B', '請填寫地點', '管理人B'),
  ('保健箱 C', '請填寫地點', '管理人C');

-- 取得第一個 box 的 id 並建立預設品項
DO $$
DECLARE
  box_ids uuid[];
  bid uuid;
BEGIN
  SELECT ARRAY(SELECT id FROM boxes ORDER BY created_at) INTO box_ids;
  FOREACH bid IN ARRAY box_ids LOOP
    INSERT INTO items (box_id, item_no, name, base_quantity, sort_order) VALUES
      (bid, 1, '生理食鹽水(20ML)', '1瓶', 1),
      (bid, 2, '中衛優碘棉片', '1片', 2),
      (bid, 3, '3吋棉棒', '2包', 3),
      (bid, 4, '無菌紗布', '2吋x2吋 2片/包、3吋x3吋 10片/包、4吋x4吋 10片/包 各1包', 4),
      (bid, 5, 'OK繃', '10片', 5),
      (bid, 6, '通氣膠帶', '1捲', 6);
  END LOOP;
END $$;

-- 預設管理員（帳號: admin / 密碼: admin1234）
-- 請上線後立即修改密碼！
-- 密碼 hash 是用 bcrypt(admin1234, 10)
INSERT INTO admins (username, password_hash, display_name) VALUES
  ('admin', '$2a$10$YmhqN5K6O9GkqJZlJxQfOOqEyoXWgJhBzAVKJNXsGqbhgNEE7Kkiq', '系統管理員');
