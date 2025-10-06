# ------------------------------------------
# Gravitee AKS Cluster - DEV Deployment Script
# Author: Shaun Hardneck (THATLAZYADMIN)
# Last Updated: 2025-04
# ------------------------------------------

# === CONFIGURATION VARIABLES ===
location="EastUS"
resourceGroup="rg-dev-gravit-aks-eastus"
clusterName="aks-dev-eastus"
vnetName="vnet-dev-eastus"
vnetResourceGroup="rg-dev-vnet-eastus"
subnetName="snet-dev-aks-eastus"
dnsZoneResourceGroup="rg-dev-gravit-aks-eastus"
identityName="uami-aks-dev"
adminGroupObjectId="5c29836d-fd17-4f18-87b8-4dc4cbe907d4"
graviteeNodePoolName="grvtnp"
sysNodePoolName="sysnp"
internalIngressClassName="nginx-internal"
dnsRecordName="gravitee-internal"

# === STEP 0: Login and Set Subscription ===
az login
az account set --subscription "sub-core-development"

# === STEP 1: Lookup Resource IDs ===
vnetId=$(az network vnet show \
  --name "$vnetName" \
  --resource-group "$vnetResourceGroup" \
  --query id -o tsv)

subnetId=$(az network vnet subnet show \
  --vnet-name "$vnetName" \
  --name "$subnetName" \
  --resource-group "$vnetResourceGroup" \
  --query id -o tsv)

identityId=$(az identity show \
  --name "$identityName" \
  --resource-group "$resourceGroup" \
  --query id -o tsv)

# === STEP 2: Create AKS Cluster ===
az aks create \
  --name "$clusterName" \
  --resource-group "$resourceGroup" \
  --location "$location" \
  --enable-managed-identity \
  --assign-identity "$identityId" \
  --enable-private-cluster \
  --vnet-subnet-id "$subnetId" \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --service-cidr 192.168.1.0/24 \
  --dns-service-ip 192.168.1.2 \
  --load-balancer-sku standard \
  --enable-aad \
  --aad-admin-group-object-ids "$adminGroupObjectId" \
  --enable-azure-rbac \
  --private-dns-zone none \
  --enable-addons monitoring,http_application_routing \
  --nodepool-name "$sysNodePoolName" \
  --node-count 2 \
  --node-vm-size Standard_D2s_v5 \
  --generate-ssh-keys \
  --outbound-type userDefinedRouting \
  --yes

# === STEP 3: Add Gravitee Node Pool ===
az aks nodepool add \
  --cluster-name "$clusterName" \
  --resource-group "$resourceGroup" \
  --name "$graviteeNodePoolName" \
  --node-count 2 \
  --node-vm-size Standard_D4s_v5 \
  --mode User \
  --labels workload=gravitee \
  --node-taints gravitee=true:NoSchedule \
  --no-wait

# === STEP 4: Deploy Internal Ingress Controller ===
cat <<EOF | kubectl apply -f -
apiVersion: approuting.kubernetes.azure.com/v1alpha1
kind: NginxIngressController
metadata:
  name: $internalIngressClassName
spec:
  ingressClassName: $internalIngressClassName
  controllerNamePrefix: $internalIngressClassName
  loadBalancerAnnotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
EOF

# === STEP 5: Deploy Internal Ingress for Gravitee ===
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gravitee-test-ingress
  namespace: gravitee-system
spec:
  ingressClassName: $internalIngressClassName
  rules:
  - host: $dnsRecordName.devaks.privatelink.eastus.azmk8s.io
    http:
      paths:
      - backend:
          service:
            name: gravitee-gateway
            port:
              number: 8082
        path: /
        pathType: Prefix
EOF
