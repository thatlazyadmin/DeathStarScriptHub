export interface VMRequest {
    name: string;
    size: string;
    image: string;
    adminUsername: string;
    adminPassword: string;
    location: string;
}

export interface VMResponse {
    id: string;
    name: string;
    size: string;
    image: string;
    status: string;
}

export interface SKU {
    name: string;
    tier: string;
    family: string;
    size: string;
    capacity: number;
}

export interface Image {
    publisher: string;
    offer: string;
    sku: string;
    version: string;
}

export interface ValidationResult {
    isValid: boolean;
    message: string;
}