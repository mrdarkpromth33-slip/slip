from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class OrderStatus(str, Enum):
    pending = "pending"
    completed = "completed"
    failed = "failed"
    expired = "expired"


class TransactionStatus(str, Enum):
    pending_slip = "pending_slip"
    matched = "matched"
    verified = "verified"
    failed = "failed"


# Request Schemas
class GenerateQRRequest(BaseModel):
    order_id: str = Field(..., min_length=1, max_length=100)
    amount: float = Field(..., gt=0)


class WebhookLineNotification(BaseModel):
    app: str  # e.g., "LINE"
    title: str  # e.g., "LINE BK"
    text: str  # e.g., "เงินเข้า 100.50 บาท เวลา 12:00"
    timestamp: int  # Unix timestamp


# Response Schemas
class GenerateQRResponse(BaseModel):
    order_id: str
    amount: float
    qr_payload: str  # PromptPay payload string
    qr_raw_data: str  # EMVCo format
    created_at: datetime

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: int
    order_id: str
    amount: float
    status: OrderStatus
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TransactionResponse(BaseModel):
    id: int
    ref_id: str
    amount: float
    bank_id: Optional[str]
    status: TransactionStatus
    matched_order_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class WebhookResponse(BaseModel):
    success: bool
    message: str
    transaction_id: Optional[int]


class UploadSlipResponse(BaseModel):
    success: bool
    message: str
    ref_id: Optional[str]
    bank_id: Optional[str]
    matched_order_id: Optional[int]
    order_status: Optional[OrderStatus]
    verification_id: Optional[int]


class SlipVerificationDetail(BaseModel):
    id: int
    qr_found: bool
    qr_amount: Optional[float]
    ocr_amount: Optional[float]
    amounts_match: bool
    confidence: Optional[str]
    status: str  # pending / verified / rejected / manual_review
    rejection_reason: Optional[str]
    admin_notes: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True


class AdminVerificationRequest(BaseModel):
    verification_id: int
    approve: bool
    notes: Optional[str] = None
    admin_username: str


class AdminVerificationResponse(BaseModel):
    success: bool
    message: str
    verification_status: str
    order_status: Optional[OrderStatus]
