import { SNSClient, PublishCommand } from "@aws-sdk/client-sns"; // ES Modules import

export const sendSmsHandler = async (event) => {
    if (event.httpMethod !== 'POST') {
        throw new Error(`postMethod only accepts POST method, you tried: ${event.httpMethod} method.`);
    }

    console.info('Received: ', event);

    // Get phone number from the body of the request
    const body = JSON.parse(event.body);
    const phoneNumber = body.phoneNumber;
    
    const client = new SNSClient({});
    const input = { 
    Message: 'FireAlert: Smoke Detector Signal registered!',
    PhoneNumber: phoneNumber,
    Subject: 'FireAlert'};

    const command = new PublishCommand(input);
    const responseSns = await client.send(command);

    console.info('Response from SNS: ', responseSns);

    const response = {
        statusCode: responseSns?.$metadata?.httpStatusCode
    };

    return response;
};

