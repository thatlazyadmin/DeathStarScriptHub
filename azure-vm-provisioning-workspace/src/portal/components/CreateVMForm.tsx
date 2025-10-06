import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { VMRequest } from '../../types';

const CreateVMForm: React.FC = () => {
    const [vmName, setVmName] = useState('');
    const [vmSize, setVmSize] = useState('');
    const [image, setImage] = useState('');
    const [availableSizes, setAvailableSizes] = useState<string[]>([]);
    const [availableImages, setAvailableImages] = useState<string[]>([]);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        const fetchAvailableSizes = async () => {
            try {
                const response = await axios.get('/api/vm/sizes');
                setAvailableSizes(response.data);
            } catch (err) {
                setError('Failed to fetch available sizes');
            }
        };

        const fetchAvailableImages = async () => {
            try {
                const response = await axios.get('/api/vm/images');
                setAvailableImages(response.data);
            } catch (err) {
                setError('Failed to fetch available images');
            }
        };

        fetchAvailableSizes();
        fetchAvailableImages();
    }, []);

    const handleSubmit = async (event: React.FormEvent) => {
        event.preventDefault();
        setLoading(true);
        setError('');

        const vmRequest: VMRequest = {
            name: vmName,
            size: vmSize,
            image: image,
        };

        try {
            await axios.post('/api/vm/create', vmRequest);
            alert('VM created successfully!');
        } catch (err) {
            setError('Failed to create VM');
        } finally {
            setLoading(false);
        }
    };

    return (
        <form onSubmit={handleSubmit}>
            <div>
                <label>
                    VM Name:
                    <input
                        type="text"
                        value={vmName}
                        onChange={(e) => setVmName(e.target.value)}
                        required
                    />
                </label>
            </div>
            <div>
                <label>
                    VM Size:
                    <select
                        value={vmSize}
                        onChange={(e) => setVmSize(e.target.value)}
                        required
                    >
                        <option value="">Select size</option>
                        {availableSizes.map((size) => (
                            <option key={size} value={size}>
                                {size}
                            </option>
                        ))}
                    </select>
                </label>
            </div>
            <div>
                <label>
                    Image:
                    <select
                        value={image}
                        onChange={(e) => setImage(e.target.value)}
                        required
                    >
                        <option value="">Select image</option>
                        {availableImages.map((img) => (
                            <option key={img} value={img}>
                                {img}
                            </option>
                        ))}
                    </select>
                </label>
            </div>
            {error && <div style={{ color: 'red' }}>{error}</div>}
            <button type="submit" disabled={loading}>
                {loading ? 'Creating...' : 'Create VM'}
            </button>
        </form>
    );
};

export default CreateVMForm;