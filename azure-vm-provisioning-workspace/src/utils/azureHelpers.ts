import { ResourceManagementClient } from '@azure/arm-resources';
import { ComputeManagementClient } from '@azure/arm-compute';
import { DefaultAzureCredential } from '@azure/identity';

const subscriptionId = process.env.AZURE_SUBSCRIPTION_ID;

const credential = new DefaultAzureCredential();
const resourceClient = new ResourceManagementClient(credential, subscriptionId);
const computeClient = new ComputeManagementClient(credential, subscriptionId);

export const fetchAvailableSkus = async (location: string) => {
    const skus = await computeClient.virtualMachineSizes.list(location);
    return skus;
};

export const fetchImages = async (location: string) => {
    const images = await computeClient.images.list(location);
    return images;
};

export const validateVmName = async (resourceGroupName: string, vmName: string) => {
    const vmExists = await computeClient.virtualMachines.get(resourceGroupName, vmName);
    return !vmExists;
};