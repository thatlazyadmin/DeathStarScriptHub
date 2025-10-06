import React from 'react';
import CreateVMForm from '../components/CreateVMForm';

const IndexPage: React.FC = () => {
    return (
        <div>
            <h1>Provision Azure Virtual Machine</h1>
            <CreateVMForm />
        </div>
    );
};

export default IndexPage;