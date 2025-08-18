# Step 1: Create the Weather Forecast App

## Create a GitHub Repository

1. **Name the repository**: `weather-forecast-app`.
2. **Include a README**:
   - Add a `README.md` file that briefly explains the project, its purpose, and instructions for setup and usage.

## Code the App

1. **Choose Your Language**:
   - Use **Python** (with Flask) or **Node.js** (with Express) for the backend.
2. **Set Up the OpenWeatherMap API**:
   - Register on [OpenWeatherMap](https://openweathermap.org/api) to get an API key for fetching weather data.

### Python Example: Setting Up the Application with Flask

1. **Install Flask and Requests**:
   ```bash
   pip install Flask requests
    ```
2. **Create** app.py:
    - Basic strcture for app.py to fetch and display weather data:
    
```python
from flask import Flask, render_template, request
import requests

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/forecast', methods=['POST'])
def forecast():
    city = request.form['city']
    api_key = 'YOUR_API_KEY'  # Replace with your actual API key
    url = f'http://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}'
    response = requests.get(url).json()
    weather = response['weather'][0]['description']
    temperature = response['main']['temp']
    return render_template('forecast.html', weather=weather, temperature=temperature)

if __name__ == '__main__':
    app.run(debug=True)
```

### HTML Templates 
1. **Create** template/index.html:
    - Basic HTML form for entering the city name:

```html
    <!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Weather Forecast</title>
</head>
<body>
    <h1>Enter City Name</h1>
    <form action="/forecast" method="POST">
        <input type="text" name="city" placeholder="City Name" required>
        <button type="submit">Get Forecast</button>
    </form>
</body>
</html>
```

2. **Create** templates/forecast.html
    - Display the weather data:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Weather Forecast</title>
</head>
<body>
    <h1>Weather Forecast</h1>
    <p>Weather: {{ weather }}</p>
    <p>Temperature: {{ temperature }}°C</p>
    <a href="/">Back to Home</a>
</body>
</html>
```

## Push the Code to Github
1. **Initialize Git:**
    ```bash
    git init
    ```
2. **Add and Commit the Code:**
    ```bash
    git add .
    git commit -m "Initial commit"
    ```
3. **Push to GitHub:**
 - Set up the remote repository and push:
    ```bash
    git remote add origin <your-repo-url>
    git push -u origin main
    ```

This completed the setup of your weather forecasting app, with source code managed in GitHub. The app fetches weather data using the OpenWeatherMap API, and displays it on a simple HTML interface.