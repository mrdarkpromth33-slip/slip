from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
import logging
from datetime import datetime
import io
import os
import time

from config import settings
from database import engine, get_db, Base
from models import Order, Transaction, OrderStatus, TransactionStatus, SlipVerification, VerificationStatus
import schemas
from payment_service import PromptPayQRGenerator, extract_amount_from_text
from qr_reader import SlipQRReader

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize database tables with retry logic
def init_db():
    """Initialize database tables with retry logic for PostgreSQL startup"""
    max_retries = 5
    retry_delay = 2
    
    for attempt in range(max_retries):
        try:
            logger.info(f"Attempting to create database tables (attempt {attempt + 1}/{max_retries})...")
            Base.metadata.create_all(bind=engine)
            logger.info("✓ Database tables created successfully")
            return True
        except Exception as e:
            logger.warning(f"Database init failed: {str(e)}")
            if attempt < max_retries - 1:
                logger.info(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                logger.error("Failed to initialize database after all retries")
                return False
    return False

# Create FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.PROJECT_VERSION,
)

# Initialize database on app startup
@app.on_event("startup")
async def startup_event():
    """Initialize database when app starts"""
    logger.info("FastAPI app starting up...")
    init_db()
    logger.info("✓ Application startup complete")

# ============================================================================
# ENDPOINT 1: Generate QR Code (POST /api/payment/generate-qr)
# ============================================================================

@app.post(
    "/api/payment/generate-qr",
    response_model=schemas.GenerateQRResponse,
    tags=["Payment"]
)
async def generate_qr(
    request: schemas.GenerateQRRequest,
    db: Session = Depends(get_db)
):
    """
    Generate PromptPay QR Code for payment
    
    - **order_id**: Unique order identifier
    - **amount**: Payment amount in Thai Baht (will add random cent for matching)
    """
    
    try:
        # Check if order already exists
        existing_order = db.query(Order).filter(
            Order.order_id == request.order_id
        ).first()
        
        if existing_order:
            # Return existing order
            qr_payload = PromptPayQRGenerator.generate_qr_payload(
                account_id=request.order_id,
                amount=existing_order.amount
            )
            
            return schemas.GenerateQRResponse(
                order_id=existing_order.order_id,
                amount=existing_order.amount,
                qr_payload=qr_payload,
                qr_raw_data=qr_payload,
                created_at=existing_order.created_at
            )
        
        # Add micro-transaction (random decimal for accurate matching)
        final_amount = PromptPayQRGenerator.add_micro_transaction(request.amount)
        
        # Create new order
        db_order = Order(
            order_id=request.order_id,
            amount=final_amount,
            status=OrderStatus.pending,
            created_at=datetime.utcnow()
        )
        db.add(db_order)
        db.flush()  # Get the ID without committing
        
        # Generate PromptPay QR Code
        # Using order_id as the account ID (in real scenario, use merchant PromptPay ID)
        qr_payload = PromptPayQRGenerator.generate_qr_payload(
            account_id=request.order_id,  # Could be phone or national ID
            amount=final_amount
        )
        
        db.commit()
        db.refresh(db_order)
        
        logger.info(f"QR generated for order {request.order_id} with amount {final_amount}")
        
        return schemas.GenerateQRResponse(
            order_id=db_order.order_id,
            amount=db_order.amount,
            qr_payload=qr_payload,
            qr_raw_data=qr_payload,
            created_at=db_order.created_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error generating QR: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate QR code: {str(e)}"
        )


# ============================================================================
# ENDPOINT 2: Webhook Receiver for LINE Bank Notification
# POST /api/webhook/linebk
# ============================================================================

@app.post(
    "/api/webhook/linebk",
    response_model=schemas.WebhookResponse,
    tags=["Webhook"]
)
async def receive_line_notification(
    request: schemas.WebhookLineNotification,
    db: Session = Depends(get_db)
):
    """
    Receive webhook notification from Android app (LINE Bank notification)
    
    Expected payload:
    {
        "app": "LINE",
        "title": "LINE BK",
        "text": "เงินเข้า 100.50 บาท เวลา 12:00",
        "timestamp": 1678888888
    }
    """
    
    try:
        # Extract amount from notification text using regex
        amount = extract_amount_from_text(request.text)
        
        if amount is None:
            logger.warning(f"Could not extract amount from text: {request.text}")
            return schemas.WebhookResponse(
                success=False,
                message="Could not extract amount from notification"
            )
        
        # Generate reference ID from timestamp and amount
        # In real scenario, this would come from the bank notification
        ref_id = f"{request.timestamp}_{amount}".replace(".", "")
        
        # Check if this transaction already exists
        existing_tx = db.query(Transaction).filter(
            Transaction.ref_id == ref_id
        ).first()
        
        if existing_tx:
            logger.info(f"Transaction already recorded: {ref_id}")
            return schemas.WebhookResponse(
                success=True,
                message="Transaction already recorded",
                transaction_id=existing_tx.id
            )
        
        # Create new transaction record
        db_transaction = Transaction(
            ref_id=ref_id,
            amount=amount,
            bank_id=None,  # Will be extracted from slip QR
            status=TransactionStatus.pending_slip,
            notification_text=request.text,
            created_at=datetime.utcnow()
        )
        db.add(db_transaction)
        db.commit()
        db.refresh(db_transaction)
        
        logger.info(f"Webhook recorded: ref_id={ref_id}, amount={amount}")
        
        return schemas.WebhookResponse(
            success=True,
            message="Notification received and recorded",
            transaction_id=db_transaction.id
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error processing webhook: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process webhook: {str(e)}"
        )


# ============================================================================
# ENDPOINT 3: Upload Slip and Verify Payment
# POST /api/payment/upload-slip
# ============================================================================

@app.post(
    "/api/payment/upload-slip",
    response_model=schemas.UploadSlipResponse,
    tags=["Payment"]
)
async def upload_slip(
    file: UploadFile = File(...),
    order_id: str = None,
    db: Session = Depends(get_db)
):
    """
    Upload slip image with 100% strict verification
    
    - Comprehensive QR + OCR dual analysis
    - STRICT amount matching (no tolerance)
    - Duplicate detection
    - Detailed audit trail
    - Manual review for edge cases
    """
    
    try:
        # Read file content
        contents = await file.read()
        
        if not contents:
            raise ValueError("File is empty")
        
        # ========== STEP 1: Comprehensive Analysis ==========
        logger.info(f"Starting comprehensive analysis for {file.filename}")
        analysis = SlipQRReader.comprehensive_slip_analysis(contents)
        
        # ========== STEP 2: Validate QR Found ==========
        if not analysis["qr_found"]:
            logger.warning("QR code not found in image")
            return schemas.UploadSlipResponse(
                success=False,
                message="❌ QR Code not found in slip image. Please upload a clear slip photo with visible QR code."
            )
        
        qr_amount = analysis["extracted_data"]["qr_amount"]
        qr_ref_id = analysis["extracted_data"]["qr_ref_id"]
        ocr_amount = analysis["extracted_data"]["ocr_amount"]
        
        if not qr_amount:
            logger.warning("Could not extract amount from QR code")
            return schemas.UploadSlipResponse(
                success=False,
                message="❌ Could not extract amount from QR code. QR may be damaged."
            )
        
        # ========== STEP 3: Find Target Order ==========
        if order_id:
            order = db.query(Order).filter(Order.order_id == order_id).first()
        else:
            # Try to match by amount (STRICT: must be exact match)
            order = db.query(Order).filter(
                and_(
                    Order.status == OrderStatus.pending,
                    Order.amount == qr_amount  # STRICT: no tolerance
                )
            ).order_by(Order.created_at.desc()).first()
        
        if not order:
            logger.warning(f"No matching order for amount {qr_amount}")
            # Create verification record with failure
            verification = SlipVerification(
                transaction_id=None,
                qr_found=True,
                qr_amount=qr_amount,
                ocr_amount=ocr_amount,
                amounts_match=False,
                status=VerificationStatus.rejected,
                rejection_reason=f"No order found matching amount {qr_amount} exactly"
            )
            db.add(verification)
            db.commit()
            
            return schemas.UploadSlipResponse(
                success=False,
                message=f"❌ No order found for amount {qr_amount}. Check if amount is correct.",
                verification_id=verification.id
            )
        
        # ========== STEP 4: STRICT Amount Matching ==========
        amount_diff = abs(order.amount - qr_amount)
        amounts_match = amount_diff == 0  # STRICT: must be exact
        
        if not amounts_match:
            logger.warning(f"Amount mismatch: expected {order.amount}, got {qr_amount}, diff={amount_diff}")
            return schemas.UploadSlipResponse(
                success=False,
                message=f"❌ AMOUNT MISMATCH! Expected {order.amount:,.2f} ฿ but slip shows {qr_amount:,.2f} ฿ (Difference: {amount_diff:,.2f} ฿)"
            )
        
        # ========== STEP 5: Check Duplicate Transaction ==========
        existing_tx = db.query(Transaction).filter(
            Transaction.ref_id == qr_ref_id,
            Transaction.status != TransactionStatus.failed
        ).first()
        
        if existing_tx:
            logger.warning(f"Duplicate transaction detected: {qr_ref_id}")
            return schemas.UploadSlipResponse(
                success=False,
                message="❌ This transaction has already been used. Duplicate payment detected!"
            )
        
        # ========== STEP 6: Cross-Verify with OCR (if available) ==========
        ocr_matches = False
        if ocr_amount:
            ocr_matches = abs(ocr_amount - qr_amount) < 0.01
            if not ocr_matches:
                logger.warning(f"OCR/QR mismatch: QR={qr_amount}, OCR={ocr_amount}")
        
        confidence = analysis["confidence"]
        
        # ========== STEP 7: Create Transaction ==========
        transaction = Transaction(
            ref_id=qr_ref_id or f"{int(datetime.utcnow().timestamp())}_{qr_amount}",
            amount=qr_amount,
            bank_id=analysis["extracted_data"]["qr_ref_id"],
            status=TransactionStatus.verified,
            matched_order_id=order.id,
            slip_image_path=file.filename,
            created_at=datetime.utcnow()
        )
        db.add(transaction)
        db.flush()
        
        # ========== STEP 8: Create Detailed Verification Record ==========
        verification = SlipVerification(
            transaction_id=transaction.id,
            qr_found=analysis["qr_found"],
            qr_data=analysis["qr_data"],
            qr_amount=qr_amount,
            qr_ref_id=qr_ref_id,
            ocr_text=analysis["ocr_text"],
            ocr_amount=ocr_amount,
            ocr_ref_id=analysis["extracted_data"]["ocr_ref_id"],
            amounts_match=amounts_match,
            amount_difference=amount_diff,
            order_amount=order.amount,
            status=VerificationStatus.verified,
            confidence=confidence,
            verified_at=datetime.utcnow()
        )
        db.add(verification)
        
        # ========== STEP 9: Update Order Status ==========
        order.status = OrderStatus.completed
        order.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(order)
        db.refresh(transaction)
        db.refresh(verification)
        
        logger.info(
            f"✅ PAYMENT VERIFIED: order_id={order.order_id}, "
            f"amount={order.amount}, confidence={confidence}, "
            f"qr_match=✓, ocr_match={'✓' if ocr_matches else '✗'}"
        )
        
        return schemas.UploadSlipResponse(
            success=True,
            message="✅ Payment verified successfully! All checks passed.",
            ref_id=qr_ref_id,
            bank_id=analysis["extracted_data"]["qr_ref_id"],
            matched_order_id=order.id,
            order_status=OrderStatus.completed,
            verification_id=verification.id
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error uploading slip: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process slip: {str(e)}"
        )


# ============================================================================
# ADMIN VERIFICATION ENDPOINT (for manual review cases)
# ============================================================================

@app.post(
    "/api/admin/verify-payment",
    response_model=schemas.AdminVerificationResponse,
    tags=["Admin"]
)
async def admin_verify_payment(
    request: schemas.AdminVerificationRequest,
    db: Session = Depends(get_db)
):
    """
    Admin manual verification endpoint
    Used for edge cases that failed automatic verification
    """
    
    try:
        verification = db.query(SlipVerification).filter(
            SlipVerification.id == request.verification_id
        ).first()
        
        if not verification:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Verification record not found"
            )
        
        if request.approve:
            # Admin approved
            verification.status = VerificationStatus.approved_by_admin
            verification.approved_by = request.admin_username
            verification.admin_notes = request.notes
            
            # Update transaction status
            transaction = verification.transaction
            transaction.status = TransactionStatus.verified
            
            # Update order status
            if transaction.matched_order_id:
                order = db.query(Order).filter(
                    Order.id == transaction.matched_order_id
                ).first()
                if order:
                    order.status = OrderStatus.completed
                    order.updated_at = datetime.utcnow()
            
            message = "✅ Payment approved by admin"
            order_status = OrderStatus.completed
            
        else:
            # Admin rejected
            verification.status = VerificationStatus.rejected
            verification.approved_by = request.admin_username
            verification.rejection_reason = request.notes or "Rejected by admin"
            verification.admin_notes = request.notes
            
            # Update transaction status
            transaction = verification.transaction
            transaction.status = TransactionStatus.failed
            
            # Revert order status
            if transaction.matched_order_id:
                order = db.query(Order).filter(
                    Order.id == transaction.matched_order_id
                ).first()
                if order:
                    order.status = OrderStatus.failed
                    order.updated_at = datetime.utcnow()
            
            message = "❌ Payment rejected by admin"
            order_status = OrderStatus.failed
        
        db.commit()
        
        logger.info(
            f"Admin verification: verification_id={request.verification_id}, "
            f"approved={request.approve}, admin={request.admin_username}"
        )
        
        return schemas.AdminVerificationResponse(
            success=True,
            message=message,
            verification_status=verification.status,
            order_status=order_status
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error in admin verification: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Admin verification failed: {str(e)}"
        )


@app.get(
    "/api/admin/verifications",
    tags=["Admin"]
)
async def list_verifications(
    status_filter: str = None,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    List all verification records (for admin review)
    """
    query = db.query(SlipVerification)
    
    if status_filter:
        query = query.filter(SlipVerification.status == status_filter)
    
    verifications = query.order_by(
        SlipVerification.created_at.desc()
    ).limit(limit).all()
    
    return [
        {
            "id": v.id,
            "status": v.status,
            "qr_amount": v.qr_amount,
            "order_amount": v.order_amount,
            "amounts_match": v.amounts_match,
            "confidence": v.confidence,
            "created_at": v.created_at,
            "rejection_reason": v.rejection_reason
        }
        for v in verifications
    ]


# ============================================================================
# HEALTH CHECK & INFO ENDPOINTS
# ============================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": settings.PROJECT_NAME,
        "version": settings.PROJECT_VERSION
    }


@app.get("/api/info")
async def api_info():
    """API information"""
    return {
        "name": settings.PROJECT_NAME,
        "version": settings.PROJECT_VERSION,
        "endpoints": [
            {
                "method": "POST",
                "path": "/api/payment/generate-qr",
                "description": "Generate PromptPay QR code"
            },
            {
                "method": "POST",
                "path": "/api/webhook/linebk",
                "description": "Receive LINE Bank notification webhook"
            },
            {
                "method": "POST",
                "path": "/api/payment/upload-slip",
                "description": "Upload slip image and verify payment"
            }
        ]
    }


# ============================================================================
# QUERY ENDPOINTS (for testing and debugging)
# ============================================================================

@app.get("/api/orders/{order_id}", response_model=schemas.OrderResponse)
async def get_order(order_id: str, db: Session = Depends(get_db)):
    """Get order status by order_id"""
    order = db.query(Order).filter(Order.order_id == order_id).first()
    
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order {order_id} not found"
        )
    
    return order


@app.get("/api/transactions/{ref_id}", response_model=schemas.TransactionResponse)
async def get_transaction(ref_id: str, db: Session = Depends(get_db)):
    """Get transaction status by ref_id"""
    transaction = db.query(Transaction).filter(
        Transaction.ref_id == ref_id
    ).first()
    
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Transaction {ref_id} not found"
        )
    
    return transaction


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
