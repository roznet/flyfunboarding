<?php

class Flight {
    public Airport $origin;
    public Airport $destination;
    public string $gate;
    public string $flightNumber;
    public Aircraft $aircraft;
    public DateTime $scheduledDepartureDate;
    public DateInterval $flightTime; 
    public int $flight_id = -1;
    public int $aircraft_id = -1;


    function uniqueIdentifier() : array {
        // EGTFLFMD_N122DR_202012311200
        $tag = $this->origin->icao . $this->destination->icao . '_' . $this->aircraft->registration . '_' . $this->scheduledDepartureDate->format('YmdHi');
        return [ 'flight_identifier' => $tag ];
    }

    public static $jsonKeys = [
        'origin' => 'Airport',
        'destination' => 'Airport',
        'gate' => 'string',
        'flightNumber'  => 'string',
        'aircraft' => 'Aircraft',
        'scheduledDepartureDate' => 'DateTime',
        'flightTime' => 'DateInterval'
    ];
    public static $jsonValuesOptionalDefaults = [
        'flight_id' => -1
    ];

    public static function fromJson($json) : Flight {
        return JsonHelper::fromJson($json, 'Flight');
    }

    public function toJson() : array {
        return JsonHelper::toJson($this);
    }
}
