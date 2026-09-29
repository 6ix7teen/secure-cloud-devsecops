output "bucket_name" {
  description = "The globally unique name of the secure bucket"
  value       = aws_s3_bucket.secure_storage.id
}

output "bucket_arn" {
  description = "The ARN of the secure bucket"
  value       = aws_s3_bucket.secure_storage.arn
}
