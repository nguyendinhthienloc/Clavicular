import ServiceResponse from '../helper/ServiceResponse.js';
import AIService from '../services/AIService.js';

const PROMPT_MAXIMUM_LENGTH = 500;

class AIController {
	async sendPrompt(req, res, next) {
		try {
			const prompt = req.body.prompt;
			const model = req.body.model;

			if (!prompt) {
				const response = new ServiceResponse(
					false,
					400,
					"Prompt parameter is required"
				);
				return void res.status(response.statusCode).json(response.get());
			}

			if (prompt.length > PROMPT_MAXIMUM_LENGTH) {
				const response = new ServiceResponse(
					false,
					413,
					"Prompt must not exceed 500 characters"
				);
				return void res.status(response.statusCode).json(response.get());
			}

			const response = await AIService.sendPrompt(prompt, model);
			return void res.status(response.statusCode).json(response.get());
		} catch (error) {
			next(error);
		}
	}

	async diagnose(req, res, next) {
		try {
			const bodyParts = req.body.bodyParts;
			const severity = req.body.severity;
			const painType = req.body.painType;
			const duration = req.body.duration;
			const trigger = req.body.trigger;
			const lat = req.body.lat;
			const lng = req.body.lng;

			const response = await AIService.diagnose(bodyParts, severity, painType, duration, trigger, lat, lng);
			return void res.status(response.statusCode).json(response.get()); 
		} catch (err) {
			next(err)
		}
	}

	async sources(req, res, next) {
		try {
			const bodyParts = req.body.bodyParts;
			const severity = req.body.severity;
			const painType = req.body.painType;
			const duration = req.body.duration;
			const trigger = req.body.trigger;
			const lat = req.body.lat;
			const lng = req.body.lng;

			const response = await AIService.sources(bodyParts, severity, painType, duration, trigger, lat, lng);
			return void res.status(response.statusCode).json(response.get()); 
		} catch (err) {
			next(err)
		}
	}
}

export default new AIController();