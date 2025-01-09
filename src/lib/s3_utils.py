import os
import boto3
from PIL import Image
from io import BytesIO
from typing import List, Tuple

class S3ImageHandler:
    def __init__(self, bucket_name: str):
        self.s3 = boto3.client('s3')
        self.bucket = bucket_name

    def upload_student_images(self, student_id: str, image_files: dict[str, str]):
        """
        Upload student images to S3
        image_files: dict with keys 'front', 'left', 'right', 'tiltUp', 'tiltDown'
        """
        uploaded_urls = {}
        
        for angle, file_path in image_files.items():
            # Preprocess image
            processed_image = self._preprocess_image(file_path)
            
            # Generate S3 key
            key = f"students/{student_id}/{angle}.jpg"
            
            # Upload to S3
            buffer = BytesIO()
            processed_image.save(buffer, format="JPEG")
            buffer.seek(0)
            
            self.s3.upload_fileobj(buffer, self.bucket, key)
            
            # Generate URL
            uploaded_urls[angle] = f"s3://{self.bucket}/{key}"
        
        return uploaded_urls

    def download_student_images(self, student_id: str, local_dir: str):
        """Download all images for a student to local directory"""
        # Create student directory if it doesn't exist
        os.makedirs(local_dir, exist_ok=True)
        
        # List all objects for the student
        prefix = f"students/{student_id}/"
        response = self.s3.list_objects_v2(Bucket=self.bucket, Prefix=prefix)
        
        downloaded_files = []
        for obj in response.get('Contents', []):
            # Get filename from key
            filename = os.path.basename(obj['Key'])
            local_path = os.path.join(local_dir, filename)
            
            # Download file
            self.s3.download_file(self.bucket, obj['Key'], local_path)
            downloaded_files.append(local_path)
        
        return downloaded_files

    def cleanup_local_files(self, local_dir: str):
        """Remove downloaded files after processing"""
        if os.path.exists(local_dir):
            for file in os.listdir(local_dir):
                os.remove(os.path.join(local_dir, file))
            os.rmdir(local_dir)

    def _preprocess_image(self, image_path: str) -> Image:
        """Preprocess image before upload"""
        with Image.open(image_path) as img:
            # Convert to RGB if necessary
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Resize to more appropriate size for facial recognition
            # 720p is usually sufficient
            target_size = (1280, 720)
            img = img.resize(target_size, Image.Resampling.LANCZOS)
            
            return img