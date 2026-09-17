---
aliases:
  - Autonomous Agent Workflow
tags:
  - workflow
  - guide
---

# 🤖 Workflow 4: การสั่งการ Agent อัตโนมัติและการสร้างทักษะ (Automation & Meta)

คู่มือสำหรับสั่งการ AI Agent ให้ทำงานระยะยาวแบบอัตโนมัติ และการสร้างเครื่องมือ/ทักษะใหม่ให้กับ AI

---

## 🗺️ แผนผังลำดับขั้นตอน

```text
[1. กำหนดเป้าหมายหรือลูป] ➔ [2. ตรวจสอบสถานะและกู้คืนตนเอง] ➔ [3. สกัดบทเรียนเป็น Skill ใหม่]
```

---

### ขั้นที่ 1: สั่งการทำงานอัตโนมัติ (Autonomous Execution)
- **ทักษะที่ใช้:**
  - [[Skills/goal/SKILL|goal]] — เมื่อต้องการสั่งงานข้ามคืนหรือต้องการให้ Agent มุ่งมั่นแก้ปัญหาจนกว่าจะสำเร็จ 100%
  - [[Skills/loop/SKILL|loop]] — เมื่อต้องการสั่งให้เช็คสถานะหรือรันคำสั่งซ้ำตามรอบเวลา
  - [[Skills/automate/SKILL|automate]] — สร้าง Trigger และ Automation flows

### ขั้นที่ 2: การตรวจสอบและกู้คืนตัว Agent (Self-Healing)
- **ทักษะที่ใช้:** [[Skills/agent-introspection-debugging/SKILL|agent-introspection-debugging]]
- **เมื่อใดที่ต้องใช้:**
  - เมื่อ Agent เรียกเครื่องมือเดิมซ้ำๆ เกินขีดจำกัด
  - เมื่อพบว่า Context Window มีขนาดใหญ่เกินไปและเริ่มออกนอกประเด็น (Drift)
  - สรุป Report ปัญหาและปรับกลยุทธ์ก่อนทำงานต่อ

### ขั้นที่ 3: สกัดเป็นทักษะใหม่เก็บไว้ใน Obsidian (Continuous Learning)
- **ทักษะที่ใช้:**
  - [[Skills/create-skill/SKILL|create-skill]] — สกัดกระบวนการที่ทำสำเร็จเป็น Skill ถาวร
  - [[Skills/create-rule/SKILL|create-rule]] — เพิ่มกฎบังคับเฉพาะโปรเจกต์
  - [[Templates/Skill Template|Skill Template]] — บันทึกลง Obsidian Vault พร้อมเชื่อมโยง `[[Wikilinks]]`
