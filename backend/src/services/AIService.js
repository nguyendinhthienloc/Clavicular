import config from '../config/config.js'
import ServiceResponse from '../helper/ServiceResponse.js';
import { GoogleGenAI } from '@google/genai';
import OpenAI from 'openai'

const client = new OpenAI({
	apiKey: config.openai.APIKey
});

class AIService {
	constructor() {
		
	}

	async sendPrompt(instructions, prompt) {
		try {
			const data = await client.responses.create({
				model: 'gpt-5.4',
				instructions: instructions,
				input: prompt
			});

			const text = data.output_text;
			const response = new ServiceResponse(
				true,
				200,
				"Success",
				text
			);
			return response;
		} catch (err) {
			const response = new ServiceResponse(
				false,
				502,
				"Something went wrong",
				err.toString()
			);
			return response;
		}
	}
}

export default new AIService();