Guidlines: Ok status - 200, Error status - 500 and also send an error message

POST auth/keyExchange
	Headers:
		authentication token, userId: string (WIP)
	Body: 
		key: string
	Return:
				

GET video/:journeyId
	Headers:
		authentication token, userId: string
	Param: 
		journeyId: string
	Return:
		list of video chunks names as string with ',' for the specific journeyId + (WIP to also include thumbnail for each video name)
		
GET video/
	Headers:
		authentication token, userId: string	
	Return:
		list of journeys names as string with ','
		
GET video/:journeyId/:chunkId
	Headers:
		authentication token, userId: string (WIP)
	Param: 
		journeyId: string
		chunkId: string
	Return:
		Response with the following headers:
		res.setHeader('Content-Type', 'video/mp4');
		res.setHeader('Content-Disposition', `attachment; filename="${userId}_${journeyId}_${chunkId}.mp4"`);
	content:
		video + flag if it highlighted or not
	
GET video/download/:journeyId
	Headers:
		authentication token,userId: string
	Body: 
		journeyId: string
	Return:
		Response with the following headers:
		res.setHeader('Content-Type', 'application/zip');
		res.setHeader('Content-Disposition',`attachment; filename=${userId}_${journeyId}_videos.zip`);
	content:
		Zip of list of (video) + list of not/highlighted
		
GET video/download/all
	Headers:
		authentication token
	Body: 
		userId: string
	Return:
		Response with the following headers:
		res.setHeader('Content-Type', 'application/zip');
		res.setHeader('Content-Disposition',`attachment; filename=${userId}-videos.zip`);
	content:
		Zip of list of (video + metadata + pictures)
		
POST video/upload
	Headers:
		authentication token, userId: string
	form-data:
		key: video value: file,
		key: pictures value: file[],
		key: metadata value: file,
	body:
		