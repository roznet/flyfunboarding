<?php

class Ticket {
    public Passenger $passenger;
    public Flight $flight;
    public string $seatNumber;
    // this is calculated from the flight and passenger
    public int $ticket_id = -1;
    public int $flight_id = -1;
    public int $passenger_id = -1;

    function uniqueIdentifier() : array {
        // EGTFLFMD_N122DR_202012311200
        $tag = $this->flight->uniqueIdentifier()['flight_identifier'] . '_' . $this->passenger->uniqueIdentifier()['passenger_identifier'];
        return [ 'ticket_identifier' => $tag ];
    }
    static public function issue(Passenger $passenger, Flight $flight, string $seatNumber, int $ticket_id = -1) : Ticket {
        $ticket = new Ticket();
        $ticket->passenger = $passenger;
        $ticket->flight = $flight;
        $ticket->seatNumber = $seatNumber;
        $ticket->ticket_id = $ticket_id;
        return $ticket;
    }

    static $jsonKeys = [
        'passenger' => 'Passenger',
        'flight' => 'Flight',
        'seatNumber' => 'string',
        'ticket_id' => 'integer'
    ];
    static $jsonValuesOptionalDefaults = [
        'ticket_id' => -1
    ];
    public function toJson() : array {
        return JsonHelper::toJson($this);
    }

    static public function fromJson(array $json) : Ticket {
        return JsonHelper::fromJson($json, 'Ticket');
    }
}
