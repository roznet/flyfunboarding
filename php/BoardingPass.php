<?php

use PKPass\PKPass;

class BoardingPass {

	public Passenger $passenger;
	public Flight $flight;

    function __construct(Passenger $passenger, Flight $flight) {
        $this->passenger = $passenger;
        $this->flight = $flight;
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
            'value' => $value->format("D M d, H:s"),
        ];
    }

    private function dateIntervalField(string $key, string $label, DateInterval $value) {
        return [
            'key' => $key,
            'label' => $label,
            'value' => $value->format('%H:%I'),
        ];
    }
    function create_pass() {
        $data = [
            'description' => 'Boarding pass',
            'formatVersion' => 1,
            'organizationName' => 'FlyFun Boarding Pass',
            'passTypeIdentifier' => 'pass.net.ro-z.flyfunboardingpass',
            'serialNumber' => '12345678',
            'teamIdentifier' => 'M7QSSF3624',

            'backgroundColor' => 'rgb(189,144,71)',
            'logoText' => 'Brice Airline',
            'relevantDate' => date('Y-m-d\TH:i:sP')
        ];
        $boardingpass = ['transitType' => 'PKTransitTypeAir'];
        $boardingpass[ 'headerFields' ] = [
            $this->textField('seat', 'Seat', '1B'),
            $this->textField('flight', 'Flight', $this->flight->flightNumber),
        ];

        $boardingpass[ 'primaryFields' ] = [
            $this->textField('origin', $this->flight->origin->fitName(20), $this->flight->origin->getIcao()),
            $this->textField('destination', $this->flight->destination->fitName(20), $this->flight->destination->getIcao()),
        ];

        $boardingpass[ 'secondaryFields' ] = [
            $this->textField('passenger-name', 'Passenger', $this->passenger->formattedName),
        ];
        $boardingpass['auxiliaryFields'] = [
            $this->dateField('date', 'Departs', $this->flight->scheduledDepartureDate),
            $this->dateIntervalField('flightTime', 'Flight Time', $this->flight->flightTime),
        ];

        $boardingpass['backFields'] = [
            $this->textField('passenger-name', 'Passenger', $this->passenger->formattedName),
        ];

        $data['boardingPass'] = $boardingpass;
        $json_payload = json_encode($this->flight->toJson());
        $data['barcode'] = [
            'format' => 'PKBarcodeFormatQR',
            'message' => $json_payload,
            'messageEncoding' => 'iso-8859-1'
            ];

		
		$pass = $this->create_pkpass();
		$pass->setData($data);
		$pass->addFile($this->image_path('icon.png'));
		$pass->addFile($this->image_path('icon@2x.png'));
		$pass->addFile($this->image_path('logo.png'));
		$pass->create(true);
    }

	function image_path($image) {
		return '../images/' . $image;
	}

}