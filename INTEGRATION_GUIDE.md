# Integration Guide for Frontend & Android Developers

## 🔗 API Integration Examples

### For Web Frontend (JavaScript/React)

#### 1. Generate QR Code on Order Creation
```javascript
async function generatePaymentQR(orderId, amount) {
  try {
    const response = await fetch('http://api.example.com/api/payment/generate-qr', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        order_id: orderId,
        amount: amount
      })
    });

    const data = await response.json();
    
    if (response.ok) {
      // Display QR Code
      return {
        success: true,
        qrPayload: data.qr_payload,
        finalAmount: data.amount,  // Note: may differ due to micro-transaction
        orderID: data.order_id
      };
    } else {
      console.error('Failed to generate QR:', data);
      return { success: false, error: data.detail };
    }
  } catch (error) {
    console.error('Error:', error);
    return { success: false, error: error.message };
  }
}

// Usage with qrcode library
import QRCode from 'qrcode';

async function displayQRCode(qrPayload) {
  const canvas = document.getElementById('qr-canvas');
  await QRCode.toCanvas(canvas, qrPayload);
}
```

#### 2. Poll for Payment Status
```javascript
async function pollPaymentStatus(orderId, maxAttempts = 60) {
  let attempts = 0;
  const pollInterval = 2000; // 2 seconds

  return new Promise((resolve, reject) => {
    const intervalId = setInterval(async () => {
      attempts++;

      try {
        const response = await fetch(`http://api.example.com/api/orders/${orderId}`);
        const order = await response.json();

        console.log(`Poll attempt ${attempts}: Status = ${order.status}`);

        if (order.status === 'completed') {
          clearInterval(intervalId);
          resolve({ success: true, order: order });
        } else if (order.status === 'failed' || order.status === 'expired') {
          clearInterval(intervalId);
          reject({ success: false, status: order.status });
        }

        if (attempts >= maxAttempts) {
          clearInterval(intervalId);
          reject({ success: false, error: 'Timeout waiting for payment' });
        }
      } catch (error) {
        console.error('Poll error:', error);
      }
    }, pollInterval);
  });
}

// Usage
async function handlePayment(orderId) {
  try {
    await pollPaymentStatus(orderId);
    console.log('Payment successful!');
    redirect('/success');
  } catch (error) {
    console.log('Payment failed or timeout');
    redirect('/failed');
  }
}
```

#### 3. Upload Slip Image
```javascript
async function uploadSlip(orderId, fileInput) {
  const formData = new FormData();
  formData.append('file', fileInput.files[0]);
  formData.append('order_id', orderId);

  try {
    const response = await fetch('http://api.example.com/api/payment/upload-slip', {
      method: 'POST',
      body: formData  // Don't set Content-Type header
    });

    const data = await response.json();
    
    if (response.ok && data.success) {
      return {
        success: true,
        message: data.message,
        orderStatus: data.order_status,
        refId: data.ref_id
      };
    } else {
      return {
        success: false,
        error: data.message || 'Upload failed'
      };
    }
  } catch (error) {
    console.error('Upload error:', error);
    return { success: false, error: error.message };
  }
}

// Usage in React
import React, { useState } from 'react';

export function SlipUploadForm({ orderId, onSuccess }) {
  const [uploading, setUploading] = useState(false);
  const fileInputRef = React.useRef();

  const handleUpload = async () => {
    setUploading(true);
    const result = await uploadSlip(orderId, fileInputRef.current);
    setUploading(false);

    if (result.success) {
      alert('Payment verified!');
      onSuccess();
    } else {
      alert('Error: ' + result.error);
    }
  };

  return (
    <div>
      <input ref={fileInputRef} type="file" accept="image/*" />
      <button onClick={handleUpload} disabled={uploading}>
        {uploading ? 'Uploading...' : 'Upload & Verify'}
      </button>
    </div>
  );
}
```

---

### For Android App (Kotlin/Java)

#### 1. Capture LINE Bank Notification and Send Webhook
```kotlin
// Android Service to capture notifications
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import kotlinx.coroutines.*
import okhttp3.*
import org.json.JSONObject

class PaymentNotificationListener : NotificationListenerService() {
    private val client = OkHttpClient()

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)

        sbn?.let {
            val notification = it.notification
            val extras = notification.extras
            
            // Check if it's LINE Bank notification
            val appPackage = it.packageName
            val title = extras.getString("android.title")
            val text = extras.getCharSequence("android.text")?.toString()

            if (appPackage.contains("jp.co.linebk.android")) {
                // Send webhook to backend
                sendWebhook(
                    app = "LINE",
                    title = title ?: "LINE BK",
                    text = text ?: "",
                    timestamp = System.currentTimeMillis() / 1000
                )
            }
        }
    }

    private fun sendWebhook(app: String, title: String, text: String, timestamp: Long) {
        val json = JSONObject().apply {
            put("app", app)
            put("title", title)
            put("text", text)
            put("timestamp", timestamp)
        }

        val requestBody = RequestBody.create(
            MediaType.parse("application/json"),
            json.toString()
        )

        val request = Request.Builder()
            .url("http://api.example.com/api/webhook/linebk")
            .post(requestBody)
            .build()

        // Execute in background thread
        CoroutineScope(Dispatchers.IO).launch {
            try {
                client.newCall(request).execute().use { response ->
                    if (response.isSuccessful) {
                        Log.d("Webhook", "Payment notification sent successfully")
                    } else {
                        Log.e("Webhook", "Failed to send webhook: ${response.code()}")
                    }
                }
            } catch (e: Exception) {
                Log.e("Webhook", "Error sending webhook: ${e.message}")
            }
        }
    }
}

// AndroidManifest.xml permissions
<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />

// In AndroidManifest.xml service declaration
<service
    android:name=".PaymentNotificationListener"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

#### 2. Upload Slip from Camera/Gallery
```kotlin
import android.content.Intent
import android.net.Uri
import androidx.activity.result.contract.ActivityResultContracts
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import java.io.File

class SlipUploadActivity : AppCompatActivity() {
    private val pickImageLauncher = registerForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { uploadSlipImage(it) }
    }

    fun selectSlipImage() {
        pickImageLauncher.launch("image/*")
    }

    private fun uploadSlipImage(imageUri: Uri, orderId: String) {
        val client = OkHttpClient()
        
        // Read file from URI
        val file = File(cacheDir, "slip_image.jpg")
        val inputStream = contentResolver.openInputStream(imageUri)
        file.outputStream().use { fileOut ->
            inputStream?.copyTo(fileOut)
        }

        // Create multipart request
        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("file", file.name, RequestBody.create(
                "image/jpeg".toMediaTypeOrNull(), file
            ))
            .addFormDataPart("order_id", orderId)
            .build()

        val request = Request.Builder()
            .url("http://api.example.com/api/payment/upload-slip")
            .post(requestBody)
            .build()

        CoroutineScope(Dispatchers.IO).launch {
            try {
                client.newCall(request).execute().use { response ->
                    val responseBody = response.body?.string() ?: ""
                    val json = JSONObject(responseBody)
                    
                    withContext(Dispatchers.Main) {
                        if (response.isSuccessful && json.optBoolean("success")) {
                            showMessage("Payment verified: ${json.optString("message")}")
                            // Order completed
                        } else {
                            showMessage("Error: ${json.optString("message")}")
                        }
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    showMessage("Upload failed: ${e.message}")
                }
            }
        }
    }

    private fun showMessage(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()
    }
}
```

---

## 📱 Payment Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Customer Payment Flow                  │
└─────────────────────────────────────────────────────────────┘

1. GENERATE QR CODE (Website)
   ┌──────────────────────┐
   │ POST /api/payment/   │
   │  generate-qr         │
   │ {order_id, amount}   │
   └──────────────────────┘
            │ │
            ↓ ↓
   ┌──────────────────────┐
   │ Backend generates    │
   │ PromptPay QR code    │
   │ (with micro-tx)      │
   └──────────────────────┘
            ↓
   ┌──────────────────────┐
   │ Website displays QR  │
   │ Customer scans with  │
   │ banking app or LINE  │
   └──────────────────────┘

2. PAYMENT SENT (Customer)
   ┌──────────────────────┐
   │ Customer transfers   │
   │ funds from bank      │
   └──────────────────────┘
            ↓
   ┌──────────────────────┐
   │ LINE Bank sends      │
   │ notification to      │
   │ Android phone        │
   └──────────────────────┘

3. WEBHOOK FROM ANDROID (Background)
   ┌──────────────────────┐
   │ Android app captures │
   │ LINE notification    │
   └──────────────────────┘
            │ │
            ↓ ↓
   ┌──────────────────────┐
   │ POST /api/webhook/   │
   │ linebk {text, ...}   │
   └──────────────────────┘
            │ │
            ↓ ↓
   ┌──────────────────────┐
   │ Backend records      │
   │ transaction info     │
   │ (status: pending)    │
   └──────────────────────┘

4. SLIP VERIFICATION (Customer)
   ┌──────────────────────┐
   │ Customer uploads     │
   │ slip screenshot      │
   │ (with QR code)       │
   └──────────────────────┘
            │ │
            ↓ ↓
   ┌──────────────────────┐
   │ POST /api/payment/   │
   │ upload-slip          │
   │ {file, order_id}     │
   └──────────────────────┘
            │ │
            ↓ ↓
   ┌──────────────────────┐
   │ Backend reads QR     │
   │ from slip image      │
   └──────────────────────┘
            │ │
            ↓ ↓
   ┌──────────────────────┐
   │ Verify:              │
   │ - Ref ID matches     │
   │ - Amount matches     │
   │ - No duplicates      │
   └──────────────────────┘
            │ │
            ↓ ↓
   ┌──────────────────────┐
   │ UPDATE order status  │
   │ → COMPLETED ✓        │
   └──────────────────────┘

5. POLLING STATUS (Website)
   ┌──────────────────────┐
   │ GET /api/orders/     │
   │ {order_id}           │
   │ (every 2 seconds)    │
   └──────────────────────┘
            │ │
            ↓ ↓
   ┌──────────────────────┐
   │ Website detects      │
   │ status: completed    │
   │ Show success message │
   └──────────────────────┘
```

---

## ⚙️ Environment Setup for Developers

### Backend (.env)
```
DATABASE_URL=postgresql://user:password@localhost:5432/slip_db
API_PREFIX=/api
DEBUG=True
```

### Frontend (.env)
```
REACT_APP_API_URL=http://localhost:8000
REACT_APP_API_TIMEOUT=30000
```

### Android (build.gradle)
```gradle
dependencies {
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.11.0'
    implementation 'org.json:json:20230227'
}
```

---

## 🧪 Testing Checklist

- [ ] QR code generates correctly with PromptPay format
- [ ] Micro-transaction decimal is added (0.01-0.99)
- [ ] Webhook receives and parses amount correctly
- [ ] Slip upload reads QR code from image
- [ ] Order status updates to completed after slip verification
- [ ] Polling detects payment completion
- [ ] Multiple orders with same amount don't conflict
- [ ] Error handling for missing/invalid slip image

---

## 📞 Common Issues & Solutions

**Q: QR code not generating**
→ Check PromptPay account format (phone or national ID)

**Q: Amount doesn't match after micro-transaction**
→ Display the exact amount from QR response, not input amount

**Q: Webhook not received**
→ Ensure Android app has notification listener permission

**Q: Slip upload fails**
→ Upload high-quality image (600x600px or larger)

**Q: Payment shows as pending**
→ Ensure QR code in slip matches generated QR format

