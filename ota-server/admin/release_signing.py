"""Versioned Ed25519 release envelope for offline RedOne verification.

Signing key stays on the private publisher; distribute only the public key
to Lollipop and RedOne. The signed bytes are canonical JSON of the payload.
"""
import base64
import json
from pathlib import Path

def canonical_bytes(payload):
    return json.dumps(payload, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode('ascii')

def sign_release(payload, private_key_pem_path, key_id):
    from cryptography.hazmat.primitives import serialization
    key = serialization.load_pem_private_key(Path(private_key_pem_path).read_bytes(), password=None)
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
    if not isinstance(key, Ed25519PrivateKey):
        raise ValueError('Expected Ed25519 signing key')
    if not key_id or len(key_id) > 64:
        raise ValueError('Invalid signing key identifier')
    return {
        'signature_format': 'redone-ed25519-json-v1',
        'key_id': key_id,
        'payload': payload,
        'signature': base64.b64encode(key.sign(canonical_bytes(payload))).decode('ascii'),
    }

def verify_release(envelope, trusted_keys):
    from cryptography.exceptions import InvalidSignature
    if envelope.get('signature_format') != 'redone-ed25519-json-v1':
        return False
    key = trusted_keys.get(envelope.get('key_id'))
    if key is None:
        return False
    try:
        signature = base64.b64decode(envelope['signature'], validate=True)
        if len(signature) != 64:
            return False
        key.verify(signature, canonical_bytes(envelope['payload']))
        return True
    except (InvalidSignature, ValueError, KeyError, TypeError):
        return False
