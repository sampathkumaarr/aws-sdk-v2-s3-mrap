package com.sampath.aws.client;

import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
import software.amazon.awssdk.core.client.config.ClientOverrideConfiguration;
import software.amazon.awssdk.core.internal.retry.SdkDefaultRetrySetting;
import software.amazon.awssdk.core.retry.RetryPolicy;
import software.amazon.awssdk.core.retry.backoff.BackoffStrategy;
import software.amazon.awssdk.core.retry.backoff.FullJitterBackoffStrategy;
import software.amazon.awssdk.core.retry.conditions.RetryCondition;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3AsyncClient;
import java.time.Duration;
import java.util.function.Function;

import static com.sampath.aws.client.Constants.PROFILE_NAME;

public class AwsS3AsyncClientUtil {

    public static final Function<Region, S3AsyncClient> createS3AsyncClientForRegion = region -> {
        BackoffStrategy backoffStrategy = FullJitterBackoffStrategy.builder()
                .baseDelay(Duration.ofMillis(100))
                .maxBackoffTime(SdkDefaultRetrySetting.MAX_BACKOFF)
                .build();
        ClientOverrideConfiguration clientOverrideConfiguration = ClientOverrideConfiguration
                .builder()
                .retryPolicy(RetryPolicy.builder()
                        .retryCondition(RetryCondition.defaultRetryCondition())
                        .numRetries(1)
                        .backoffStrategy(backoffStrategy)
                        .throttlingBackoffStrategy(BackoffStrategy.defaultThrottlingStrategy())
                        .build()).build();
        return S3AsyncClient
                .builder()
                .overrideConfiguration(clientOverrideConfiguration)
                .region(region)
                .credentialsProvider(ProfileCredentialsProvider.create(PROFILE_NAME))
                .build();
    };

}
