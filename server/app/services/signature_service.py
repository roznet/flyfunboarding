"""
Signature service for cryptographic operations.

Mirrors PHP Signature.php behavior:
- RSA key pair management (load/create)
- Secret-based hashing
- RSA signing/verification
- Combined signature digests
"""
import hashlib
import base64
from pathlib import Path
from typing import Optional

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.backends import default_backend

from app.config import settings


class SignatureService:
    """
    Cryptographic signature service matching PHP Signature class.
    
    Handles:
    - RSA key pair loading/creation
    - Secret-based hashing (SHA256)
    - RSA signing/verification (SHA256)
    - Combined signature digests
    """

    def __init__(self, base_name: str):
        """
        Initialize signature service for a given base name.
        
        Args:
            base_name: Base name for key files (e.g., airline apple_identifier)
        """
        self.base_name = base_name
        self.secret = settings.SECRET
        self.use_public_key_signature = settings.USE_PUBLIC_KEY_SIGNATURE
        
        keys_path = Path(settings.KEYS_PATH)
        self.private_key_path = keys_path / f"{base_name}.pem"
        self.public_key_path = keys_path / f"{base_name}.pub"
        
        # Load keys if they exist
        self.private_key: Optional[rsa.RSAPrivateKey] = None
        self.public_key: Optional[rsa.RSAPublicKey] = None
        
        if self.private_key_path.exists():
            self._load_private_key()
        
        if self.public_key_path.exists():
            self._load_public_key()

    def _load_private_key(self) -> None:
        """Load private key from PEM file."""
        try:
            with open(self.private_key_path, "rb") as f:
                private_key_data = f.read()
            self.private_key = serialization.load_pem_private_key(
                private_key_data,
                password=None,
                backend=default_backend()
            )
        except Exception:
            self.private_key = None

    def _load_public_key(self) -> None:
        """Load public key from PEM file."""
        try:
            with open(self.public_key_path, "rb") as f:
                public_key_data = f.read()
            self.public_key = serialization.load_pem_public_key(
                public_key_data,
                backend=default_backend()
            )
        except Exception:
            self.public_key = None

    def can_sign(self) -> bool:
        """Check if private key is available for signing."""
        return self.private_key is not None

    def can_verify(self) -> bool:
        """Check if public key is available for verification."""
        return self.public_key is not None

    @classmethod
    def retrieve_or_create(cls, base_name: str) -> "SignatureService":
        """
        Retrieve existing signature service or create new key pair.
        
        Args:
            base_name: Base name for key files
            
        Returns:
            SignatureService instance
        """
        keys_path = Path(settings.KEYS_PATH)
        private_key_path = keys_path / f"{base_name}.pem"
        public_key_path = keys_path / f"{base_name}.pub"
        
        if private_key_path.exists() and public_key_path.exists():
            return cls(base_name)
        else:
            return cls.create(base_name)

    @classmethod
    def create(cls, base_name: Optional[str] = None) -> "SignatureService":
        """
        Create new RSA key pair and save to files.
        
        Args:
            base_name: Optional base name. If None, generates from public key hash.
            
        Returns:
            SignatureService instance
        """
        # Generate RSA key pair (2048 bits, matching PHP)
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
            backend=default_backend()
        )
        public_key = private_key.public_key()
        
        # Serialize keys
        private_key_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        
        public_key_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        # Determine base name
        if base_name is None:
            # Hash public key to generate base name (matching PHP: hash('sha1', $publicKey))
            public_key_str = public_key_pem.decode('utf-8')
            base_name = hashlib.sha1(public_key_str.encode()).hexdigest()
        
        # Save keys
        keys_path = Path(settings.KEYS_PATH)
        keys_path.mkdir(parents=True, exist_ok=True)
        
        private_key_path = keys_path / f"{base_name}.pem"
        public_key_path = keys_path / f"{base_name}.pub"
        
        with open(private_key_path, "wb") as f:
            f.write(private_key_pem)
        
        with open(public_key_path, "wb") as f:
            f.write(public_key_pem)
        
        # Return new instance (will load the keys we just saved)
        return cls(base_name)

    def export_public_keys(self) -> dict[str, str]:
        """
        Export public key information.
        
        Returns:
            Dictionary with 'baseName' and 'publicKey' (PEM format as string)
        """
        if not self.public_key:
            return {
                'baseName': self.base_name,
                'publicKey': ''
            }
        
        public_key_pem = self.public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        return {
            'baseName': self.base_name,
            'publicKey': public_key_pem.decode('utf-8')
        }

    def signature_digest(self, data: str) -> dict[str, str]:
        """
        Create signature digest (hash + optional RSA signature).
        
        Matches PHP: signatureDigest()
        
        Args:
            data: Data to sign
            
        Returns:
            Dictionary with 'hash' and optionally 'signature'
        """
        digest: dict[str, str] = {
            'hash': self.secret_hash(data)
        }
        
        if self.use_public_key_signature and self.can_sign():
            signature = self._sign(data)
            if signature:
                digest['signature'] = signature
        
        return digest

    def verify_signature_digest(self, data: str, digest: dict) -> bool:
        """
        Verify signature digest.
        
        Matches PHP: verifySignatureDigest()
        
        Args:
            data: Original data
            digest: Dictionary with 'hash' and optionally 'signature'
            
        Returns:
            True if verification succeeds
        """
        if 'hash' not in digest:
            return False
        
        # Verify secret hash
        if digest['hash'] != self.secret_hash(data):
            return False
        
        # Verify RSA signature if present
        if 'signature' in digest:
            return self._verify(data, digest['signature'])
        
        return True

    def _sign(self, data: str) -> Optional[str]:
        """
        Sign data with RSA private key.
        
        Matches PHP: sign() using OPENSSL_ALGO_SHA256
        
        Args:
            data: Data to sign
            
        Returns:
            Base64-encoded signature, or None if signing fails
        """
        if not self.can_sign():
            return None
        
        try:
            # Sign with SHA256 (matching PHP OPENSSL_ALGO_SHA256)
            signature_bytes = self.private_key.sign(
                data.encode('utf-8'),
                padding.PKCS1v15(),
                hashes.SHA256()
            )
            # Base64 encode (matching PHP base64_encode)
            return base64.b64encode(signature_bytes).decode('utf-8')
        except Exception:
            return None

    def _verify(self, data: str, signature: str) -> bool:
        """
        Verify RSA signature.
        
        Matches PHP: verify() using OPENSSL_ALGO_SHA256
        
        Args:
            data: Original data
            signature: Base64-encoded signature
            
        Returns:
            True if signature is valid
        """
        if not self.can_verify():
            return False
        
        try:
            # Decode base64 (matching PHP base64_decode)
            signature_bytes = base64.b64decode(signature)
            
            # Verify with SHA256 (matching PHP OPENSSL_ALGO_SHA256)
            self.public_key.verify(
                signature_bytes,
                data.encode('utf-8'),
                padding.PKCS1v15(),
                hashes.SHA256()
            )
            return True
        except Exception:
            return False

    def secret_hash(self, data: str) -> str:
        """
        Create secret-based hash.
        
        Matches PHP: secretHash() using SHA256
        
        Args:
            data: Data to hash
            
        Returns:
            SHA256 hex digest
        """
        # Concatenate secret + data (matching PHP: $this->secret . $data)
        data_to_hash = self.secret + data
        # SHA256 hash (matching PHP: hash('sha256', $dataToHash))
        return hashlib.sha256(data_to_hash.encode('utf-8')).hexdigest()

    def verify_secret_hash(self, data: str, hash_value: str) -> bool:
        """
        Verify secret-based hash.
        
        Matches PHP: verifySecretHash()
        
        Args:
            data: Original data
            hash_value: Expected hash
            
        Returns:
            True if hash matches
        """
        return self.secret_hash(data) == hash_value

    def digest(self, data: str) -> dict[str, Optional[str]]:
        """
        Create full digest with both sign and hash.
        
        Matches PHP: digest()
        
        Args:
            data: Data to digest
            
        Returns:
            Dictionary with 'sign' and 'hash'
        """
        return {
            'sign': self._sign(data),
            'hash': self.secret_hash(data)
        }

