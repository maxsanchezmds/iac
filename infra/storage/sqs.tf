
resource "aws_sqs_queue" "colas" {
  for_each = toset(local.microservicios)
  name = "smartlogix-cola-${each.key}-${var.environment}"
}

resource "aws_sns_topic_subscription" "suscripciones" {
  for_each = toset(local.microservicios)
  topic_arn = aws_sns_topic.eventos.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.colas[each.key].arn
}

data "aws_iam_policy_document" "policies" {
  for_each = toset(local.microservicios)

  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.colas[each.key].arn]
    
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.eventos.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "politicas" {
  for_each  = toset(local.microservicios)
  queue_url = aws_sqs_queue.colas[each.key].url
  policy    = data.aws_iam_policy_document.policies[each.key].json
}