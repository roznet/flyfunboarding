<?php

class Flight {
    public Airport $origin;
    public Airport $destination;
    public string $gate;
    public string $flightNumber;
    public Aircraft $aircraft;
    public DateTime $scheduledDepartureDate;
    public int $flight_id = -1;
    public int $aircraft_id = -1;


    function identifierTag() : string {
        // EGTFLFMD.N122DR.202012311200
        $gmt = $this->scheduledDepartureDate->setTimezone(new DateTimeZone('GMT'));

        return $this->origin->icao . $this->destination->icao . '.' . $this->aircraft->registration . '.' . $gmt->format('YmdHi');
    }
    function uniqueIdentifier() : array {
        return [ 'flight_identifier' => MyFlyFunDb::uniqueIdentifier($this->identifierTag()) ];
    }

    function verifySame(Flight $other ) : array {
        $valueSame = $this->origin->icao == $other->origin->icao &&
            $this->destination->icao == $other->destination->icao &&
            $this->aircraft->registration == $other->aircraft->registration &&
            $this->scheduledDepartureDate->format('YmdHi') == $other->scheduledDepartureDate->format('YmdHi');

        $attributeSame = $this->gate == $other->gate &&
            $this->flightNumber == $other->flightNumber;

        $identifierSame = $this->identifierTag() == $other->identifierTag();

        return [
            'valueSame' => $valueSame,
            'attributeSame' => $attributeSame,
            'identifierSame' => $identifierSame,
        ];
    }

    public static $jsonKeys = [
        'origin' => 'Airport',
        'destination' => 'Airport',
        'gate' => 'string',
        'flightNumber'  => 'string',
        'aircraft' => 'Aircraft',
        'scheduledDepartureDate' => 'DateTime',
        'flight_id' => 'integer',
    ];
    public static $jsonValuesOptionalDefaults = [
        'flight_id' => -1,
    ];

    public static function fromJson($json) : Flight {
        $rv = JsonHelper::fromJson($json, 'Flight');
        if(isset($rv->aircraft->aircraft_id)) {
            $rv->aircraft_id = $rv->aircraft->aircraft_id;
        }
        return $rv;
    }

    public function toJson() : array {
        return JsonHelper::toJson($this);
    }
}
