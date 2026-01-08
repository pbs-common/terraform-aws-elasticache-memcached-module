package test

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testMemcached(t *testing.T, variant string) {
	t.Parallel()

	terraformDir := fmt.Sprintf("../examples/%s", variant)

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		LockTimeout:  "5m",
		Upgrade:      true,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	name := terraform.Output(t, terraformOptions, "name")
	arn := terraform.Output(t, terraformOptions, "arn")
	SGIDs := terraform.Output(t, terraformOptions, "sg_ids")
	clusterAddress := terraform.Output(t, terraformOptions, "cluster_address")
	configurationEndpoint := terraform.Output(t, terraformOptions, "configuration_endpoint")

	accountID := getAWSAccountID(t)
	region := getAWSRegion(t)

	expectedName := fmt.Sprintf("ex-tf-memcached-%s", variant)
	expectedARN := fmt.Sprintf("arn:aws:elasticache:%s:%s:cluster:%s", region, accountID, expectedName)
	expectedPartialClusterAddress := expectedName
	expectedPartialConfigurationEndpoint := expectedName

	assert.Equal(t, expectedName, name)
	assert.Equal(t, expectedARN, arn)
	assert.NotNil(t, SGIDs)
	assert.Contains(t, clusterAddress, expectedPartialClusterAddress)
	assert.Contains(t, configurationEndpoint, expectedPartialConfigurationEndpoint)

	if variant == "lambda" {
		expectedLambdaName := expectedName
		lambdaName := terraform.Output(t, terraformOptions, "lambda_name")
		assert.Equal(t, expectedLambdaName, lambdaName)

		sess, err := session.NewSessionWithOptions(session.Options{
			SharedConfigState: session.SharedConfigEnable,
		})
		if err != nil {
			t.Fatalf("Failed to create AWS session: %v", err)
		}

		lambdaSvc := lambda.New(sess)

		invokeOutput, err := lambdaSvc.Invoke(&lambda.InvokeInput{
			FunctionName: &lambdaName,
		})

		if err != nil {
			t.Fatal(err)
		}

		var lambdaResp struct {
			Result string `json:"result"`
			Error  string `json:"error"`
		}

		err = json.Unmarshal(invokeOutput.Payload, &lambdaResp)

		if err != nil {
			t.Fatal(err)
		}

		if *invokeOutput.StatusCode != 200 {
			t.Logf("lambda response: %v", lambdaResp)
			t.Fatalf("Expected status code 200, got %d", *invokeOutput.StatusCode)
		}

		if lambdaResp.Result == "failure" {
			t.Logf("lambda response: %v", lambdaResp)
			t.Fatalf("Expected result 'success', got 'failure'")
		}
	}
}