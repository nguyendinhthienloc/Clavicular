import config from '../config/config.js'
import ServiceResponse from '../helper/ServiceResponse.js';
import { GoogleGenAI } from '@google/genai';
import axios from 'axios';
const gemini = new GoogleGenAI(config.gemini.APIKey);

class AIService {
	constructor() {
		this.locAIBaseURL = config.locAI.baseURL;
	}

	async sendPrompt(prompt, model = 'gemini-flash-latest') {
		try {
			await gemini.models.get({ model: model });
		} catch (err) {
			const response = new ServiceResponse(
				false,
				422,
				"Cannot load model",
				err.toString()
			);
			return response;
		}
		try {
			const data = await gemini.models.generateContent({
				model: model,
				contents: prompt
			});
			const text = data.candidates[0].content.parts[0].text;
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

	async diagnose(bodyParts, severity, painType, duration, trigger, lat, lng) {
		const query = `Body region: ${bodyParts.join(', ')}\nSeverity: ${severity}\nPain type: ${painType}\nDuration: ${duration}\nActivity trigger: ${trigger}`;

		try {
			const res = await axios.post(this.locAIBaseURL, {
				language: "en",
				query,
				lat,
				lng
			});
			const response = new ServiceResponse(
				true,
				200,
				"Success",
				res.data.data
			)
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