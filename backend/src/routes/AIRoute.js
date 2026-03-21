import { Router } from 'express';
const router = Router();
import AIController from '../controllers/AIController.js';
import ValidatorMiddleware from '../middleware/ValidatorMiddleware.js';

router.all('/send-prompt',
	ValidatorMiddleware.validateMethods(['POST']),
	ValidatorMiddleware.validateContentType,
	AIController.sendPrompt
);

router.all('/diagnose',
	ValidatorMiddleware.validateMethods(['POST']),
	ValidatorMiddleware.validateContentType,
	AIController.diagnose
);

router.all('/sources',
	ValidatorMiddleware.validateMethods(['POST']),
	ValidatorMiddleware.validateContentType,
	AIController.sources
);

router.all('/clinics',
	ValidatorMiddleware.validateMethods(['POST']),
	ValidatorMiddleware.validateContentType,
	AIController.clinics
);

router.all('/chat',
	ValidatorMiddleware.validateMethods(['POST']),
	ValidatorMiddleware.validateContentType,
	AIController.chat
);

export default router;