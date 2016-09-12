var motorSlider = document.getElementById('motor-slider');

noUiSlider.create(motorSlider, {
	start: [8192],
	range: {
		min: [1],
		max: [8192]
	}
});

motorSlider.noUiSlider.on("update", function() {
	var value = motorSlider.noUiSlider.get();
	$.post({
		url: "http://" + window.location.host + "/motor", 
		data: JSON.stringify({newPwmValue: +value}),
		contentType: "application/json",
		dataType: "json"
	}).then(console.log).fail(console.error);
});
