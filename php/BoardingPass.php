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

    function dateIntervalField(string $key, string $label, DateInterval $value) {
        return [
            'key' => $key,
            'label' => $label,
            'value' => $value->format('%H:%I'),
        ];
    }

    function localeStrings($language) : array {
        $defs = [
            'fr' => [
                'Flight' => 'Vol',
                'Aircraft' => 'Avion',
                'Gate' => 'Porte',
                'Departs' => 'Départ',
                'Arrives' => 'Arrivée',
                'Passenger' => 'Passager',
                'Seat' => 'Siège',
                'I agree to the terms and conditions below' => 'J\'accepte les termes et conditions ci-dessous',
            ],
            'en' => [
                'Flight' => 'Flight',
                'Aircraft' => 'Aircraft',
                'Gate' => 'Gate',
                'Departs' => 'Departs',
                'Arrives' => 'Arrives',
                'Passenger' => 'Passenger',
                'Seat' => 'Seat',
                'I agree to the terms and conditions below' => 'I agree to the terms and conditions below',
            ],
            'de' => [
                'Flight' => 'Flug',
                'Aircraft' => 'Flugzeug',
                'Gate' => 'Tor',
                'Departs' => 'Abflug',
                'Arrives' => 'Ankunft',
                'Passenger' => 'Passagier',
                'Seat' => 'Sitz',
                'I agree to the terms and conditions below' => 'Ich stimme den unten stehenden Bedingungen zu',
            ],
            'es' => [
                'Flight' => 'Vuelo',
                'Aircraft' => 'Avión',
                'Gate' => 'Puerta',
                'Departs' => 'Sale',
                'Arrives' => 'Llega',
                'Passenger' => 'Pasajero',
                'Seat' => 'Asiento',
                'I agree to the terms and conditions below' => 'Acepto los términos y condiciones a continuación',
            ],
        ];
        if( isset($defs[$language]) ) {
            return $defs[$language];
        }
        return [];
    }

    function localString($language, $key) {
        $strings = $this->localeStrings($language);
        if( isset($strings[$key]) ) {
            return $strings[$key];
        }
        return $key;
    }

    function boardingPassData() : array {
        $boardingpass = ['transitType' => 'PKTransitTypeAir'];
        $boardingpass[ 'headerFields' ] = [
            $this->textField('seat', 'Seat', $this->ticket->seatNumber),
        ];

        if( $this->flight->hasFlightNumber() ) {
            $boardingpass['headerFields'][] = $this->textField('flight-number', 'Flight', $this->flight->flightNumber);
        }else{
            $boardingpass['headerFields'][] = $this->textField('flight-number', 'Aircraft', $this->flight->aircraft->registration);
        }
        $boardingpass[ 'primaryFields' ] = [
            $this->textField('origin', $this->flight->origin->fitName(20), $this->flight->origin->getIcao()),
            $this->textField('destination', $this->flight->destination->fitName(20), $this->flight->destination->getIcao()),
        ];

        $boardingpass[ 'secondaryFields' ] = [
            $this->textField('passenger-name', 'Passenger', $this->passenger->formattedName),
            $this->textField('gate', 'Gate', $this->flight->gate),
        ];
        $boardingpass['auxiliaryFields'] = [
            $this->textField('date', 'Departs', $this->flight->formatScheduledDepartureDate()),
        ];

        $hasCustom = $this->ticket->hasCustomLabel();
        if( $hasCustom){
            $settings = Airline::$current->settings();
            $boardingpass['auxiliaryFields'][] = $this->textField('custom-label', $settings->customLabel(), $this->ticket->customLabelValue);
        }
        
        if( !$hasCustom && $this->flight->hasFlightNumber()){
            $boardingpass['auxiliaryFields'][] = $this->textField('aircraft', 'Aircraft', $this->flight->aircraft->registration);
        }
        $boardingpass['backFields'] = [
            $this->textField('passenger-name', 'Passenger', $this->passenger->formattedName),
        ];

        $infos = ['origin' => $this->flight->origin->getInfo(), 'destination' => $this->flight->destination->getInfo()];
        foreach( $infos as $which => $info ) {
            if( $which == 'origin' ){
                $boardingpass['backFields'][] = $this->textField('origin-map-url', 'Origin Airport Location', $this->flight->origin->getMapURL());
            } else if( $which == 'destination' ){
                $boardingpass['backFields'][] = $this->textField('destination-map-url', 'Destination Airport Location', $this->flight->destination->getMapURL());
            }

            if( !is_null($info) ) {
                foreach(['name', 'municipality', 'iso_country','iata_code', 'home_link', 'wikipedia_link'] as $key) {
                    if( isset($info[$key]) && !empty($info[$key])) {
                        // replace _ with space and capitalize
                        $label = ucwords($which.' airport '.str_replace('_', ' ', $key));
                        $fieldkey = $which.'-'.str_replace('_', '-', $key);
                        $boardingpass['backFields'][] = $this->textField($fieldkey, $label, $info[$key]);
                    }
                }
            }
        }

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
        $payload = $this->ticket->signature();

        return [
            'format' => 'PKBarcodeFormatQR',
            'message' => json_encode($payload),
            'messageEncoding' => 'iso-8859-1'
        ];
    }

    function getPassData() {
        $data = [
            'description' => 'Boarding Pass',
            'formatVersion' => 1,
            'organizationName' => 'FlyFun Boarding Pass',
            'passTypeIdentifier' => 'pass.net.ro-z.flyfunboardingpass',
            'serialNumber' => $this->ticket->ticket_identifier,
            'teamIdentifier' => 'M7QSSF3624',

            'backgroundColor' => 'rgb(189,144,71)',
            'foregroundColor' => 'rgb(255,255,255)',
            'labelColor' => 'rgb(255,255,255)',
            'logoText' => 'FlyFun Airline',
            'relevantDate' => $this->flight->scheduledDepartureDate->format('Y-m-d\TH:i:sP'),
        ];
        if( Airline::$current !== null){
            $settings = Airline::$current->settings();
            $data['logoText'] = Airline::$current->airline_name;
            $data['backgroundColor'] = $settings->backgroundColor();
            $data['foregroundColor'] = $settings->foregroundColor();
            $data['labelColor'] = $settings->labelColor();
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
        foreach( ['en', 'fr'] as $lang ) {
            $pass->addLocaleStrings($lang, $this->localeStrings($lang));
        }
		$pass->addFile($this->getImagePath('icon.png'));
		$pass->addFile($this->getImagePath('icon@2x.png'));
		$pass->addFile($this->getImagePath('logo.png'));
		$pass->create(true);
    }

	function getImagePath($image) {
		return '../images/' . $image;
	}

}
