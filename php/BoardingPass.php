<?php

use PKPass\PKPass;

class BoardingPass {

	function createPKPass() : PKPass {
		$pass = new PKPass(Config::$shared['certificate'], Config::$shared['certificate_password'], Config::$shared['wwdr']);
		$pass->setCertificatePassword(Config::$shared['certificate_password']);
		return $pass;
	}
	function imagePath($image) {
		return '../images/' . $image;
	}
	function create_pass() {
		$pass = $this->createPKPass();

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
		$pass->setData($data);
		$pass->addFile($this->imagePath('icon.png'));
		$pass->addFile($this->imagePath('icon@2x.png'));
		$pass->addFile($this->imagePath('logo.png'));
		$pass->create(true);

	}
}
?>
