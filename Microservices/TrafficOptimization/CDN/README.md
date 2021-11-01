### Network Traffic Optimization (CDN)

Why should we use Azure Content Delivery Network (CDN) ?

Azure CDN is a solution for rapidly delivering high-bandwidth content to users by caching their content at strategically placed physical nodes across the world. These edge servers are close to end-users in order to speed up the delivery of dynamic assets and minimize latency.

With Azure CDN dynamic site acceleration (DSA) optimization, the performance of web pages with dynamic content is measurably improved.
For our example, by default the selected DSA is Verizon offer corresponding to Azure PAYG plan, which uses some optimization technics:

Verizon network uses a combination of Anycast DNS, high-capacity support Point of Presence, and health checks, to determine the best gateways to best route data from the client to the origin.

See more about optimization technics used by Verizon network and Akamai network
https://docs.microsoft.com/en-us/azure/cdn/cdn-dynamic-site-acceleration#dsa-optimization-using-azure-cdn

Setup Content Delivery Network on azure services using terraform
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_endpoint#origin

### Hands on lab

- Az cli installed
- Terraform client installed
- Azure Container Registry provisioned

For this sample, we will use a Service Principal authentication with a Client Secret.

More information on [how to configure a Service Principal using a Client Secret can be found in this guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret).
First, you have to set up terraform env variables :

```yaml
export TF_VAR_env_deployment=dev
export TF_VAR_client_id=$AZURE_CLIENT_ID
export TF_VAR_client_secret=$AZURE_CLIENT_SECRET
export TF_VAR_subscription=$AZURE_SUBSCRIPTION
export TF_VAR_tenant=$AZURE_TENANT
export TF_VAR_container_registry_admin_pwd=$TF_ACR_PWD
```

**IMPORTANT**

    For Azure CDN Standard from Microsoft profiles, propagation usually completes in ten minutes.
    For Azure CDN Standard from Akamai profiles, propagation usually completes within one minute.
    For Azure CDN Standard from Verizon and Azure CDN Premium from Verizon profiles, propagation usually completes within 90 minutes.
