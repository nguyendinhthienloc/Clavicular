import ServiceResponse from '../helper/ServiceResponse.js';
import AIService from '../services/AIService.js';

const PROMPT_MAXIMUM_LENGTH = 500;

class AIController {
	async sendPrompt(req, res, next) {
		try {
			const prompt = req.body.prompt;
			const instructions = req.body.instructions;

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

			const response = await AIService.sendPrompt(instructions, prompt);
			return void res.status(response.statusCode).json(response.get());
		} catch (error) {
			next(error);
		}
	}
}

export default new AIController();