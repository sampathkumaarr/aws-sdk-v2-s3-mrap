module "S3-bi-directional-repli-mrap" {
    source = ".."
    source_bucket = "my-sample-bucket-london"
    destination_bucket = "my-sample-bucket-ireland"
}