<h1>Sign Up</h1>
<form action="/welcome" method="POST" onsubmit="return validate()">
	Name: <input id="Name" type="text" maxlength="100" name="Name"/><br>
	Number of URLs you wish to register (maximum 5): <input id="url_count" type="number" min="0" max="5" maxlength="20" name="url_count"/><br>
	Email: <input id="email" type="email" name="email"><br>
	URLs: <input id="url_0" type="text" maxlength="200" name="url_0"/><br>
	URLs: <input id="url_1" type="text" maxlength="200" name="url_1"/>
	<input type="button" value="Add" onclick="addURL(this.form)"/><br>
	<input id="Submit" type="submit" name="Submit"><br>
	<script src="js/form.js" type="text/javascript"></script>
</form>