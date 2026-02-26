# Bicep-Infra

Enterprise starter scaffold for **Azure Logic App Standard** using Bicep with reusable parameter-only deployments.

## Confirmed standards implemented
- **Subscription model**:
  - Lower environments (`dev`, `qa`, `uat`) deploy to a **lower subscription**.
  - `prod` deploys to a **production subscription**.
- **Resource group naming**: `RG-AG-<environment>`.
- **Region**: all environments standardized to `eastus`.
- **Sizing/HA baseline**: basic baseline (`WS1`, 1 worker) for all envs.
- **Networking**: VNet integration + Private Endpoint pattern.
- **Secrets**: Key Vault reference pattern.
- **Monitoring**: App Insights workspace-based + metric alert baseline.
- **Workflow source strategy**: monorepo.

## Folder structure

```text
Bicep-Infra/
├── main.bicep
├── main.parameters.json
├── modules/
│   └── logic-app-standard.bicep
├── environments/
│   ├── dev/main.parameters.json
│   ├── qa/main.parameters.json
│   ├── uat/main.parameters.json
│   └── prod/main.parameters.json
├── workflows/
│   └── sample.workflow.json
├── docs/
│   └── deployment-model.md
└── .github/workflows/
    └── validate-bicep.yml
```

## Scale model (easy to add more Logic Apps)
Add new entries under `logicApps` array in any environment parameter file:

```json
"logicApps": {
  "value": [
    {
      "name": "la-std-qa-orders",
      "appServicePlanName": "asp-la-qa-shared",
      "storageAccountName": "stlaqashared01",
      "appInsightsName": "appi-la-qa-orders",
      "skuName": "WS1",
      "workerSize": 0,
      "workerCount": 1
    },
    {
      "name": "la-std-qa-billing",
      "appServicePlanName": "asp-la-qa-shared",
      "storageAccountName": "stlaqabilling01",
      "appInsightsName": "appi-la-qa-billing",
      "skuName": "WS1",
      "workerSize": 0,
      "workerCount": 1
    }
  ]
}
```

## Deployment examples

Lower subscription (dev/qa/uat):
```bash
az account set --subscription <LOWER_SUBSCRIPTION_ID>
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters @environments/qa/main.parameters.json
```

Production subscription:
```bash
az account set --subscription <PROD_SUBSCRIPTION_ID>
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters @environments/prod/main.parameters.json
```

## Validation
```bash
az bicep build --file main.bicep
```
