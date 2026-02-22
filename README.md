# slip
​1. การออกแบบสถาปัตยกรรม API สำหรับเว็บไซต์ (API Architecture Design)
​เพื่อให้เว็บไซต์ทำงานร่วมกับระบบที่คุณออกแบบไว้ได้อย่างสมบูรณ์ Backend ของเราควรมี API Endpoints หลักๆ ดังนี้ครับ
​1.1 ลำดับการทำงาน (Workflow)
​Customer -> Website: ลูกค้ากดสั่งซื้อสินค้า เว็บไซต์เรียก API สร้าง QR Code ยอดเงินแบบระบุทศนิยม (เพื่อความแม่นยำในการตรวจสอบ)
​Website -> Customer: แสดง QR Code ให้ลูกค้าสแกนจ่าย
​Android App -> Backend: แอปบนมือถือดักจับ Notification จาก LINE BK แล้วส่ง Webhook มาที่ Backend (บอกว่ามียอดเงิน x.xx บาทเข้ามา)
​Customer -> Website: ลูกค้าอัปโหลดสลิปโอนเงิน (เพื่อความชัวร์และอ้างอิง Ref ID)
​Backend: อ่าน QR บนสลิป ดึงข้อมูล Sending Bank ID และ Transaction Ref ID นำไปเช็คกับฐานข้อมูลว่าตรงกับ Webhook ที่เข้ามาและยอดเงินของ Order หรือไม่
​Website -> Backend: เว็บไซต์ใช้การทำ Polling หรือ WebSocket เพื่อรอรับสถานะว่า "ชำระเงินสำเร็จ"
​1.2 แนะนำเทคโนโลยี (Tech Stack)
​จากข้อมูลที่คุณวิเคราะห์มา ผมแนะนำให้เริ่มต้นด้วย Python (FastAPI) ครับ เนื่องจากพัฒนา API ได้รวดเร็วมาก รองรับ Asynchronous (ดีสำหรับรอ Webhook) และมีไลบรารีจัดการภาพสลิป (pyzbar, opencv) ที่พร้อมใช้งานทันที ส่วนฐานข้อมูลแนะนำเป็น PostgreSQL ครับ
​2. ชุดคำสั่ง (Prompts) สำหรับพัฒนาระบบ
​เพื่อให้การสร้าง API เป็นระบบและโค้ดไม่ตีกัน ผมได้แบ่ง Prompt ออกเป็น 3 ส่วนหลัก คุณสามารถคัดลอก Prompt เหล่านี้ไปสั่งผมทีละส่วนเพื่อเริ่มเขียนโค้ดได้เลยครับ
​Prompt 1: สร้างโครงสร้าง Database และระบบสร้าง QR Code (PromptPay)
​Copy prompt ด้านล่างนี้ไปใช้งาน:
"คุณเป็นผู้เชี่ยวชาญด้าน Python และ FastAPI ช่วยเขียนโค้ดสำหรับระบบรับชำระเงิน PromptPay แบบ Self-hosted โดยเริ่มจาก:
​สร้างโมเดลฐานข้อมูลด้วย SQLAlchemy (PostgreSQL) ประกอบด้วยตาราง orders (id, amount, status, created_at) และ transactions (ref_id, amount, bank_id, status, matched_order_id)
​สร้าง API Endpoint: POST /api/payment/generate-qr โดยรับ order_id และ amount เพื่อสร้าง Payload PromptPay ตามมาตรฐาน EMVCo (รองรับ promptpay-qr) และส่งคืนค่าเป็น string payload เพื่อให้ฝั่งหน้าเว็บนำไปแสดงเป็น QR Code ต่อไป"
​Prompt 2: สร้างระบบรับ Webhook จาก Android Notification
​Copy prompt ด้านล่างนี้ไปใช้งาน:
"เขียนโค้ด FastAPI ต่อจากส่วนที่แล้ว โดยสร้าง Endpoint สำหรับรับ Webhook จากแอปพลิเคชัน Android:
​สร้าง API Endpoint: POST /api/webhook/linebk
​รับ Request JSON ที่ประกอบด้วยข้อมูลเบื้องต้นจากการแจ้งเตือน เช่น {'app': 'LINE', 'title': 'LINE BK', 'text': 'เงินเข้า 100.50 บาท เวลา 12:00', 'timestamp': 1678888888}
​เขียน Logic เบื้องต้นในการใช้ Regex สกัดตัวเลขยอดเงิน (amount) ออกจากข้อความ text
​บันทึกข้อมูลที่ดึงได้ลงตาราง transactions โดยตั้งสถานะเป็น pending_slip"
​Prompt 3: สร้างระบบอัปโหลดสลิป, ถอดรหัส QR (OCR/Pyzbar) และยืนยันยอด
​Copy prompt ด้านล่างนี้ไปใช้งาน:
"เขียนโค้ด FastAPI ต่อจากส่วนที่แล้ว สำหรับจัดการสลิปโอนเงิน:
​สร้าง API Endpoint: POST /api/payment/upload-slip รับไฟล์รูปภาพสลิป (UploadFile)
​ใช้ไลบรารี opencv-python และ pyzbar หรือ promptparse ในการอ่าน QR Code จากรูปภาพสลิป
​ดึงข้อมูล Transaction Ref ID และ Bank ID จาก Payload ของ QR สลิป
​สร้าง Logic ตรวจสอบ: นำ Ref ID ที่ได้ไปเช็คว่าซ้ำซ้อนไหม และจับคู่ยอดเงินให้ตรงกับตาราง orders และข้อมูล Webhook ที่อยู่ใน transactions
​หากตรงกันทั้งหมด ให้อัปเดตสถานะ order เป็น completed และคืนค่า HTTP 200"
​ข้อควรระวังเพิ่มเติมจากความเป็นจริง (Reality Check)
​ความน่าเชื่อถือของ Notification: ระบบปฏิบัติการ Android บางเวอร์ชันอาจหยุดการทำงานของแอปพื้นหลัง ทำให้ Notification Webhook ส่งมาไม่ถึง Backend การออกแบบให้ระบบอ่าน QR จากสลิปเป็นหลัก (ตาม Prompt 3) แล้วค่อยนำไปเช็คกับยอดเงินที่คาดหวัง จึงเป็นวิธีสำรองที่ปลอดภัยที่สุดครับ
​Micro-transactions (ทศนิยม): หากคุณขายของราคาเท่ากันหลายออเดอร์ในเวลาเดียวกัน แนะนำให้ระบบบวกเศษสตางค์แบบสุ่ม (เช่น 100.01 บาท, 100.02 บาท) เพื่อให้จับคู่ Webhook กับ Order ได้ง่ายและแม่นยำขึ้นครับ
