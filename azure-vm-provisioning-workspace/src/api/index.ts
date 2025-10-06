import express from 'express';
import { createVM, getAvailableSKUs, getAvailableImages, validateVMName } from './vmProvision';

const router = express.Router();

// Route to create a new VM
router.post('/vms', async (req, res) => {
    try {
        const vmData = req.body;
        const result = await createVM(vmData);
        res.status(201).json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Route to fetch available SKUs
router.get('/vms/skus', async (req, res) => {
    try {
        const skus = await getAvailableSKUs();
        res.status(200).json(skus);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Route to fetch available images
router.get('/vms/images', async (req, res) => {
    try {
        const images = await getAvailableImages();
        res.status(200).json(images);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Route to validate VM name
router.post('/vms/validate-name', async (req, res) => {
    try {
        const { name } = req.body;
        const isValid = await validateVMName(name);
        res.status(200).json({ valid: isValid });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

export default router;