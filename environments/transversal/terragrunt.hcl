include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infra//transversal"
}

inputs = {
  environment = "transversal"
}
