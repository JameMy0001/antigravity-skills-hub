---
aliases:
  - New Feature Workflow
tags:
  - workflow
  - guide
---

# 🚀 Workflow 1: การพัฒนาฟีเจอร์ใหม่ (New Feature Development)

คู่มือนี้กำหนดลำดับขั้นตอนมาตรฐานที่ AI Assistant และ Developer ต้องปฏิบัติตามเมื่อสร้างฟีเจอร์ใหม่ในโปรเจกต์ เพื่อให้ได้โค้ดที่สะอาด มีเทสต์รับประกัน และไม่มีบัก

---

## 🗺️ แผนผังลำดับขั้นตอน (Step-by-Step Sequence)

```text
[Step 1: สำรวจโปรเจกต์] ➔ [Step 2: ออกแบบสถาปัตยกรรม & API] ➔ [Step 3: ออกแบบ Web & UI]
                                       │
[Step 6: ปล่อยระบบ] 🠤 [Step 5: ตรวจสอบความปลอดภัย] 🠤 [Step 4: พัฒนาด้วย TDD]
```

---

### ขั้นที่ 1: สำรวจและเข้าใจบริบทของโปรเจกต์ (Recon & Discovery)
- **ทักษะที่ใช้:** [[Skills/codebase-onboarding/SKILL|codebase-onboarding]]
- **สิ่งที่ต้องทำ:**
  1. สแกนโครงสร้างโปรเจกต์ ตรวจจับ Manifest (`package.json`, `go.mod`, `pyproject.toml`)
  2. ระบุจุดเริ่มต้นการทำงาน (Entry Points) และ Conventions ของทีม
  3. สรุปความต้องการและ Scope ของฟีเจอร์ใหม่

### ขั้นที่ 2: ออกแบบสถาปัตยกรรม, API และฐานข้อมูล (Architecture & Contracts)
- **ทักษะที่ใช้:**
  - [[Skills/backend-patterns/SKILL|backend-patterns]] — วางโครงสร้าง Controller, Service, Repository
  - [[Skills/api-design/SKILL|api-design]] — กำหนด Endpoints, HTTP Status, และ DTO Response
  - [[Skills/database-migrations/SKILL|database-migrations]] — วางแผน Schema และ Indexing ป้องกัน Table Lock
- **สิ่งที่ต้องทำ:**
  1. ทำ Implementation Plan อธิบายสถาปัตยกรรมก่อนแตะต้องโค้ด
  2. เขียนแบบ Schema ฐานข้อมูลและ API Specifications

### ขั้นที่ 3: พัฒนาและเชื่อมต่อ Frontend (Web & UI Standards)
- **ทักษะที่ใช้:**
  - [[Skills/modern-web-guidance/SKILL|modern-web-guidance]] — ตรวจสอบ Web APIs ล่าสุดและ Core Web Vitals
  - [[Skills/claude-design/SKILL|claude-design]] — ออกแบบ UI/UX Craft ระดับโลก, Dual-Mode Delivery (HTML/React), Atomic Button Craft และ 10-Point Slop Diagnostics
  - [[Skills/canvas/SKILL|canvas]] หรือ [[Skills/visualize/SKILL|visualize]] — พรีวิว UI หรือผังข้อมูล
- **สิ่งที่ต้องทำ:**
  1. ดึงคู่มือมาตรฐานเว็บล่าสุดผ่าน `npx modern-web-guidance`
  2. ออกแบบ UI/UX Craft ด้วย claude-design ยึดหลัก Surface-First 7 Archetypes และปุ่ม Atomic 4 Layers
  3. เลี่ยงการใช้ Library หนักเกินจำเป็น โดยใช้ Native HTML5/CSS3 APIs

### ขั้นที่ 4: พัฒนา Logic ด้วย Test-Driven Development (TDD)
- **ทักษะที่ใช้:**
  - [[Skills/tdd-workflow/SKILL|tdd-workflow]] — วงจร Red-Green-Refactor
  - [[Skills/error-handling/SKILL|error-handling]] — สร้าง Typed Exceptions และ Circuit Breakers
- **สิ่งที่ต้องทำ:**
  1. **RED:** เขียน Unit / Integration Test ให้ Fail เพื่อพิสูจน์เงื่อนไขที่ต้องการ
  2. **GREEN:** เขียนโค้ดให้สั้นและกระชับที่สุดเพื่อให้ Test ผ่าน
  3. **REFACTOR:** ปรับปรุงโค้ดให้สะอาดโดยที่ Test ยังคงผ่าน 100%

### ขั้นที่ 5: ตรวจทานคุณภาพและความปลอดภัย (Review & Security)
- **ทักษะที่ใช้:**
  - [[Skills/review/SKILL|review]] และ [[Skills/review-bugbot/SKILL|review-bugbot]] — ตรวจหา Code Smells
  - [[Skills/review-security/SKILL|review-security]] — สแกนหาช่องโหว่ OWASP Top 10
- **สิ่งที่ต้องทำ:**
  1. ตรวจสอบความปลอดภัยของ Input และ Sanitization
  2. ยืนยันว่าไม่มี Secret หรือ API Key หลุดลงในโค้ด

### ขั้นที่ 6: Commit และ Deploy (Git & Release)
- **ทักษะที่ใช้:**
  - [[Skills/git-workflow/SKILL|git-workflow]] — เขียน Conventional Commits (`feat: ...`)
  - [[Skills/split-to-prs/SKILL|split-to-prs]] — แตก Branch และเปิด PR ขนาดกะทัดรัด
  - [[Skills/autopilot/SKILL|autopilot]] ➔ [[Skills/deploy-with-vercel/SKILL|deploy-with-vercel]]
