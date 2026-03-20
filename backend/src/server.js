import express, { json, urlencoded } from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import cookies from 'cookie-parser';

import config from './config/config.js';
import corsMiddleware from './middleware/cors.js';
import errorHandler from './middleware/errorHandler.js';
import ServiceResponse from './helper/ServiceResponse.js';

const app = express()
const customStream = {
	write: (message) => {
		console.log(message.trimEnd());
		const stripAnsi = (s) => s.replace(/\x1b\[[0-9;]*m/g, '');
	}
};

app.use(helmet());
app.use(cookies());

// IMPORT ROUTES

// CORS
app.use(corsMiddleware);
app.use(json());
app.use(urlencoded({ extended: true }));

if (config.env === 'development') {
	app.use(morgan('dev', { stream: customStream }));
}
else {
	app.use(morgan('combined'));
}

// Health check endpoint
app.get('/health', (req, res) => {
	res.json({
		success: true,
		message: 'Smart Tourism API is running',
		timestamp: new Date().toISOString(),
		environment: config.env
	});
});

// Root endpoint
app.get('/', (req, res, next) => {
	const response = new ServiceResponse(
		true,
		200,
		"Welcome"
	);
	return void res.status(response.statusCode).json(response.get());
});

// 404 handler
app.use((req, res, next) => {
	const response = new ServiceResponse(
		false,
		404,
		"Route not found"
	);
	return void res.status(response.statusCode).json(response.get());
});

// Error handling middleware
app.use(errorHandler);

// Start server
const PORT = config.port;
app.listen(PORT, () => {
	// console.log(`1. Server is running on port ${PORT}`);
	// console.log(`2. Environment: ${config.env}`);
	// console.log(`3. Map tiles ready with OpenMapTiles`);
	// console.log(`\n API Docummentation: http://localhost:${PORT}/`)
	console.clear();
});

export default app;