---
aliases:
  - Production Release Workflow
tags:
  - workflow
  - guide
---

# 🛡️ Workflow 3: การเตรียมและปล่อยระบบขึ้น Production (Release Workflow)

ขั้นตอนการเตรียมปล่อยระบบขึ้นสู่ Production ให้ปลอดภัย ราบรื่น และไม่มี Downtime

---

## 🗺️ แผนผังลำดับขั้นตอน

```text
[1. Database Migration Safety] ➔ [2. Security & Penetration Check] ➔ [3. CI Verification & Merge] ➔ [4. Production Deploy] ➔ [5. Editorial Delivery]
```

---

### ขั้นที่ 1: ตรวจสอบความปลอดภัยของฐานข้อมูล (Database Safety)
- **ทักษะที่ใช้:** [[Skills/database-migrations/SKILL|database-migrations]]
- **Checklist สำคัญ:**
  - มีสคริปต์ทั้ง Up และ Down (Rollback plan)
  - ไม่ทำ Table Lock กับตารางขนาดใหญ่ (ใช้ Concurrent Indexing)
  - แยก DDL (โครงสร้าง) ออกจาก DML (ข้อมูล) เสมอ

### ขั้นที่ 2: ตรวจสอบความปลอดภัยขั้นสุดท้าย (Final Security Gate)
- **ทักษะที่ใช้:** [[Skills/review-security/SKILL|review-security]]
- **สิ่งที่ต้องทำ:**
  - ตรวจสอบ Environment Variables และ Secret Injection
  - ตรวจสอบสิทธิ์การเข้าถึง (Authentication & Authorization)
  - ป้องกัน Cross-Origin และ Injections

### ขั้นที่ 3: ตรวจ CI และเตรียมรวม Branch (CI & PR Gate)
- **ทักษะที่ใช้:**
  - [[Skills/git-workflow/SKILL|git-workflow]] — ตรวจสอบ Version Tag (Semantic Versioning)
  - [[Skills/autopilot/SKILL|autopilot]] — ตรวจสอบสถานะการ Build และ CI ทั้งหมดให้ผ่านสมบูรณ์

### ขั้นที่ 4: การ Deploy สู่ Cloud (Cloud Deployment)
- **ทักษะที่ใช้:** [[Skills/deploy-with-vercel/SKILL|deploy-with-vercel]]
- **สิ่งที่ต้องทำ:**
  - ตรวจสอบ Health Check Endpoints หลัง Deploy
  - มอนิเตอร์ Log ตรวจสอบความผิดปกติ

### ขั้นที่ 5: จัดทำรายงานและสรุปผลงานระดับสิ่งพิมพ์ (Editorial Documentation & Delivery)
- **ทักษะที่ใช้:**
  - [[Skills/document-design/SKILL|document-design]] — ออกแบบรายงานส่งมอบงานด้วยมาตรฐานสิ่งพิมพ์ 60-30-10, ตาราง Tufte และ Web-to-PDF
  - [[Skills/docx/SKILL|docx]] หรือ [[Skills/pdf/SKILL|pdf]] — สร้างและส่งมอบเอกสารทางการ
- **สิ่งที่ต้องทำ:**
  - สรุป Release Notes หรือ Executive Summary ในรูปแบบเอกสารทางการ
  - แปลงรายงานเป็น PDF คุณภาพสูงระดับนิตยสารผ่าน Playwright
