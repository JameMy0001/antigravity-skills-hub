---
aliases:
  - Bug Fixing Workflow
tags:
  - workflow
  - guide
---

# 🐞 Workflow 2: การแก้ไขบักอย่างเป็นระบบ (Defect Fixing & Debugging)

คู่มือสำหรับแก้ไขปัญหาและบักในโปรเจกต์ โดยมุ่งเน้นที่การค้นหา **สาเหตุที่แท้จริง (Root Cause)** แทนที่จะแก้แบบปะผุที่ปลายเหตุ

---

## 🗺️ แผนผังลำดับขั้นตอน

```text
[1. วิเคราะห์อาการ & Stack Trace] ➔ [2. สร้าง Failing Regression Test] ➔ [3. แก้ไขโค้ดให้ Test เขียว] ➔ [4. ตรวจทาน & ป้องกันเกิดซ้ำ]
```

---

### ขั้นที่ 1: แยกแยะอาการและค้นหาสาเหตุที่แท้จริง (Triage & Isolation)
- **ทักษะที่ใช้:** [[Skills/orch-fix-defect/SKILL|orch-fix-defect]]
- **หลักการสำคัญ:**
  - แยกให้ออกว่า "ระบบทำงานผิดปกติ (Broken)" หรือ "ความต้องการเปลี่ยน (Requirement Change)"
  - ตรวจสอบ Stack Trace และ Input ที่ทำให้เกิด Error
  - หากตัว AI เองติดขัดหรือวนลูป ให้ใช้ [[Skills/agent-introspection-debugging/SKILL|agent-introspection-debugging]] กู้คืนการทำงาน

### ขั้นที่ 2: พิสูจน์บักด้วย Failing Regression Test (RED)
- **ทักษะที่ใช้:** [[Skills/tdd-workflow/SKILL|tdd-workflow]]
- **กฎเหล็ก:** **ห้ามแตะต้องโค้ดของแอปพลิเคชันจนกว่าจะเขียน Test ที่รันแล้วพัง (Fail) ได้สำเร็จ!**
  - การมี Failing Test คือหลักฐานเดียวที่พิสูจน์ว่าบักมีอยู่จริง และเข้าใจอาการถูกต้อง

### ขั้นที่ 3: ลงมือแก้โค้ดเฉพาะจุดที่จำเป็น (GREEN)
- **ทักษะที่ใช้:**
  - [[Skills/orch-fix-defect/SKILL|orch-fix-defect]]
  - [[Skills/error-handling/SKILL|error-handling]] — ปรับปรุงการจัดการ Exception ไม่ให้ Error เงียบ
- **สิ่งที่ต้องทำ:**
  1. แก้ไขโค้ดที่จุดเกิดเหตุจนกระทั่ง Regression Test กลับมาผ่าน (เขียว)
  2. รัน Test Suite ทั้งหมดของโปรเจกต์ เพื่อยืนยันว่าการแก้จุดนี้ไม่ไปทำลายฟังก์ชันเดิม

### ขั้นที่ 4: ตรวจทานและบันทึกประวัติ (Review & Gated Commit)
- **ทักษะที่ใช้:**
  - [[Skills/review/SKILL|review]] — ตรวจทาน Diff
  - [[Skills/git-workflow/SKILL|git-workflow]] — บันทึก Commit เป็น `fix: <คำอธิบายสาเหตุและวิธีแก้>`
