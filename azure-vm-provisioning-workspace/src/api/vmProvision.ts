import express, { Request, Response } from 'express';
import { getAvailableSkus, getAvailableImages, validateVmName } from '../utils/azureHelpers';
import { VmRequest, VmResponse } from '../types';

const router = express.Router();

// Endpoint to fetch available SKUs
router.get('/skus', async (req: Request, res: Response) => {
    try {
        const skus = await getAvailableSkus();
        res.status(200).json(skus);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch SKUs' });
    }
});

// Endpoint to fetch available images
router.get('/images', async (req: Request, res: Response) => {
    try {
        const images = await getAvailableImages();
        res.status(200).json(images);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch images' });
    }
});

// Endpoint to provision a new VM
router.post('/create', async (req: Request, res: Response) => {
    const vmRequest: VmRequest = req.body;

    // Validate VM name
    const isValidName = validateVmName(vmRequest.name);
    if (!isValidName) {
        return res.status(400).json({ error: 'Invalid VM name' });
    }

    try {
        // Logic to provision the VM goes here
        // This would typically involve calling Azure SDK or REST API

        const vmResponse: VmResponse = {
            id: 'vm-id', // Replace with actual VM ID after provisioning
            name: vmRequest.name,
            status: 'Provisioning',
        };

        res.status(201).json(vmResponse);
    } catch (error) {
        res.status(500).json({ error: 'Failed to create VM' });
    }
});

export default router;