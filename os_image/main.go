package main

import (
	"context"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	responseMessage := "Hello " + event.Body + "!"

	response := events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       "\"" + responseMessage + "\"",
	}

	return response, nil
}

func main() {
	lambda.Start(handler)
}
