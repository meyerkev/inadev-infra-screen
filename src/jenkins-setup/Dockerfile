# Use an official Python runtime as a parent image with Python 3.11
FROM python:3.11-slim

RUN apt update && apt upgrade -y

# Debugging only, but useful nonetheless
RUN pip install --upgrade pip ipython

# Create and set the working directory
WORKDIR /app

# Copy just the requirements file first to leverage Docker cache
COPY requirements.txt /app/

# Install the required packages from requirements.txt
RUN pip install -r requirements.txt

# Copy the rest of the application code
COPY . /app

# Define the command to run your Flask app
CMD  python /app/main.py
