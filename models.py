from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum as SQLEnum, Index, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from database import Base


class OrderStatus(str, enum.Enum):
    pending = "pending"
    completed = "completed"
    failed = "failed"
    expired = "expired"


class TransactionStatus(str, enum.Enum):
    pending_slip = "pending_slip"
    matched = "matched"
    verified = "verified"
    failed = "failed"


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(String(100), unique=True, index=True, nullable=False)
    amount = Column(Float, nullable=False)  # Decimal precision (e.g., 100.01)
    status = Column(SQLEnum(OrderStatus), default=OrderStatus.pending, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    transactions = relationship("Transaction", back_populates="order")

    __table_args__ = (Index("idx_order_id_status", "order_id", "status"),)


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    ref_id = Column(String(255), unique=True, index=True, nullable=False)  # Transaction reference from bank
    amount = Column(Float, nullable=False)
    bank_id = Column(String(50), nullable=True)  # Sending bank ID
    status = Column(SQLEnum(TransactionStatus), default=TransactionStatus.pending_slip, nullable=False)
    matched_order_id = Column(Integer, ForeignKey("orders.id"), nullable=True, index=True)
    notification_text = Column(String(500), nullable=True)  # Original notification text from LINE BK
    slip_image_path = Column(String(255), nullable=True)  # Path to uploaded slip image
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    order = relationship("Order", back_populates="transactions")
    verification = relationship("SlipVerification", uselist=False, back_populates="transaction")

    __table_args__ = (Index("idx_ref_id_status", "ref_id", "status"),)


class VerificationStatus(str, enum.Enum):
    pending = "pending"
    verified = "verified"
    rejected = "rejected"
    manual_review = "manual_review"
    approved_by_admin = "approved_by_admin"


class SlipVerification(Base):
    """
    Detailed verification audit trail for each slip upload
    Tracks QR + OCR results, matching, and admin actions
    """
    __tablename__ = "slip_verifications"

    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(Integer, ForeignKey("transactions.id"), unique=True, nullable=False, index=True)
    
    # QR Analysis
    qr_found = Column(Boolean, default=False)
    qr_data = Column(String(500), nullable=True)
    qr_amount = Column(Float, nullable=True)
    qr_ref_id = Column(String(255), nullable=True)
    
    # OCR Analysis
    ocr_text = Column(String(2000), nullable=True)
    ocr_amount = Column(Float, nullable=True)
    ocr_ref_id = Column(String(255), nullable=True)
    
    # Matching Results
    amounts_match = Column(Boolean, default=False)
    amount_difference = Column(Float, nullable=True)  # |expected - actual|
    order_amount = Column(Float, nullable=True)
    
    # Verification Status
    status = Column(SQLEnum(VerificationStatus), default=VerificationStatus.pending, nullable=False)
    confidence = Column(String(20), nullable=True)  # high / medium / low
    rejection_reason = Column(String(255), nullable=True)
    
    # Admin Actions
    approved_by = Column(String(100), nullable=True)  # admin username
    admin_notes = Column(String(500), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    verified_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    transaction = relationship("Transaction", back_populates="verification")
    
    __table_args__ = (Index("idx_status_created", "status", "created_at"),)
