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
            'logoText' => 'Brice FlyFun Airline',
            'relevantDate' => date('Y-m-d\TH:i:sP')
        ];
        $boardingpass = ['transitType' => 'PKTransitTypeAir'];
        $boardingpass[ 'headerFields' ] = [
            $this->textField('flight', 'Flight', $this->flight->flightNumber),
        ];

        $boardingpass[ 'primaryFields' ] = [
            $this->textField('origin', $this->flight->origin->getName(), $this->flight->origin->getIcao()),
            $this->textField('destination', $this->flight->destination->getName(), $this->flight->destination->getIcao()),
        ];

        $boardingpass[ 'secondaryFields' ] = [
            $this->textField('gate', 'Gate', $this->flight->gate),
            $this->textField('seat', 'Seat', '1B'),
        ];
        $boardingpass['auxiliaryFields'] = [
            $this->dateField('date', 'Date', $this->flight->date),
            $this->dateIntervalField('flightTime', 'Flight Time', $this->flight->flightTime),
        ];

        $boardingpass['backFields'] = [
            $this->textField('passenger-name', 'Passenger', $this->passenger->formattedName),
        ];

        $data['boardingPass'] = $boardingpass;

        $data['barcode'] = [
            'format' => 'PKBarcodeFormatQR',
            'message' => 'Flight-GateF12-ID6643679AH7B',
            'messageEncoding' => 'iso-8859-1',
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

	function create_sample_pass() {

		$data = [
	    'description' => 'Boarding pass',
	    'formatVersion' => 1,
	    'organizationName' => 'FlyFun Boarding Pass',
	    'passTypeIdentifier' => 'pass.net.ro-z.flyfunboardingpass', // Change this!
	    'serialNumber' => '12345678',
	    'teamIdentifier' => 'M7QSSF3624', // Change this!
	    'boardingPass' => [
		    'headerFields' => [
			    [
				    'key' => 'flight',
				    'label' => 'Flight',
				    'value' => 'N122DR',
			    ],
		    ],
		'primaryFields' => [
		    [
			'key' => 'origin',
			'label' => 'Fairoaks',
			'value' => 'EGTF',
		    ],
		    [
			'key' => 'destination',
			'label' => 'Cannes',
			'value' => 'LFMD',
		    ],
		],
		'secondaryFields' => [
		    [
			'key' => 'gate',
			'label' => 'Gate',
			'value' => '1',
		    ],
		    [
			'key' => 'seat',
			'label' => 'Seat',
			'value' => '1A',
		    ],
		    [
			'key' => 'flight',
			'label' => 'Flight',
			'value' => 'N122DR',
		    ],
		    [
			'key' => 'date',
			'label' => 'Departure Time',
			'value' => '07/06/2023 10:22',
		    ],
		],
		'auxiliaryFields' => [
			[
				'key' => 'class',
				'label' => 'Class',
				'value' => 'Top First',
			],
			[
				'key' => 'boardinggroup',
				'label' => 'Boarding',
				'value' => 'Group 1',
			],
		],
		'backFields' => [
		    [
			'key' => 'passenger-name',
			'label' => 'Passenger',
			'value' => 'Brice Rosenzweig',
		    ],
		],
		'transitType' => 'PKTransitTypeAir',
	    ],
	    'barcode' => [
		    
		'format' => 'PKBarcodeFormatQR',
		'message' => 'Flight-GateF12-ID6643679AH7B',
		'messageEncoding' => 'iso-8859-1',
	    ],
	    'backgroundColor' => 'rgb(189,144,71)',
	    'logoText' => 'Brice FlyFun Airline',
	    'relevantDate' => date('Y-m-d\TH:i:sP')
		];
		$pass = $this->create_pkpass();
		$pass->setData($data);
		$pass->addFile($this->image_path('icon.png'));
		$pass->addFile($this->image_path('icon@2x.png'));
		$pass->addFile($this->image_path('logo.png'));
		$pass->create(true);

	}
}
?>
