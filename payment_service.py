import re
from typing import Tuple, Optional
import random


class PromptPayQRGenerator:
    """Generate PromptPay QR Code according to EMVCo standard"""
    
    # PromptPay merchant account tag (ID 29) with Thailand mobile prefix
    PROMPTPAY_MERCHANT_TAG = "29"
    PROMPTPAY_PAYLOAD_FORMAT_TYPE = "00"  # EMVCo format type
    PROMPTPAY_APP_ID = "A000000677010112"  # PromptPay app ID
    
    # Tags
    PAYLOAD_FORMAT_INDICATOR = "00"
    POINT_OF_INITIATION_METHOD = "01"
    MERCHANT_ACCOUNT_INFO = "29"
    AMOUNT = "54"
    CURRENCY_CODE = "5303"
    COUNTRY_CODE = "5A"
    CRC = "63"
    
    @staticmethod
    def encode_length_value(value: str) -> str:
        """Encode value with TLV (Tag-Length-Value) format"""
        length = len(value)
        return f"{length:02d}{value}"
    
    @staticmethod
    def generate_merchant_info(account_id: str) -> str:
        """Generate merchant account info for PromptPay"""
        # Tag 29: Merchant Account Information
        app_id_tlv = "00" + PromptPayQRGenerator.encode_length_value(PromptPayQRGenerator.PROMPTPAY_APP_ID)
        
        # Account ID (could be phone or national ID)
        account_tlv = "01" + PromptPayQRGenerator.encode_length_value(account_id)
        
        merchant_info = app_id_tlv + account_tlv
        return PromptPayQRGenerator.encode_length_value(merchant_info)
    
    @staticmethod
    def calculate_crc(data: str) -> str:
        """Calculate CRC-16/CCITT-FALSE checksum"""
        crc = 0xFFFF
        for char in data:
            crc ^= ord(char) << 8
            for _ in range(8):
                crc <<= 1
                if crc & 0x10000:
                    crc ^= 0x1021
                crc &= 0xFFFF
        return f"{crc:04X}"
    
    @staticmethod
    def generate_qr_payload(account_id: str, amount: float = None) -> str:
        """
        Generate PromptPay QR Code payload
        
        Args:
            account_id: PromptPay account (phone number or national ID)
            amount: Transaction amount in THB (optional for static QR)
        
        Returns:
            QR payload string in EMVCo format
        """
        # Payload Format Indicator
        qr = "000201"  # Static QR, format version 1
        
        # Point of Initiation Method (01 = static, 11 = dynamic)
        qr += "01020112"  # Dynamic QR
        
        # Merchant Account Information (Tag 29)
        merchant_info = PromptPayQRGenerator.generate_merchant_info(account_id)
        qr += "29" + merchant_info
        
        # Merchant Category Code (Tag 58)
        qr += "5807" + "4111"  # 4111 = Merchant
        
        # Transaction Currency (Tag 53) - THB = 764
        qr += "5303764"
        
        # Transaction Amount (Tag 54) - if provided
        if amount is not None:
            amount_str = f"{amount:.2f}"
            qr += "54" + PromptPayQRGenerator.encode_length_value(amount_str)
        
        # Country Code (Tag 58) - Thailand = TH
        qr += "5A0TH"
        
        # Merchant Name (Tag 59)
        merchant_name = "MERCHANT"
        qr += "59" + PromptPayQRGenerator.encode_length_value(merchant_name)
        
        # City (Tag 60)
        city = "BANGKOK"
        qr += "60" + PromptPayQRGenerator.encode_length_value(city)
        
        # CRC (Tag 63) - calculated without the CRC field itself
        crc = PromptPayQRGenerator.calculate_crc(qr + "6304")
        qr += "6304" + crc
        
        return qr
    
    @staticmethod
    def add_micro_transaction(amount: float) -> float:
        """
        Add random cent to amount for accurate matching
        Helps when multiple orders have same amount
        
        Args:
            amount: Base amount
        
        Returns:
            Modified amount with random decimal (0-99 cents)
        """
        cents = random.randint(1, 99)
        modified_amount = amount + (cents / 100.0)
        return round(modified_amount, 2)


def extract_amount_from_text(text: str) -> Optional[float]:
    """
    Extract amount from LINE notification text using regex
    Handles Thai text formats like "เงินเข้า 100.50 บาท"
    
    Args:
        text: Notification text
    
    Returns:
        Extracted amount or None
    """
    # Pattern for Thai text like "เงินเข้า 100.50 บาท"
    pattern = r"(\d+[.,]\d+|\d+)"
    matches = re.findall(pattern, text)
    
    if matches:
        # Get the last number (usually amount)
        amount_str = matches[-1].replace(",", ".")
        try:
            return float(amount_str)
        except ValueError:
            return None
    
    return None
