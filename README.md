# Let's Encrypt for Ubiquiti UbiOS firmwares

## Overview

This should work on UbiOS based firmware versions 1.7.0 onwards. This includes:

* UniFi Dream Machine
* UniFi Dream Machine Pro

It does *NOT* support the Cloud Key Gen 2 or Gen 2 Plus as they do not ship with Docker (podman) support.

This script supports issuing LetsEncrypt certificates via DNS using [Lego](https://go-acme.github.io/lego/).

Out of the box, it has tested support for select [DNS providers](#dns-providers) but with little work you could get it working with any of the supported [Lego DNS Providers](https://go-acme.github.io/lego/dns/).

## Installation

1. SSH into the UDM/P (assuming it's on 192.168.1.254).

    ```sh
    ssh root@192.168.1.254
    ```
    
2. Download and run the installation script. 

    ```sh
    curl -LSsf https://raw.githubusercontent.com/diogosalazar/udm-le/main/udm-le/install-udm-le.sh | sh
    ```
    
	* For the UDM, UDM Pro, UDM-SE, and UXG Pro, the script will be installed to `/mnt/data/udm-le`. 
	* For the UDR, the script will be installed to `/data/udm-le`.
	* The installation will also link the script directory to `/etc/udm-le`, which will be used for configuration below.

## Persistance

On firmware updates or just reboots, the cron file (`/etc/cron.d/udm-le`) gets removed, so if you'd like for this to persist, I suggest so you install boostchicken's [on-boot-script](https://github.com/boostchicken/udm-utilities/tree/master/on-boot-script) package.

This script is setup such that if it determines that on-boot-script is enabled, it will set up an additional script at `/mnt/data/on_boot.d/99-udm-le.sh` which will attempt certificate renewal shortly after a reboot (and subsequently set the cron back up again).

## DNS Providers

### AWS Route53

AWS Route53 DNS challenge can use configuration and authentication values easily through shared credentials and configuration files [as described here](https://go-acme.github.io/lego/dns/route53/). This script will check for and include these files during the initial certificate generation and subsequent renewals. Ensure that `route53` is set for `DNS_PROVIDER` in `udm-le.env`, create a new directory called `.secrets` in `/mnt/data/udm-le` and add `credentials` and `config` files as required for your authentication. See the [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) for more information. Currently only the `default` profile is supported.

### Azure DNS

If not done already, [delegate a domain to an Azure DNS zone](https://docs.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns).

Assuming the DNS zone lives in subscription `00000000-0000-0000-0000-000000000000` and resource group `udm-le`, with help of the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) provision an identity to manage the DNS zone by running:

```bash
# login
az login

# create a service principal with contributor (default) permissions over the godns resource group
az ad sp create-for-rbac --name godns --scope /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/udm-le --role contributor
```

### Cloudflare

In your Cloudflare account settings, create an API token with the following permissions:

* Zone > Zone > Read
* Zone > DNS > Edit

Once you have your token generated, add the value to `udm-le.env`.

### Digital Ocean

If you use DigitalOcean as your DNS provider, set your `DNS_PROVIDER` to `digitalocean` and configure your `DO_AUTH_TOKEN`. Note: Quoting your `DO_AUTH_TOKEN` seems to cause issues with Lego.

### DuckDNS

If you use DuckDNS as your DNS provider, set your `DNS_PROVIDER` to `duckdns` and configure your `DUCKDNS_TOKEN`.

### Google Cloud DNS

GCP Cloud DNS can be configured by establishing a service account with the role [`roles/dns.admin`](https://cloud.google.com/iam/docs/understanding-roles#dns-roles) and exporting a [service account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) for that service account. Ensure that `gcloud` is set for `DNS_PROVIDER` in `udm-le.env`, and `GCE_SERVICE_ACCOUNT_FILE` references the path to the service account key (e.g. `./root/.secrets/my_service_account.json`) . Create a new directory called `.secrets` in `/mnt/data/udm-le` and add the service account file.

The CLI will output a JSON object. Use the printed properties to initialize your configuration in [udm-le.env](./udm-le.env).

Note:
- The `password` value is a secret and as such you may want to omit it from [udm-le.env](./udm-le.env) and instead set it in a `.secrets/client-secret.txt` file
- The `appId` value is what [Lego](https://go-acme.github.io/lego/) calls a client id
