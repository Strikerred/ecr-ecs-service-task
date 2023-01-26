locals {
  repo_path = run_cmd("git", "rev-parse", "--show-toplevel")
}

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${local.repo_path}/services//strongswan-l2tp-vpn"
}

inputs = {
  environment  = "sandbox"
  aws_region   = "us-west-2"
  service_name = "strongswan-l2tp"
  department   = "connections"
  secret_name  = "sandbox/vpn"
  connections = [
    {
      container_host_port = 2004
      static_env_values = {
        S3_REPOPATH = "s3://secrets-s3.com/vpn"
        CONF        = "connection-a"
        SERVER_IP   = "212.200.236.46"
        TARGET_IP   = "1XX.1XX.XXX.1XX"
        VPN_SUBNET  = "1XX.1XX.0.0/16"
      }
    },
    {
      container_host_port = 2003
      static_env_values = {
        S3_REPOPATH = "s3://secrets-s3.com/vpn"
        CONF        = "connection-b"
        SERVER_IP   = "XXX.15X.XXX.1XX"
        TARGET_IP   = "10.1XX.XX1.XX"
        VPN_SUBNET  = "10.1XX.XX1.XX/32"
      }
    }
  ]
}
