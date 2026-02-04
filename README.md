# Fraud Detection Lite

A lightweight fraud detection system built with Ruby on Rails and PostgreSQL.

## Getting Started Locally

Follow these steps to get the project running on your local machine.

### Prerequisites

Ensure you have a Linux-based system (like Ubuntu). These instructions assume you are starting from scratch.
For Windows I'll suggest using WSL(Windows Subsystem for Linux)

### Setup Instructions

#### 1. Clone the Repository
```bash
git clone https://github.com/cheemx5395/fraud_detection_lite.git
cd fraud_detection_lite
```

#### 2. Install System Dependencies
Install the necessary libraries for PostgreSQL and build tools.
```bash
sudo apt update
sudo apt install libpq-dev build-essential
```

#### 3. Install Ruby Gems
Install the project dependencies using Bundler.
```bash
bundle install
```

#### 4. Setup Environment Variables
Copy the example environment file and update it with your database credentials if necessary.
```bash
cp .env.example .env
```
Open `.env` and fill in your `DATABASE_USERNAME` and `DATABASE_PASSWORD`.

#### 5. Setup the Database
Create the database and run the migrations.
```bash
rails db:create
rails db:migrate
```

#### 6. Start the Application
Boot up the Rails server.
```bash
rails server
```
The application will be available at `http://localhost:3000`.

## API Documentation
You can find the API documentation in `swagger.yaml`.

