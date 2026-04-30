import boto3
from pathlib import Path
from dotenv import load_dotenv
import os

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)
# S3 Client Configuration
s3_client = boto3.client(
    's3',
    region_name=os.getenv('AWS_REGION', 'us-east-2'),
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY'),
    aws_secret_access_key=os.getenv('AWS_SECRET_KEY')
)

# S3 Bucket
S3_BUCKET_NAME = os.getenv('AWS_S3_BUCKET_NAME', 'appdev-inmybeli')
MAX_FILE_SIZE = 50 * 1024 * 1024
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'svg'}

# Default image
DEFAULT_PFP = "https://appdev-inmybeli.s3.us-east-2.amazonaws.com/assets/blankpfp.png"