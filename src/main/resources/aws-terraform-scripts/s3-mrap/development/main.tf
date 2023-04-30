module "S3-bi-directional-repli-mrap" {
    source = "../../s3-mrap"
    source_bucket = "my-sample-bucket-london"
    destination_bucket = "my-sample-bucket-ireland"
}