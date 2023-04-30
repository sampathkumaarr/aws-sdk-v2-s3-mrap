provider "aws" {
  alias                    = "london"
  profile                  = "default"
  region                   = "eu-west-2"
  shared_credentials_files = ["C:\\Users\\techie\\.aws\\credentials"]
}

provider "aws" {
  alias                    = "ireland"
  profile                  = "default"
  region                   = "eu-west-1"
  shared_credentials_files = ["C:\\Users\\techie\\.aws\\credentials"]
}

resource "aws_iam_role" "replication" {
  name = "iam-role-replication"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "replicationRole",
        "Action" : "sts:AssumeRole"
        "Principal" : {
          "Service" : "s3.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_s3_bucket" "source-bucket" {
  provider = aws.london
  bucket   = var.source_bucket
}

resource "aws_s3_bucket_lifecycle_configuration" "source-bucket" {
  provider = aws.london
  bucket   = var.source_bucket

  rule {
    id = "life-cycle-rule-for-${var.source_bucket}"
    abort_incomplete_multipart_upload {
      days_after_initiation = 10
    }
    expiration {
      expired_object_delete_marker = true
    }
    filter {
      prefix = ""
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "source-bucket" {
  provider = aws.london
  bucket   = aws_s3_bucket.source-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "destination-bucket" {
  provider = aws.ireland
  bucket   = var.destination_bucket
}

resource "aws_s3_bucket_lifecycle_configuration" "destination-bucket" {
  bucket   = var.destination_bucket
  provider = aws.ireland

  rule {
    id = "life-cycle-rule-for-${var.destination_bucket}"
    abort_incomplete_multipart_upload {
      days_after_initiation = 10
    }
    expiration {
      expired_object_delete_marker = true
    }
    filter {
      prefix = ""
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "destination-bucket" {
  provider = aws.ireland
  bucket   = aws_s3_bucket.destination-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_policy" "replication" {
  name = "iam_policy-replication"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : ["s3:GetReplicationConfiguration",
        "s3:ListBucket"],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.source-bucket.arn,
          aws_s3_bucket.destination-bucket.arn
        ],
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        "Resource" : [
          "${aws_s3_bucket.source-bucket.arn}/*",
          "${aws_s3_bucket.destination-bucket.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        "Resource" : [
          "${aws_s3_bucket.source-bucket.arn}/*",
          "${aws_s3_bucket.destination-bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "iam-policy-attach-replication"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket_replication_configuration" "s3-bucket-repli-source-to-destination" {
  provider   = aws.london
  depends_on = [aws_s3_bucket_versioning.source-bucket]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.source-bucket.id

  rule {

    filter {
      prefix = ""
    }

    status = "Enabled"
    delete_marker_replication {
      status = "Enabled"
    }
    destination {
      bucket        = aws_s3_bucket.destination-bucket.arn
      storage_class = "STANDARD"
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        event_threshold {
          minutes = 15
        }
        status = "Enabled"
      }
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "s3-bucket-repli-destination-to-source" {
  provider   = aws.ireland
  depends_on = [aws_s3_bucket_versioning.destination-bucket]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.destination-bucket.id

  rule {

    filter {
      prefix = ""
    }

    status = "Enabled"
    delete_marker_replication {
      status = "Enabled"
    }
    destination {
      bucket        = aws_s3_bucket.source-bucket.arn
      storage_class = "STANDARD"
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        event_threshold {
          minutes = 15
        }
        status = "Enabled"
      }
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_s3control_multi_region_access_point" "my-mrap" {
  details {
    name = "my-multi-region-access-point"

    region {
      bucket = aws_s3_bucket.source-bucket.id
    }

    region {
      bucket = aws_s3_bucket.destination-bucket.id
    }
  }
}

resource "aws_s3control_multi_region_access_point_policy" "my-mrap-policy" {
  details {
    name = element(split(":", aws_s3control_multi_region_access_point.my-mrap.id), 1)
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "mrapPolicy",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : data.aws_caller_identity.current.account_id
          },
          "Action" : ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
          "Resource" : ["arn:${data.aws_partition.current.partition}:s3::${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3control_multi_region_access_point.my-mrap.alias}",
          "arn:${data.aws_partition.current.partition}:s3::${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3control_multi_region_access_point.my-mrap.alias}/object/*"]
        }
      ]
    })
  }
}

resource "aws_s3_bucket_policy" "mrap-bp-for-source-bucket" {
  provider = aws.london
  bucket   = aws_s3_bucket.source-bucket.id
  policy   = data.aws_iam_policy_document.mrap-pd-for-source-bucket.json
}

data "aws_iam_policy_document" "mrap-pd-for-source-bucket" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.source-bucket.arn,
      "${aws_s3_bucket.source-bucket.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:DataAccessPointArn"

      values = [
        "arn:${data.aws_partition.current.partition}:s3::${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3control_multi_region_access_point.my-mrap.alias}/object/*"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "mrap-bp-for-destination-bucket" {
  provider = aws.ireland
  bucket   = aws_s3_bucket.destination-bucket.id
  policy   = data.aws_iam_policy_document.mrap-pd-for-destination-bucket.json
}

data "aws_iam_policy_document" "mrap-pd-for-destination-bucket" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.destination-bucket.arn,
      "${aws_s3_bucket.destination-bucket.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:DataAccessPointArn"

      values = [
        "arn:${data.aws_partition.current.partition}:s3::${data.aws_caller_identity.current.account_id}:accesspoint/${aws_s3control_multi_region_access_point.my-mrap.alias}/object/*"
      ]
    }
  }
}
