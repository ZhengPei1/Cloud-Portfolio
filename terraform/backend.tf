# API Gateway

resource "aws_apigatewayv2_api" "http_api" {
  name          = var.API_NAME
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_visitor_counter" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
  description               = "Lambda visitor_counter"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version                    = "2.0"
}

resource "aws_apigatewayv2_route" "get" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.lambda_visitor_counter.id}"
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  
  # Scope permission to the specific stage and method for improved security
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/${aws_apigatewayv2_stage.api_stage.name}/GET/*"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "Production"
  auto_deploy = true     
}

# Lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = var.LAMBDA_EXEC_ROLE_NAME
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "lambda_CWDynamoDB_policy" {
  statement {
    sid    = "ReadWriteTable"
    effect = "Allow"

    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]

    # Restrict permissions to the specific DynamoDB table being created
    resources = [aws_dynamodb_table.counter_table.arn]
  }

  statement {
    sid    = "CreateLogGroup"
    effect = "Allow"

    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${var.REGION}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    # Restrict logging permissions to the function's own log group
    resources = ["arn:aws:logs:${var.REGION}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.LAMBDA_FUNC_NAME}:*"]
  }
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "DynamoDBRWAndCWWrite"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda_CWDynamoDB_policy.json
}

# Attach Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_CWDynamoDB_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}


data "archive_file" "visitor_counter_zip" {
  type        = "zip"
  source_file = "../Lambda/get_and_inc_visitor_count.py" 
  output_path = "get_and_inc_visitor_count.zip"         
}

resource "aws_lambda_function" "visitor_counter" {
  filename         = data.archive_file.visitor_counter_zip.output_path
  source_code_hash = data.archive_file.visitor_counter_zip.output_base64sha256
  function_name    = var.LAMBDA_FUNC_NAME
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "get_and_inc_visitor_count.lambda_handler" 
  runtime          = "python3.12" # Using a more stable runtime. python3.13 is still in preview.
}

