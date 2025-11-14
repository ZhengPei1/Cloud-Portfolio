
# DynamoDB
resource "aws_dynamodb_table" "counter_table" {
  name           = "CounterTable"
  billing_mode   = "PAY_PER_REQUEST" 

  hash_key       = "CounterType"

  attribute {
    name = "CounterType"
    type = "S" 
  }
}
