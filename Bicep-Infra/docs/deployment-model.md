# Deployment model

## Subscription segmentation
- Lower environments: `dev`, `qa`, `uat` in lower subscription.
- Production environment: `prod` in production subscription.

## Naming standards
- Resource Group: `RG-AG-<environment>`

## Region standard
- `eastus` for all environments.

## Network/Security baseline
- Logic App Standard integrated with delegated subnet.
- Private endpoint created for each Logic App site.
- Public network access disabled at app level.
- Storage account locked with VNet ACLs.

## Secrets and configuration
- Key Vault is modeled as an existing resource and exposed to app settings with `KeyVaultUri`.
- Extend with managed identity access policy / RBAC assignments per organization policy.

## Monitoring and alerting
- App Insights is workspace-based (Log Analytics).
- Baseline metric alert added for `Http5xx` > 0.
