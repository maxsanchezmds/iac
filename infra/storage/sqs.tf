resource "aws_sqs_queue" "colas" {
  for_each = toset(var.microservicios)
  name     = "smartlogix-cola-${each.key}-${var.environment}"
}

resource "aws_sns_topic_subscription" "suscripciones" {
  for_each             = var.sns_event_subscriptions
  topic_arn            = aws_sns_topic.eventos.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.colas[each.key].arn
  raw_message_delivery = true
  filter_policy = jsonencode({
    evento = each.value
  })
}

resource "terraform_data" "sns_event_subscriptions_valid" {
  input = var.sns_event_subscriptions

  lifecycle {
    precondition {
      condition     = length(setsubtract(toset(keys(var.sns_event_subscriptions)), toset(var.microservicios))) == 0
      error_message = "sns_event_subscriptions solo puede referenciar microservicios declarados en microservicios."
    }

    precondition {
      condition     = alltrue([for events in values(var.sns_event_subscriptions) : length(events) > 0])
      error_message = "Cada suscripcion SNS debe declarar al menos un evento."
    }
  }
}

data "aws_iam_policy_document" "policies" {
  for_each = toset(var.microservicios)

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
  for_each  = toset(var.microservicios)
  queue_url = aws_sqs_queue.colas[each.key].url
  policy    = data.aws_iam_policy_document.policies[each.key].json
}
