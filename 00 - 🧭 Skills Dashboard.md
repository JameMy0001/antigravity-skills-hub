---
aliases:
  - Skills Dashboard
  - Skills MOC
  - Skills Directory
tags:
  - moc
  - agent-skills
---

# 🧭 Agent Skills System: คู่มือและสารบัญ 8 ขั้นตอน (61 Skills)

ยินดีต้อนรับสู่ระบบจัดเก็บและเรียกใช้งาน **Agent Skills** ที่จัดระเบียบตาม **Software Development Life Cycle (SDLC) 8 ขั้นตอน**
ช่วยให้ AI Assistant ทำงานได้อย่างแม่นยำ เป็นขั้นเป็นตอน ไม่ลัดขั้นตอน และเรียกใช้เครื่องมือที่ถูกต้องเสมอ

---

## ⚡ ทางลัดคู่มือกระบวนการทำงาน (Sequential Workflows)
คลิกเปิดขั้นตอนการทำงานตามเป้าหมายของคุณ:
- 🚀 **ต้องการเริ่มพัฒนาฟีเจอร์ใหม่:** [[Workflows/01 - 🚀 New Feature Workflow|Workflow 1: การพัฒนาฟีเจอร์ใหม่ (Step-by-Step)]]
- 🐞 **ต้องการแก้ปัญหาหรือบักในโค้ด:** [[Workflows/02 - 🐞 Bug Fixing Workflow|Workflow 2: การแก้บักอย่างเป็นระบบ (Root Cause First)]]
- 🛡️ **ต้องการเตรียมปล่อยระบบขึ้น Cloud:** [[Workflows/03 - 🛡️ Production Release Workflow|Workflow 3: การปล่อยระบบขึ้น Production (Safe Release)]]
- 🤖 **ต้องการสั่งบอทรันอัตโนมัติ/สร้าง Skill ใหม่:** [[Workflows/04 - 🤖 Autonomous Agent Workflow|Workflow 4: การรันอัตโนมัติและสร้างทักษะ]]

> [!TIP] การเรียกดูแผนผังความสัมพันธ์
> - 🗺️ **Interactive Canvas:** เปิดไฟล์ [[01 - 🗺️ Skills Workflow.canvas]] เพื่อดูผังการเชื่อมโยงจาก Stage 1 ถึง Stage 8
> - 🕸️ **Graph View:** กด `Cmd + G` เพื่อดูกราฟใยแมงมุมที่ทุก Skill เชื่อมต่อกันแบบ 2 ทาง

---

## 🗂️ สารบัญ Skills แยกตาม 8 ขั้นตอนของวงจรพัฒนา (SDLC)

### ==🚀 Stage 1: พัฒนาฟีเจอร์และตรรกะธุรกิจ (01 - New Features & Business Logic)==
> *ใช้เมื่อเริ่มต้นสร้างฟีเจอร์ใหม่ วางแผนสถาปัตยกรรม ออกแบบ API และเขียนโค้ดด้วย TDD*

| ทักษะ (Skill) | หน้าที่และจังหวะเวลาที่เรียกใช้ |
| :--- | :--- |
| [[Skills/api-design/SKILL|`api-design`]] | มาตรฐานการออกแบบ RESTful API ระดับ Production, Idempotency, Pagination, และ Status Codes |
| [[Skills/architecture-diagram/SKILL|`architecture-diagram`]] | สร้างไดอะแกรมสถาปัตยกรรมระบบและโครงสร้างพื้นฐาน Cloud แบบ Dark SVG ฝังใน HTML |
| [[Skills/backend-patterns/SKILL|`backend-patterns`]] | สถาปัตยกรรม Backend, Controller-Service-Repository pattern, Caching, และลด N+1 Query |
| [[Skills/brainstorming/SKILL|`brainstorming`]] | สำรวจความต้องการของผู้ใช้ อภิปรายข้อดีข้อเสีย และทำ Specification ก่อนลงมือเขียนโค้ด |
| [[Skills/subagent-driven-development/SKILL|`subagent-driven-development`]] | แตกแผนงานใหญ่เป็น Task ย่อยและกระจายงานให้ Subagent อิสระทำทีละส่วนพร้อม Code Review |
| [[Skills/tdd-workflow/SKILL|`tdd-workflow`]] | วงจร Test-Driven Development (Red-Green-Refactor) รับประกัน Test Coverage 80%+ ป้องกันโค้ดมโน |
| [[Skills/writing-plans/SKILL|`writing-plans`]] | เขียนแผนงานการพัฒนาแบบละเอียด กะทัดรัด พร้อมเกณฑ์การทดสอบและตัวชี้วัดที่ชัดเจน |

### ==🐞 Stage 2: วินิจฉัยและแก้บักอย่างเป็นระบบ (02 - Bug Fixing & Defect Resolution)==
> *ใช้เมื่อมีข้อผิดพลาด ระบบแครช หรือพฤติกรรมผิดเพี้ยน โดยต้องพิสูจน์สาเหตุรากเหง้าก่อนลงมือแก้*

| ทักษะ (Skill) | หน้าที่และจังหวะเวลาที่เรียกใช้ |
| :--- | :--- |
| [[Skills/orch-fix-defect/SKILL|`orch-fix-defect`]] | กรอบงานแก้บักหลัก สร้าง Failing Regression Test พิสูจน์บักก่อนแก้ ป้องกันการแก้ปะผุ |
| [[Skills/systematic-debugging/SKILL|`systematic-debugging`]] | วินิจฉัยหาสาเหตุรากเหง้า 4 ขั้นตอน: ทำความเข้าใจ, จำลองบัก, สโคปสาเหตุ, และแก้ไขอย่างแม่นยำ |

### ==🗄️ Stage 3: ออกแบบฐานข้อมูลและ Schema (03 - Database & Migrations)==
> *ใช้เมื่อมีการเปลี่ยนแปลง Schema ฐานข้อมูล ปรับโครงสร้างข้อมูล หรือทำ Zero-Downtime Migration*

| ทักษะ (Skill) | หน้าที่และจังหวะเวลาที่เรียกใช้ |
| :--- | :--- |
| [[Skills/database-migrations/SKILL|`database-migrations`]] | การทำ Database Migration แบบ Zero-downtime, ป้องกัน Table Lock และรองรับทุก ORM |

### ==💻 Stage 4: ส่วนติดต่อผู้ใช้และมาตรฐานเว็บ (04 - Web & Frontend)==
> *ใช้ตอนพัฒนา Frontend, ทดสอบเบราว์เซอร์อัตโนมัติ และสร้าง Extension*

| ทักษะ (Skill) | หน้าที่และจังหวะเวลาที่เรียกใช้ |
| :--- | :--- |
| [[Skills/canvas/SKILL|`canvas`]] | สร้าง Live React Canvas Artifacts สำหรับแสดงผลและวิเคราะห์ข้อมูลเชิงลึกข้างแชท |
| [[Skills/chrome-extensions/SKILL|`chrome-extensions`]] | พัฒนาและเผยแพร่ Chrome Extension ตามมาตรฐาน Manifest V3 (Service Workers, Storage, UI) |
| [[Skills/claude-design/SKILL|`claude-design`]] | ออกแบบ UI/UX ระดับโลก, Dual-Mode Delivery (HTML Artifacts และ React/Tailwind), Atomic Button Craft, และ Slop Diagnostics |
| [[Skills/modern-web-guidance/SKILL|`modern-web-guidance`]] | ดึงแนวทางมาตรฐานเว็บล่าสุด (Core Web Vitals, Native HTML5, View Transitions) แบบ Real-time |
| [[Skills/playwright-cli/SKILL|`playwright-cli`]] | สั่งการเบราว์เซอร์อัตโนมัติ ทดสอบหน้าเว็บ แคปภาพหน้าจอ และขูดข้อมูลผ่าน Playwright CLI |
| [[Skills/playwright-trace/SKILL|`playwright-trace`]] | วิเคราะห์ไฟล์ Playwright Trace Zip จาก CLI เจาะลึก Request, Console Errors, DOM Snapshots |
| [[Skills/visualize/SKILL|`visualize`]] | สร้างแผนภูมิ ชาร์ต หรือภาพจำลองข้อมูลแบบกระชับในบทสนทนา |

### ==🛡️ Stage 5: ตรวจทานโค้ดและความปลอดภัย (05 - Security & Code Quality)==
> *ใช้ตรวจสอบคุณภาพ ตรวจช่องโหว่ความปลอดภัย OWASP และการยืนยันผลก่อนปิดงาน*

| ทักษะ (Skill) | หน้าที่และจังหวะเวลาที่เรียกใช้ |
| :--- | :--- |
| [[Skills/determine_threat_model/SKILL|`determine_threat_model`]] | สร้างแบบจำลองภัยคุกคาม (Threat Model) ระบุจุดรับข้อมูล, ขอบเขตความไว้วางใจ และความเสี่ยง |
| [[Skills/error-handling/SKILL|`error-handling`]] | การออกแบบ Typed Errors, Exception Hierarchy, Retries, และ Circuit Breaker ป้องกันระบบล่มต่อเนื่อง |
| [[Skills/receiving-code-review/SKILL|`receiving-code-review`]] | รับและประเมิน Feedback จาก Code Review อย่างรอบคอบตามหลักเทคนิค ไม่ยอมรับอย่างหลับหูหลับตา |
| [[Skills/review/SKILL|`review`]] | ตรวจทานคุณภาพและมาตรฐานของโค้ดก่อนส่งต่อหรือเปิด PR |
| [[Skills/review-bugbot/SKILL|`review-bugbot`]] | สแกนหาบั๊กที่อาจเล็ดลอดด้วย Bugbot subagent |
| [[Skills/review-security/SKILL|`review-security`]] | สแกนหาช่องโหว่ความปลอดภัย วิเคราะห์ Threat Model และตรวจสิทธิ์การเข้าถึง |
| [[Skills/verification-before-completion/SKILL|`verification-before-completion`]] | ยืนยันผลลัพธ์ด้วยหลักฐานก่อนแจ้งเสร็จ (Evidence before assertions) รันเทสต์และตรวจ git diff |

### ==🚀 Stage 6: จัดการ Git, Pull Request และปล่อยระบบ (06 - Git, Commits & Release)==
> *ใช้ทำ Conventional Commits, จัดการ Worktree, ตรวจ CI, และ Deploy สู่ Production*

| ทักษะ (Skill) | หน้าที่และจังหวะเวลาที่เรียกใช้ |
| :--- | :--- |
| [[Skills/autopilot/SKILL|`autopilot`]] | รัน CI และจัดการ Resolve Merge Conflicts แบบวนลูปอัตโนมัติจนผ่าน |
| [[Skills/deploy-with-vercel/SKILL|`deploy-with-vercel`]] | Deploy โปรเจกต์ขึ้น Cloud ผ่าน Vercel |
| [[Skills/finishing-a-development-branch/SKILL|`finishing-a-development-branch`]] | ปิดกิ่งพัฒนาอย่างสมบูรณ์ ยืนยันผลเทสต์ ทำความสะอาด worktree และเตรียมส่งมอบเข้าสายหลัก |
| [[Skills/git-workflow/SKILL|`git-workflow`]] | มาตรฐาน Git, Conventional Commits (feat:, fix:), การแตก Branch และกระบวนการ Release |
| [[Skills/github-pr-workflow/SKILL|`github-pr-workflow`]] | วงจรชีวิต GitHub PR แบบครบวงจร: แตก branch, เปิด PR ด้วย Template, เฝ้าระวัง CI, และ Merge |
| [[Skills/new-repo/SKILL|`new-repo`]] | เริ่มต้นสร้าง Git Repository และเชื่อมต่อไปยัง Remote ปลายทาง |
| [[Skills/origin/SKILL|`origin`]] | ติดตั้งและจัดการ Git remote สำหรับ Repo ที่โฮสต์บน Cursor |
| [[Skills/share/SKILL|`share`]] | บันทึกและแชร์ Snapshot ของโปรเจกต์อย่างปลอดภัย |
| [[Skills/split-to-prs/SKILL|`split-to-prs`]] | แบ่งชุดงานขนาดใหญ่ออกเป็น Pull Requests ย่อยที่ตรวจสอบง่ายและ Merge ได้ไว |
| [[Skills/using-git-worktrees/SKILL|`using-git-worktrees`]] | สร้างและจัดการ Git Worktrees เพื่อแยกสภาพแวดล้อมการพัฒนาคู่ขนานโดยไม่กระทบโฟลเดอร์หลัก |

### ==🤖 Stage 7: สำรวจโค้ดเบส งานอัตโนมัติ และเครื่องมือเสริม (07 - Codebase Exploration & Tooling)==
> *ใช้สำรวจโปรเจกต์ ทำงานประจำอัตโนมัติ และสร้างทักษะใหม่*

| ทักษะ (Skill) | หน้าที่และจังหวะเวลาที่เรียกใช้ |
| :--- | :--- |
| [[Skills/agent-introspection-debugging/SKILL|`agent-introspection-debugging`]] | ระบบวินิจฉัยและกู้คืนตนเองของ AI เมื่อเกิดปัญหาวนลูป ติดขัด หรือบริบทบวม |
| [[Skills/automate/SKILL|`automate`]] | สร้างและตั้งค่า Automations สำหรับระบบงานประจำ |
| [[Skills/baoyu-infographic/SKILL|`baoyu-infographic`]] | แปลงแนวคิดทางเทคนิคและสถาปัตยกรรมเป็น Infographic ภาพสวยงาม 21 รูปแบบและ 21 สไตล์ |
| [[Skills/codebase-onboarding/SKILL|`codebase-onboarding`]] | สแกนโปรเจกต์ใหม่ ทำแผนผังโครงสร้างสถาปัตยกรรม และวิเคราะห์ Entry Points อัตโนมัติ |
| [[Skills/create-hook/SKILL|`create-hook`]] | สร้าง Lifecycle Hook สำหรับดักจับเหตุการณ์ในระบบ Agent |
| [[Skills/create-rule/SKILL|`create-rule`]] | สร้าง Rule ถาวรสำหรับควบคุมแนวทางการเขียนโค้ดของ AI |
| [[Skills/create-skill/SKILL|`create-skill`]] | สร้าง Agent Skill ใหม่พร้อมโครงสร้างมาตรฐานสากล |
| [[Skills/create-subagent/SKILL|`create-subagent`]] | สร้างและเรียกใช้ Subagent สำหรับแบ่งงานเฉพาะทาง |
| [[Skills/excalidraw/SKILL|`excalidraw`]] | สร้างและแก้ไขไดอะแกรม JSON สำหรับ Excalidraw (Flowchart, Sequence, Architecture) ลายมือวาด |
| [[Skills/goal/SKILL|`goal`]] | สั่งการ Agent ให้ทำงานระยะยาวจนกว่าจะบรรลุเป้าหมายที่ตั้งไว้อย่างเคร่งครัด |
| [[Skills/llm-wiki/SKILL|`llm-wiki`]] | สร้างและสืบค้นคลังความรู้ Markdown (Karpathy LLM Wiki Pattern) สำหรับบันทึกงานวิจัยและระบบ |
| [[Skills/loop/SKILL|`loop`]] | รันคำสั่งหรือ Skill ซ้ำตามรอบเวลาที่กำหนด (เช่น ตรวจสอบสถานะทุก 5 นาที) |
| [[Skills/migrate-to-skills/SKILL|`migrate-to-skills`]] | แปลง Workflow เดิมมาเป็นโครงสร้าง Skill มาตรฐาน |
| [[Skills/onboard/SKILL|`onboard`]] | กระบวนการ Onboarding สภาพแวดล้อมและจดจำ Preferences ของนักพัฒนา |
| [[Skills/rename-chat/SKILL|`rename-chat`]] | ตั้งชื่อและจัดระเบียบ Session บทสนทนาตามหัวข้อที่ทำ |
| [[Skills/sdk/SKILL|`sdk`]] | พัฒนาแอปและสคริปต์ควบคุม Agent ผ่าน Cursor/Gemini SDK |
| [[Skills/shell/SKILL|`shell`]] | รันคำสั่ง Terminal ผ่าน Agent อย่างปลอดภัยและมีประสิทธิภาพ |
| [[Skills/statusline/SKILL|`statusline`]] | ปรับแต่งแถบสถานะ CLI Statusline |
| [[Skills/tmux/SKILL|`tmux`]] | ควบคุมเซสชัน tmux สำหรับโปรเซสพื้นหลังระยะยาว การส่งคีย์สโตรก และอ่านเอาต์พุตเทอร์มินัล |
| [[Skills/update-cli-config/SKILL|`update-cli-config`]] | ดูและแก้ไขการตั้งค่าคอนฟิกของ CLI |
| [[Skills/update-cursor-settings/SKILL|`update-cursor-settings`]] | ปรับแต่งการตั้งค่า User Preferences และ Settings ของ Editor |

### ==📄 Stage 8: จัดการเอกสารและชุดโปรแกรมสำนักงาน (08 - Productivity & Office Documents)==
> *ใช้สร้าง แก้ไข และจัดการเอกสาร Word, Excel, PowerPoint, PDF และ OCR*

| ทักษะ (Skill) | หน้าที่และจังหวะเวลาที่เรียกใช้ |
| :--- | :--- |
| [[Skills/docx/SKILL|`docx`]] | สร้าง ตรวจสอบ และแก้ไขไฟล์ Word (.docx) รองรับ Track Changes, Style และตาราง |
| [[Skills/document-design/SKILL|`document-design`]] | ออกแบบเอกสารระดับสิ่งพิมพ์, กฎสี 60-30-10, ตาราง Tufte, Typographic Measure, Web-to-PDF Pipeline, Word & Slides |
| [[Skills/ocr-and-documents/SKILL|`ocr-and-documents`]] | สกัดข้อความ ตาราง และสมการจากไฟล์ PDF สแกนหรือรูปภาพด้วย PyMuPDF และ Marker-PDF |
| [[Skills/pdf/SKILL|`pdf`]] | รวม แยก กรอกฟอร์มอัตโนมัติ ตรวจสอบ Bounding Boxes และสกัดเนื้อหาจากไฟล์ PDF |
| [[Skills/powerpoint/SKILL|`powerpoint`]] | สร้างและแก้ไขสไลด์นำเสนอ PowerPoint (.pptx) จัดฟอนต์ กราฟิก เลย์เอาต์ และสร้างภาพตัวอย่าง |
| [[Skills/xlsx/SKILL|`xlsx`]] | สร้างและแก้ไขสเปรดชีต Excel (.xlsx) คำนวณสูตร จัดรูปแบบตารางการเงิน และส่งออก CSV |

---

## 📊 ระบบสืบค้นอัตโนมัติผ่าน Dataview (หากเปิด Plugin Dataview)

```dataview
TABLE category as "ขั้นตอน (Stage)", description as "คำอธิบาย", file.mtime as "แก้ไขล่าสุด"
FROM "Skills"
WHERE file.name = "SKILL"
SORT category ASC, file.name ASC
```

---

## 🔗 โครงสร้างการเชื่อมต่อ AI
- **Antigravity Global Discovery:** `~/.gemini/config/skills/` ➔ ซิงค์กับ Vault นี้แบบ Real-time
- **Cursor Personal Skills:** `~/.cursor/skills/` ➔ ซิงค์กับ Vault นี้แบบ Real-time
