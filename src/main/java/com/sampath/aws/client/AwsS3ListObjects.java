package com.sampath.aws.client;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3AsyncClient;
import software.amazon.awssdk.services.s3.model.ListObjectsRequest;
import software.amazon.awssdk.services.s3.model.ListObjectsResponse;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.model.S3Object;
import java.util.List;
import java.util.concurrent.ExecutionException;

import static com.sampath.aws.client.Constants.ACCOUNT;

public class AwsS3ListObjects {


    public static void main(String[] args) {

        S3AsyncClient s3AsyncClientEuWest1 = AwsS3AsyncClientUtil.createS3AsyncClientForRegion.apply(Region.EU_WEST_1);
        //listBucketObjects(s3AsyncClientEuWest1, "my-sample-bucket-ireland");

        //S3AsyncClient s3AsyncClientEuWest2 = AwsS3AsyncClientUtil.createS3AsyncClientForRegion.apply(Region.EU_WEST_2);
        //listBucketObjects(s3AsyncClientEuWest2, "my-sample-bucket-london");

        /** AWS S3 Multi-Region-Access-Point do not belong to any REGION, but still we need to set REGION (any REGION is fine)
         * Also update the "ACCOUNT" variable value to your AWS Account ID.
         * Make sure to do AWS authentication before running this class.
        */
        listBucketObjects(s3AsyncClientEuWest1, "arn:aws:s3::" + ACCOUNT + ":accesspoint/me1ozfm64wsn3.mrap");
    }
    public static void listBucketObjects(S3AsyncClient s3, String bucketName ) {

        try {
            ListObjectsRequest listObjects = ListObjectsRequest
                    .builder()
                    .bucket(bucketName)
                    .build();

            ListObjectsResponse res = s3.listObjects(listObjects).get();
            List<S3Object> objects = res.contents();
            for (S3Object myValue : objects) {
                System.out.println("******** The name of the key is " + myValue.key());
                System.out.println("******** The owner is " + myValue.owner());
            }

        } catch (S3Exception e) {
            System.err.println(e.awsErrorDetails().errorMessage());
            System.exit(1);
        } catch (ExecutionException e) {
            throw new RuntimeException(e);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }
    }
}
