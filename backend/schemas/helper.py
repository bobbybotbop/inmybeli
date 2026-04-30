from marshmallow import fields, ValidationError
from backend.configs import MAX_FILE_SIZE, ALLOWED_EXTENSIONS

class ImageField(fields.Field):
    """Custom field for all the images to be sent through requests"""
    
    def __init__(self, allowed_extensions=ALLOWED_EXTENSIONS, max_size=MAX_FILE_SIZE, **kwargs):
        super().__init__(**kwargs)
        self.allowed_extensions = allowed_extensions
        self.max_size = max_size
    
    def _deserialize(self, value, attr, data, **kwargs):
        """Validation logic - runs automatically"""
        if not value:
            raise ValidationError('No file selected')
        
        # Check file extension
        filename = value.filename.lower()
        if not any(filename.endswith(ext) for ext in self.allowed_extensions):
            raise ValidationError(f'File type not allowed. Use: {", ".join(self.allowed_extensions)}')
        
        # Check file size
        value.seek(0, 2)
        size = value.tell()
        value.seek(0)
        
        if size > self.max_size:
            raise ValidationError(f'File is too large (max {self.max_size/1024/1024:.0f}MB)')
        
        if size == 0:
            raise ValidationError('File is empty')
        
        return value