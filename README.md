# Commands 
## Prereq:
```
export AWS_PAGER=

cd lambda_containers

aws iam create-role \
    --role-name lambda \
    --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy \
    --role-name lambda \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws ecr create-repository --repository-name base-image
aws ecr create-repository --repository-name os-image
aws ecr create-repository --repository-name non-aws-base-image

aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 164820026678.dkr.ecr.eu-central-1.amazonaws.com
```
## Example 1: 
```
cd base_image

docker build --platform linux/amd64 -t base-image:v1 .
docker tag base-image:v1 164820026678.dkr.ecr.eu-central-1.amazonaws.com/base-image:v1
docker push 164820026678.dkr.ecr.eu-central-1.amazonaws.com/base-image:v1

docker run --platform linux/amd64 -d -p 9001:8080 \
    164820026678.dkr.ecr.eu-central-1.amazonaws.com/base-image:v1
curl "http://localhost:9001/2015-03-31/functions/function/invocations" -d '{}'

aws lambda create-function \
    --function-name example1 \
    --package-type Image \
    --code ImageUri=164820026678.dkr.ecr.eu-central-1.amazonaws.com/base-image:v1 \
    --role arn:aws:iam::164820026678:role/lambda 
    
aws lambda invoke --function-name example1 output.json
``` 

## Example 2:
```
cd os_image

docker build --platform linux/amd64 -t os-image:v1 .
docker tag os-image:v1 164820026678.dkr.ecr.eu-central-1.amazonaws.com/os-image:v1
docker push 164820026678.dkr.ecr.eu-central-1.amazonaws.com/os-image:v1
 
docker run --platform linux/amd64 -d -p 9002:8080 \
    --entrypoint /usr/local/bin/aws-lambda-rie \
    164820026678.dkr.ecr.eu-central-1.amazonaws.com/os-image:v1 \
    ./main
curl "http://localhost:9002/2015-03-31/functions/function/invocations" -d '{"body":"Woitekku"}'

aws lambda create-function \
   --function-name example2 \
   --package-type Image \
   --code ImageUri=164820026678.dkr.ecr.eu-central-1.amazonaws.com/os-image:v1 \
   --role arn:aws:iam::164820026678:role/lambda 

aws lambda invoke --function-name example2 --payload $(echo '{"body": "Woitekku"}' | base64) output.json
```
## Example 3:
```
cd non_aws_base_image

docker build --platform linux/amd64 -t non-aws-base-image:v1 .
docker tag non_aws_base_image:v1 164820026678.dkr.ecr.eu-central-1.amazonaws.com/non-aws-base-image:v1
docker push 164820026678.dkr.ecr.eu-central-1.amazonaws.com/non-aws-base-image:v1

mkdir -p ~/.aws-lambda-rie && \
    curl -Lo ~/.aws-lambda-rie/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
    chmod +x ~/.aws-lambda-rie/aws-lambda-rie
    
docker run --platform linux/amd64 -d -v ~/.aws-lambda-rie:/aws-lambda -p 9003:8080 \
    --entrypoint /aws-lambda/aws-lambda-rie \
    164820026678.dkr.ecr.eu-central-1.amazonaws.com/non-aws-base-image:v1 \
    aws_lambda_ric lambda_function.LambdaFunction::Handler.process
curl "http://localhost:9003/2015-03-31/functions/function/invocations" -d '{}'

aws lambda create-function \
   --function-name example3 \
   --package-type Image \
   --code ImageUri=164820026678.dkr.ecr.eu-central-1.amazonaws.com/non-aws-base-image:v1 \
   --role arn:aws:iam::164820026678:role/lambda 
   
aws lambda invoke --function-name example3 output.json
```
