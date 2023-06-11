#!/usr/bin/env python3
# run test for example:
#   runtest.py https://localhost/flyfunboarding

import urllib.request
import requests
import json
import uuid
import argparse
import logging
import os

class Test:

    def __init__(self, args):
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.DEBUG)

        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler = logging.StreamHandler()
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)
        self.args = args
        self.baseurl = args.url
        self.samplesPath = args.sample
        self.airline_apple_identifier = str(uuid.uuid4())
        self.token = self.airline_apple_identifier
        self.logger.info("URL: " + self.baseurl)
        self.logger.info("User ID: " + self.airline_apple_identifier)

    def run(self):
        self.logger.info("Starting test")

        # create airline
        self.createAirline()
        self.createAircraft()
        self.createPassenger()
        self.createFlight()
        self.createTicket()
        self.checkBoardingPass()
        if self.args.delete:
            self.deleteAirline()

    def url(self, path):
        return os.path.join(self.baseurl, 'api', path)

    def airlineUrl(self, path = None):
        if path is None:
            return self.url('airline/' + self.airline_identifier)
        return self.url('airline/' + self.airline_identifier + '/' + path)

    def sampleJson(self, name):
        sample = self.samplesPath + '/sample_' + name + '.json'
        with open(sample) as f:
            return json.load(f)

    def createAirline(self):
        url = self.url('airline/create')
        self.logger.info("Creating airline: " + url)
        airlinedata = self.sampleJson('airline')
        airlinedata['apple_identifier'] = self.airline_apple_identifier
        rv = self.postJson(url, airlinedata)
        self.airline_identifier = rv['airline_identifier']
        self.logger.info("Airline create with identifier: " + self.airline_identifier)

    def deleteAirline(self):
        url = self.airlineUrl()
        self.logger.info("Deleting airline: " + url)
        self.delete(url)

    def createAircraft(self):
        url = self.airlineUrl('aircraft/create')
        self.logger.info("Creating aircraft: " + url)
        aircraftsdata = self.sampleJson('aircrafts')
        for aircraftdata in aircraftsdata:
            self.logger.info(f'Create Aircraft : {aircraftdata["registration"]}' )
            rv = self.postJson(url, aircraftdata)
            self.logger.info(f'Created Aircraft : {rv["aircraft_identifier"]}' )

    def createPassenger(self):
        url = self.airlineUrl('passenger/create')
        self.logger.info("Creating passenger: " + url)
        passengersdata = self.sampleJson('passengers')
        for passengerdata in passengersdata:
            self.logger.info(f'Create Passenger : {passengerdata["apple_identifier"]}' )
            rv = self.postJson(url, passengerdata)
            self.logger.info(f'Created Passenger : {rv["passenger_identifier"]}' )

    def createFlight(self):
        aircrafturl = self.airlineUrl('aircraft/list')
        self.logger.info("Getting aircraft: " + aircrafturl)
        aircrafts = self.getJson(aircrafturl)
        aircraft_identifier = aircrafts[0]['aircraft_identifier']
        self.logger.info("Aircraft identifier: " + aircraft_identifier)
        url = self.airlineUrl(f'flight/plan/{aircraft_identifier}')
        self.logger.info("Creating flight: " + url)
        flightsdata = self.sampleJson('flights')
        for flightdata in flightsdata:
            self.logger.info(f'Create Flight : {flightdata["flightNumber"]}' )
            rv = self.postJson(url, flightdata)
            self.logger.info(f'Created Flight : {rv["flight_identifier"]}' )

    def createTicket(self):
        flighturl = self.airlineUrl('flight/list')
        self.logger.info("Getting flight: " + flighturl)
        flights = self.getJson(flighturl)
        flight_identifier = flights[0]['flight_identifier']
        self.logger.info("Flight identifier: " + flight_identifier)
        passengerurl = self.airlineUrl('passenger/list')
        self.logger.info("Getting passenger: " + passengerurl)
        passengers = self.getJson(passengerurl)
        ticketsdata = self.sampleJson('tickets')
        for (ticketdata,passenger) in zip(ticketsdata,passengers):
            passenger_identifier = passenger['passenger_identifier']
            url = self.airlineUrl(f'ticket/issue/{flight_identifier}/{passenger_identifier}')
            self.logger.info(f'Create Ticket : {ticketdata["seatNumber"]} for {passenger["formattedName"]}' )
            rv = self.postJson(url, ticketdata)
            self.logger.info(f'Created Ticket : {rv["ticket_identifier"]}' )

    def checkBoardingPass(self):
        ticketurl = self.airlineUrl('ticket/list')
        self.logger.info("Getting ticket: " + ticketurl)
        tickets = self.getJson(ticketurl)
        ticket_identifier = tickets[0]['ticket_identifier']

        url = self.url(f'boardingpass/{ticket_identifier}?debug')
        self.logger.info("Getting boarding pass: " + url)
        rv = self.getJson(url)
        if self.args.verbose:
            self.logger.info("Boarding pass: " + json.dumps(rv, indent=4)) 

    def headers(self):
        rv = {'Content-Type': 'application/json'}
        if self.token:
            rv['Authorization'] = 'Bearer ' + self.token
        return rv

    def getJson(self,url):
        headers = self.headers()
        response = requests.get(url, headers=headers)

        if response.status_code != 200:
            self.logger.error('GET {} {}'.format(response.status_code, response.text))
        else:
            return response.json()

    def delete(self, url):
        req = urllib.request.Request(url, headers=self.headers(), method='DELETE')
        with urllib.request.urlopen(req) as response:
            if response.status != 200:
                self.logger.error('DELETE {} {}'.format(response.status, response.read()))
                return None
            responsetxt = response.read()
            self.logger.info('DELETE {} {}'.format(response.status, responsetxt))


    def postJson(self, url, data):
        req = urllib.request.Request(url, data=json.dumps(data).encode(), headers=self.headers(), method='POST')
        with urllib.request.urlopen(req) as response:
            if response.status != 200:
                self.logger.error('POST {} {}'.format(response.status, response.read()))
                return None
            responsetxt = response.read()
            self.logger.info('POST {} {}'.format(response.status, responsetxt))
            return json.loads(responsetxt)


# get the url from the command line argument
argparser = argparse.ArgumentParser()
argparser.add_argument('url', help='The base URL of the service to test ex: https://localhost/flyfunboarding')
argparser.add_argument('-s', '--sample', default='app/flyfunboarding/Preview Content', help='The path to the samples')
argparser.add_argument('--delete', action=argparse.BooleanOptionalAction, default=True, help='Delete the airline after the test')
argparser.add_argument('-v', '--verbose', action='store_true', help='Verbose logging')
args = argparser.parse_args()


# create a random user identifier
test = Test(args)
test.run()
