variable "private_key" {
  type    = string
  validation {
    condition     = length(var.private_key) > 0
    error_message = "you must enter the private key path"
  }
}

variable "public_key" {
  type    = string
  validation {
    condition     = length(var.public_key) > 0
    error_message = "you must enter the public key path"
  }
}