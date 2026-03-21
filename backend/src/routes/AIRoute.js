import { Router } from 'express';
import multer from 'multer';
const router = Router();
import AIController from '../controllers/AIController.js';
import ValidatorMiddleware from '../middleware/ValidatorMiddleware.js';

const storage = multer.memoryStorage()
const upload = multer({ storage: storage });
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

router.all('/transcribe',
	ValidatorMiddleware.validateMethods(['POST']),
	upload.single('file'),
	AIController.transcribe
);

export default router;