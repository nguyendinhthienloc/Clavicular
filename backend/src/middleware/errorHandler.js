function errorHandler(err, req, res, next) {
	console.error(err);

	const response = {
		success: false,
		statusCode: 500,
		message: "Something went wrong",
		payload: err.toString()
	};
	return void res.status(response.statusCode).json(response.get());
}

export default errorHandler;