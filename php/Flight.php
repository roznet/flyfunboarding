<?php

class Flight {
    public Airport $origin;
    public Airport $destination;
    public string $gate;
    public string $flightNumber;
    public Aircraft $aircraft;
    public DateTime $scheduledDepartureDate;
    public DateInterval $flightTime; 


    function uniqueFlightIdentifier() : string {
        // EGTFLFMDN122DR202012311200
        return $this->origin->icao . $this->destination->icao . $this->aircraft->registration . $this->scheduledDepartureDate->format('YmdHi');
    }
    // Example json object:
    // {
    //    "origin": "EGTF",
    //    "destination": "LFMD",
    //    "gate": "1",
    //  "flightNumber": "N122DR",
    //  "aircraft": {
    //  "registration": "N122DR",
    //  "type": "Cessna 172"
    //  },

    // create from json
    public static function fromJson($json) : Flight {
        $flight = new Flight();
        $flight->origin = new Airport($json['origin']);
        $flight->destination = new Airport($json['destination']);
        $flight->gate = $json['gate'];
        $flight->flightNumber = $json['flightNumber'];
        $flight->aircraft = Aircraft::fromJson($json['aircraft']);
        $flight->scheduledDepartureDate = new DateTime($json['scheduledDepartureDate']);
        $flight->flightTime = new DateInterval($json['flightTime']);
        return $flight;
    }

    public function toJson() : array {
        return [
            'origin' => $this->origin->icao,
            'destination' => $this->destination->icao,
            'gate' => $this->gate,
            'flightNumber' => $this->flightNumber,
            'aircraft' => $this->aircraft->toJson(),
            'scheduledDepartureDate' => $this->scheduledDepartureDate->format('c'),
            'flightTime' => $this->flightTime->format('PT%hH%iM%sS'),

           // derived properties 
            'uniqueFlightIdentifier' => $this->uniqueFlightIdentifier(),
        ];
    }
}
