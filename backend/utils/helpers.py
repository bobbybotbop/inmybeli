import secrets

def generate_token():
    """Generate random token"""
    return secrets.token_urlsafe(32)