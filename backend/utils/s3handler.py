import uuid
from pathlib import PurePosixPath, Path
from backend.configs import s3_client, S3_BUCKET_NAME, ALLOWED_EXTENSIONS
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

def allowed_file(filename):
    """Checks if the file is of the defined following extensions"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def upload_to_s3(file, folder):
    """Upload file to S3"""
    try:
        if not allowed_file(file.filename):
            return {'success': False, 'error': 'File type not allowed'}
        
        file_ext = Path(file.filename).suffix
        unique_filename = f"{uuid.uuid4()}{file_ext}"
        
        s3_key = str(PurePosixPath(folder) / unique_filename)
        
        # Upload to S3
        s3_client.upload_fileobj(
            file.stream,
            S3_BUCKET_NAME,
            s3_key,
            ExtraArgs={'ContentType': file.content_type}
        )
        
        s3_url = f"https://{S3_BUCKET_NAME}.s3.amazonaws.com/{s3_key}"
        
        return {
            'success': True,
            's3_url': s3_url,
            's3_key': s3_key
        }
    
    except NoCredentialsError:
        return {'success': False, 'error': 'AWS credentials not found'}
    except PartialCredentialsError:
        return {'success': False, 'error': 'Incomplete AWS credentials'}
    except Exception as e:
        return {'success': False, 'error': str(e)}
def delete_from_s3(s3_key):
    """Delete file from S3"""
    try:
        s3_client.delete_object(Bucket=S3_BUCKET_NAME, Key=s3_key)
        return {'success': True}
    except Exception as e:
        return {'success': False, 'error': str(e)}