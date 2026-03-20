import 'dotenv/config';

const config = {
	env: process.env.NODE_ENV || 'development',
	port: process.env.PORT || 3000,

	cors: {
		allowedOrigins: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000']
	},

	rateLimit: {
		windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
		max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
	},

	gemini: {
		APIKey: process.env.GEMINI_API_KEY,
	}
}

export default config;