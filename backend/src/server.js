import express, { json, urlencoded } from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import cookies from 'cookie-parser';

import config from './config/config.js';
import corsMiddleware from './middleware/cors.js';
import errorHandler from './middleware/errorHandler.js';

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

app.get('/health', (req, res) => {
	res.json({
		success: true,
		message: 'Running',
		timestamp: new Date().toISOString(),
		environment: config.env
	});
});

app.get('/', (req, res, next) => {
	const response = {
		success: true,
		statusCode: 200,
		message: "Welcome"
	};
	return void res.status(response.statusCode).json(response);
});

app.use((req, res, next) => {
	const response = {
		success: true,
		statusCode: 404,
		message: "Not found"
	};
	return void res.status(response.statusCode).json(response);
});

app.use(errorHandler);

const PORT = config.port
app.listen(PORT, () => {
	console.clear();
})

export default app;