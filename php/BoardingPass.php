<?php

use PKPass\PKPass;

class BoardingPass {

	private Passenger $passenger;
    private Flight $flight;
    public Ticket $ticket;

    function __construct(Ticket $ticket) {
        $this->ticket = $ticket;
        $this->passenger = $ticket->passenger;
        $this->flight = $ticket->flight;
    }

	private function create_pkpass() : PKPass {
		return  new PKPass(Config::$shared['certificate'], Config::$shared['certificate_password'], Config::$shared['wwdr']);
	}


    private function textField($key, $label, $value) {
        return [
            'key' => $key,
            'label' => $label,
            'value' => $value,
        ];
    }
    private function dateField(string $key, string $label, DateTime $value) {
        return [
            'key' => $key,
            'label' => $label,
            'value' => $value->format("D M d, H:i"),
        ];
    }

    function dateIntervalField(string $key, string $label, DateInterval $value) {
        return [
            'key' => $key,
            'label' => $label,
            'value' => $value->format('%H:%I'),
        ];
    }

    function boardingPassData() : array {
        $boardingpass = ['transitType' => 'PKTransitTypeAir'];
        $boardingpass[ 'headerFields' ] = [
            $this->textField('seat', 'Seat', $this->ticket->seatNumber),
            $this->textField('flight', 'Flight', $this->flight->flightNumber),
        ];
        $boardingpass[ 'primaryFields' ] = [
            $this->textField('origin', $this->flight->origin->fitName(20), $this->flight->origin->getIcao()),
            $this->textField('destination', $this->flight->destination->fitName(20), $this->flight->destination->getIcao()),
        ];

        $boardingpass[ 'secondaryFields' ] = [
            $this->textField('passenger-name', 'Name', $this->passenger->formattedName),
            $this->textField('gate', 'Gate', $this->flight->gate),
        ];
        $boardingpass['auxiliaryFields'] = [
            $this->dateField('date', 'Departs', $this->flight->scheduledDepartureDate),

        ];

        $boardingpass['backFields'] = [
            $this->textField('passenger-name', 'Passenger', $this->passenger->formattedName),
        ];

        $locations = $this->locationData();
        if( count($locations) > 0 ) {
            $boardingpass['locations'] = $locations;
        }
        return $boardingpass;
    }

    function locationData() : array {
        $locations = [];
        $originLocation = $this->flight->origin->getLocation();
        if( !is_null($originLocation) ) {
            $originLocation['relevantText'] = 'Welcome to '.$this->flight->origin->getName();
            $locations[] = $originLocation;
        }
        if( $this->flight->destination->icao != $this->flight->origin->icao ) {
            $destinationLocation = $this->flight->destination->getLocation();
            if( !is_null($destinationLocation) ) {
                $destinationLocation['relevantText'] = 'Thank you for flying with us to '.$this->flight->destination->getName();
                $locations[] = $destinationLocation;
            }
        }
        return $locations;
    }

    function getBarcodeData() : array {
        $uniqueId = $this->ticket->ticket_identifier;
        
        $payload = [];
        $payload['ticket'] = $uniqueId;
        if( Airline::$current !== null){
            $payload['signature'] = Airline::$current->sign($uniqueId);
        }

        return [
            'format' => 'PKBarcodeFormatQR',
            'message' => json_encode($payload),
            'messageEncoding' => 'iso-8859-1'
        ];
    }

    function getPassData() {
        $data = [
            'description' => 'Boarding pass',
            'formatVersion' => 1,
            'organizationName' => 'FlyFun Boarding Pass',
            'passTypeIdentifier' => 'pass.net.ro-z.flyfunboardingpass',
            'serialNumber' => '12345678',
            'teamIdentifier' => 'M7QSSF3624',

            'backgroundColor' => 'rgb(189,144,71)',
            'relevantDate' => $this->flight->scheduledDepartureDate->format('Y-m-d\TH:i:sP'),
        ];
        if( Airline::$current !== null){
            $data['logoText'] = Airline::$current->airline_name;
        } else {
            $data['logoText'] = 'FlyFun Airline';
        }
        $boardingpass = $this->boardingPassData();

        $data['boardingPass'] = $boardingpass;
        $data['barcode'] = $this->getBarcodeData();
        return $data;
    }

    function createPass() {
        $data = $this->getPassData();
		
		$pass = $this->create_pkpass();
		$pass->setData($data);
		$pass->addFile($this->getImagePath('icon.png'));
		$pass->addFile($this->getImagePath('icon@2x.png'));
		$pass->addFile($this->getImagePath('logo.png'));
		$pass->create(true);
    }

	function getImagePath($image) {
		return '../images/' . $image;
	}

}
