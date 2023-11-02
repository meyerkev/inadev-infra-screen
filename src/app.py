import os
import requests
from flask import Flask, render_template, request

app = Flask(__name__)

# Replace with your OpenWeatherMap API key
API_KEY = os.environ.get('OPENWEATHERMAP_API_KEY')

def get_weather(city):
    base_url = 'https://api.openweathermap.org/data/2.5/weather'
    params = {'q': city, 'appid': API_KEY, 'units': 'imperial'}  # You can change 'units' to 'metric' for Celsius
    response = requests.get(base_url, params=params)
    data = response.json()
    return data

@app.route('/')
def index():
    # TODO: Get city from request.args, but that's not really the meat of this interview
    city = 'Washington,US'  # You can change this to any city you like

    # TODO: Absorb error handling if we get 401 errors
    weather_data = get_weather(city)

    # 401 error handling
    if weather_data.get('cod') == 401:
        return "Bad openweathermap.com token", 500
    
    if 'main' in weather_data and 'temp' in weather_data['main']:
        temperature = weather_data['main']['temp']
    else:
        temperature = 'N/A'
    
    if 'weather' in weather_data and len(weather_data['weather']) > 0:
        weather_description = weather_data['weather'][0]['description']
    else:
        weather_description = 'N/A'
    
    return render_template('index.html', city=city, temperature=temperature, weather_description=weather_description)

if __name__ == '__main__':
    app.run(debug=True)