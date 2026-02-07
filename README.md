# ![icon](https://github.com/roznet/flyfunboarding/blob/ecda36f975109a8708dd4ea8d943c5064dde16d1/images/icon.png) Fly Fun Boarding App

Welcome to Fly Fun Boarding, a Mini Airline Workflow for Private Pilots! This open-source application is designed to provide a fun and engaging way for private pilots to issue boarding passes to their friends and family for flights on small planes, such as Cirrus, Cessna, or Diamond aircraft. It is intended for non-commercial use and serves as a fun way to enhance the experience of flying with a private pilot. The app is built using SwiftUI with a Python/FastAPI backend server.

## Features

- Issue boarding passes for fun flights with friends and family
- Boarding passes can be viewed on a web page
- Add boarding passes to the Apple Wallet application
- Simple user experience leveraging Apple infrastructure
- Sign in with Apple
- Import contacts from the Contacts app

## Prerequisites

Xcode 14 or later
iOS 16 or later
Python 3.13 or later for the backend server
MySQL 8.0

## Installation

### App Store
This app is available for free on the [app store](https://apps.apple.com/us/app/flyfunboarding/id6446208594). You can also check out the [help page](https://ro-z.net/blog/flyfun-boarding-pass/).

### App
The app is located under the `app` directory. You will need to edit the `secrets.json` file with information on your server.

### Server
The server is located under the `server` directory. It runs as a Docker container with FastAPI/uvicorn.
You will need to create a `.env` file with your database credentials, secrets, and certificate paths. See `server/.env.docker.example` for reference.

## Usage

- Sign in with your Apple ID.
- Import your contacts or manually add passengers for your flight.
- Create a flight by specifying the departure and arrival airports, date, and time.
- Issue boarding passes to the selected passengers.
- Passengers will receive a link to view their boarding pass online and can add it to their Apple Wallet.


## Contributing

We welcome contributions from the community. If you'd like to contribute, please fork the repository and submit a pull request with your changes. Make sure to follow the coding conventions and provide clear descriptions of your changes.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This application is intended for fun and non-commercial use only. It is not affiliated with any airline, aircraft manufacturer, or certification authority. The developers are not responsible for any misuse or unintended consequences resulting from the

## Acknowledgments

This app was initially developed with extensive assistance from ChatGPT by OpenAI and GitHub Copilot, two AI-powered tools that provided valuable insights and code suggestions throughout the development process. The server was subsequently migrated from PHP to Python/FastAPI and significantly refactored and improved with Claude by Anthropic. Their contributions have made the development process much faster than is typical for such an application. We appreciate their support in making this project a success.
