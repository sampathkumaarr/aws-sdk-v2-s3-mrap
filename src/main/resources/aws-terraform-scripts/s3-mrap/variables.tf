variable "source_bucket" {
    type = string
    description = "s3 source bucket name"
    default = "source-bucket-london"
}

variable "destination_bucket" {
    type = string
    description = "s3 destination bucket name"
    default = "destination-bucket-ireland"
}