include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../infra/networking"
}

inputs = {
  environment = "transversal"
}