import cv2
import numpy as np
from pyzbar.pyzbar import decode, ZBarSymbol
from PIL import Image
import io
from typing import Optional, Tuple, Dict
import logging
import re

try:
    import pytesseract
    TESSERACT_AVAILABLE = True
except ImportError:
    TESSERACT_AVAILABLE = False
    pytesseract = None

logger = logging.getLogger(__name__)


class SlipQRReader:
    """Read and extract QR code information from slip images"""
    
    @staticmethod
    def read_qr_from_image(image_bytes: bytes) -> Optional[str]:
        """
        Read QR code from image bytes
        
        Args:
            image_bytes: Image file bytes
        
        Returns:
            QR code data as string or None if not found
        """
        try:
            # Convert bytes to numpy array
            nparr = np.frombuffer(image_bytes, np.uint8)
            # Decode image
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if image is None:
                logger.error("Failed to decode image")
                return None
            
            # Try to decode QR codes
            qr_codes = decode(image)
            
            if qr_codes:
                # Return first QR code data
                return qr_codes[0].data.decode('utf-8')
            
            # If no QR found, try with preprocessing
            logger.info("No QR found on first attempt, trying with preprocessing")
            return SlipQRReader._read_qr_with_preprocessing(image)
            
        except Exception as e:
            logger.error(f"Error reading QR code: {str(e)}")
            return None
    
    @staticmethod
    def _read_qr_with_preprocessing(image: np.ndarray) -> Optional[str]:
        """
        Try to read QR code with image preprocessing
        Useful for low-quality or rotated images
        
        Args:
            image: OpenCV image array
        
        Returns:
            QR code data or None
        """
        try:
            # Convert to grayscale
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Apply contrast enhancement
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            enhanced = clahe.apply(gray)
            
            # Threshold
            _, thresh = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
            
            # Decode
            qr_codes = decode(thresh)
            if qr_codes:
                return qr_codes[0].data.decode('utf-8')
            
            # Try with inverted image
            inverted = cv2.bitwise_not(thresh)
            qr_codes = decode(inverted)
            if qr_codes:
                return qr_codes[0].data.decode('utf-8')
            
        except Exception as e:
            logger.error(f"Error in preprocessing: {str(e)}")
        
        return None
    
    @staticmethod
    def parse_promptpay_qr(qr_data: str) -> Dict:
        """
        Parse PromptPay QR code payload (EMVCo format)
        
        Args:
            qr_data: QR code data string
        
        Returns:
            Dictionary with parsed data (merchant_id, amount, etc)
        """
        result = {
            "merchant_id": None,
            "account_id": None,
            "amount": None,
            "currency": None,
            "merchant_name": None,
            "city": None,
            "raw_data": qr_data
        }
        
        try:
            # Parse EMVCo format TLV
            i = 0
            while i < len(qr_data) - 4:  # -4 for CRC
                tag = qr_data[i:i+2]
                length = int(qr_data[i+2:i+4])
                value = qr_data[i+4:i+4+length]
                
                # Tag 29: Merchant Account Information
                if tag == "29":
                    # Parse merchant info
                    result["merchant_id"] = value
                
                # Tag 54: Amount
                elif tag == "54":
                    try:
                        result["amount"] = float(value)
                    except ValueError:
                        pass
                
                # Tag 53: Currency
                elif tag == "53":
                    result["currency"] = value
                
                # Tag 59: Merchant Name
                elif tag == "59":
                    result["merchant_name"] = value
                
                # Tag 60: City
                elif tag == "60":
                    result["city"] = value
                
                i += 4 + length
            
        except Exception as e:
            logger.error(f"Error parsing QR data: {str(e)}")
        
        return result
    
    @staticmethod
    def extract_ref_id_from_image(image_bytes: bytes) -> Tuple[Optional[str], Optional[str]]:
        """
        Extract QR code and parse it to get reference ID and bank ID
        
        Args:
            image_bytes: Image file bytes
        
        Returns:
            Tuple of (ref_id, bank_id) or (None, None) if extraction fails
        """
        qr_data = SlipQRReader.read_qr_from_image(image_bytes)
        
        if not qr_data:
            logger.warning("No QR code found in image")
            return None, None
        
        # If it's PromptPay format, parse it
        if qr_data.startswith("00020"):  # EMVCo format indicator
            parsed = SlipQRReader.parse_promptpay_qr(qr_data)
            # Extract account ID as ref_id (could be phone or national ID)
            ref_id = parsed.get("account_id")
            bank_id = parsed.get("merchant_id")
        else:
            # For other QR formats, return raw data and try to extract bank info
            ref_id = qr_data
            bank_id = None
        
        return ref_id, bank_id
    
    @staticmethod
    def extract_text_from_image(image_bytes: bytes) -> Optional[str]:
        """
        Extract text from slip image using OCR (Tesseract)
        For backup verification when QR fails
        
        Args:
            image_bytes: Image file bytes
        
        Returns:
            Extracted text or None
        """
        if not TESSERACT_AVAILABLE:
            logger.warning("pytesseract not available - OCR skipped")
            return None
        
        try:
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if image is None:
                return None
            
            # Preprocess for better OCR
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Upscale image for better OCR
            scale_percent = 200
            width = int(gray.shape[1] * scale_percent / 100)
            height = int(gray.shape[0] * scale_percent / 100)
            upscaled = cv2.resize(gray, (width, height), interpolation=cv2.INTER_CUBIC)
            
            # Apply thresholding
            _, thresh = cv2.threshold(upscaled, 150, 255, cv2.THRESH_BINARY)
            
            # OCR
            text = pytesseract.image_to_string(thresh, lang='tha+eng')
            
            return text.strip() if text else None
            
        except Exception as e:
            logger.error(f"Error extracting text via OCR: {str(e)}")
            return None
    
    @staticmethod
    def extract_amount_from_ocr_text(text: str) -> Optional[float]:
        """
        Extract amount from OCR text (slip text)
        Patterns: "123.45", "123,45", "เงินเข้า 123.45"
        
        Args:
            text: OCR extracted text
        
        Returns:
            Amount or None
        """
        if not text:
            return None
        
        try:
            # Pattern 1: เงินเข้า X บาท
            match = re.search(r'เงินเข้า\s*(\d+[.,]\d+)\s*บาท', text)
            if match:
                return float(match.group(1).replace(',', '.'))
            
            # Pattern 2: จำนวน X บาท
            match = re.search(r'จำนวน\s*(\d+[.,]\d+)\s*บาท', text)
            if match:
                return float(match.group(1).replace(',', '.'))
            
            # Pattern 3: Just number with บาท
            match = re.search(r'(\d+[.,]\d+)\s*บาท', text)
            if match:
                return float(match.group(1).replace(',', '.'))
            
            # Pattern 4: ยอดเงิน X บาท
            match = re.search(r'ยอดเงิน\s*(\d+[.,]\d+)', text)
            if match:
                return float(match.group(1).replace(',', '.'))
        
        except Exception as e:
            logger.error(f"Error extracting amount from OCR: {str(e)}")
        
        return None
    
    @staticmethod
    def extract_ref_from_ocr_text(text: str) -> Optional[str]:
        """
        Extract transaction reference from OCR text
        Patterns: "Ref: ABC123", "Reference: ABC123", etc.
        
        Args:
            text: OCR extracted text
        
        Returns:
            Reference ID or None
        """
        if not text:
            return None
        
        try:
            # Pattern 1: Ref: ABC123
            match = re.search(r'Ref[erence]*\s*:?\s*([A-Za-z0-9]+)', text)
            if match:
                return match.group(1).strip()
            
            # Pattern 2: เลขอ้างอิง
            match = re.search(r'เลขอ้างอิง\s*([A-Za-z0-9]+)', text)
            if match:
                return match.group(1).strip()
            
            # Pattern 3: Transaction ID / Ref ID
            match = re.search(r'(?:Transaction|Transfer)\s*(?:ID|Ref)\s*:?\s*([A-Za-z0-9]+)', text, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        
        except Exception as e:
            logger.error(f"Error extracting ref from OCR: {str(e)}")
        
        return None
    
    @staticmethod
    def comprehensive_slip_analysis(image_bytes: bytes) -> Dict:
        """
        Comprehensive analysis of slip image (QR + OCR dual verification)
        
        Returns:
            {
                "qr_found": bool,
                "qr_data": str,
                "ocr_text": str,
                "extracted_data": {
                    "qr_amount": float,
                    "ocr_amount": float,
                    "qr_ref_id": str,
                    "ocr_ref_id": str,
                    "amounts_match": bool
                },
                "confidence": "high/medium/low"
            }
        """
        result = {
            "qr_found": False,
            "qr_data": None,
            "ocr_text": None,
            "extracted_data": {
                "qr_amount": None,
                "ocr_amount": None,
                "qr_ref_id": None,
                "ocr_ref_id": None,
                "amounts_match": False
            },
            "confidence": "low"
        }
        
        # Try QR first
        qr_data = SlipQRReader.read_qr_from_image(image_bytes)
        if qr_data:
            result["qr_found"] = True
            result["qr_data"] = qr_data
            parsed = SlipQRReader.parse_promptpay_qr(qr_data)
            result["extracted_data"]["qr_amount"] = parsed.get("amount")
            result["extracted_data"]["qr_ref_id"] = parsed.get("merchant_id")
        
        # Try OCR as backup/verification
        ocr_text = SlipQRReader.extract_text_from_image(image_bytes)
        if ocr_text:
            result["ocr_text"] = ocr_text
            result["extracted_data"]["ocr_amount"] = SlipQRReader.extract_amount_from_ocr_text(ocr_text)
            result["extracted_data"]["ocr_ref_id"] = SlipQRReader.extract_ref_from_ocr_text(ocr_text)
        
        # Calculate confidence
        qr_amount = result["extracted_data"]["qr_amount"]
        ocr_amount = result["extracted_data"]["ocr_amount"]
        
        if qr_amount and ocr_amount:
            if abs(qr_amount - ocr_amount) < 0.01:
                result["extracted_data"]["amounts_match"] = True
                result["confidence"] = "high"
            else:
                result["confidence"] = "medium"
        elif qr_amount or ocr_amount:
            result["confidence"] = "medium"
        
        return result
