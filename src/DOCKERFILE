# Use an official Python runtime as a parent image with Python 3.11
FROM python:3.11-slim

RUN apt update && apt upgrade -y

# Set environment variables for Flask
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

# Create and set the working directory
WORKDIR /app

# Copy just the requirements file first to leverage Docker cache
COPY requirements.txt /app/

# Install the required packages from requirements.txt
RUN pip install -r requirements.txt

# Copy the rest of the application code
COPY . /app

# Build argument for the OpenWeatherMap API key
ARG OPENWEATHERMAP_API_KEY

# Set the API key as an environment variable
ENV OPENWEATHERMAP_API_KEY=$OPENWEATHERMAP_API_KEY

# Expose port 5000 for Flask
EXPOSE 5000

# Define the command to run your Flask app
CMD ["flask", "run"]
