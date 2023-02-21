<?php

include_once( 'PKPass.php' );

use PKPass\PKPass;
// function to create a pass
function create_pass() {
	$pass = new PKPass('certs/Certificates.p12', 'passeluc!2003');

	$data = [
		'formatVersion' => 1,
		'passTypeIdentifier' => 'pass.net.ro-z.flyfunboardingpass',
		'teamIdentifier' => 'M7QSSF3624',
		'serialNumber' => '123456',
		'organizationName' => 'FlyFun Boarding',
		'description' => 'FlyFun Boarding Pass',
		'logoText' => 'Example',
		'boardingpass' => [
			'primaryFields' => [
				[ 'key' => 'origin',
				'label' => 'Fairoaks',
				'value' => 'EGTF'
				],
				[ 'key' => 'destination',
				'label' => 'Cannes',
				'value' => 'LFMD'
				],
			],
			'secondaryFields' => [
				[ 'key' => 'gate',
				'label' => 'Gate',
				'value' => '1'
				],
				[ 'key' => 'seat',
				'label' => 'Seat',
				'value' => '1B'
				],
				[ 'key' => 'flight',
				'label' => 'Flight',
				'value' => 'N122DR'
				],
			],
			'backFields' => [
				[ 'key' => 'passenger-name',
				'label' => 'Passenger',
				'value' => 'Brice Rosenzweig'
				],
				[ 'key' => 'seat',
				'label' => 'Seat',
				'value' => '1B'
				],
				[ 'key' => 'flight',
				'label' => 'Flight',
				'value' => 'N122DR'
				],
				[ 'key' => 'departure-date',
				'label' => 'Departure',
				'value' => '2023-06-01 12:00'
				],
				[ 'key' => 'arrival-date',
				'label' => 'Arrival',
				'value' => '2023-06-01 14:00'
				],
				[ 'key' => 'flight-duration',
				'label' => 'Flight Duration',
				'value' => '2h'
				],
			],
		],
		'foregroundColor' => 'rgb(255, 255, 255)',
		'backgroundColor' => 'rgb(255, 0, 0)',
		'labelColor' => 'rgb(255, 255, 255)',
		'barcode' => [
			'format' => 'PKBarcodeFormatQR',
			'message' => '123456',
			'messageEncoding' => 'iso-8859-1',
		],
		'locations' => [
			[
				'longitude' => 2.294481,
				'latitude' => 48.858370,
			],
		],
		'associatedStoreIdentifiers' => [12345, 54321],
		'userInfo' => [
			'customKey' => 'customValue',
		],
		'relevantDate' => '2023-06-01T12:00-08:00',
	];
	$data = [
    'description' => 'Demo pass',
    'formatVersion' => 1,
    'organizationName' => 'Flight Express',
    'passTypeIdentifier' => 'pass.net.ro-z.flyfunboardingpass', // Change this!
    'serialNumber' => '12345678',
    'teamIdentifier' => 'M7QSSF3624', // Change this!
    'boardingPass' => [
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
                'key' => 'date',
                'label' => 'Departure date',
                'value' => '07/11/2012 10:22',
            ],
        ],
        'backFields' => [
            [
                'key' => 'passenger-name',
                'label' => 'Passenger',
                'value' => 'John Appleseed',
            ],
        ],
        'transitType' => 'PKTransitTypeAir',
    ],
    'barcode' => [
        'format' => 'PKBarcodeFormatQR',
        'message' => 'Flight-GateF12-ID6643679AH7B',
        'messageEncoding' => 'iso-8859-1',
    ],
    'backgroundColor' => 'rgb(32,110,247)',
    'logoText' => 'Flight info',
    'relevantDate' => date('Y-m-d\TH:i:sP')
];
	$pass->setData($data);
	$pass->addFile('images/icon.png');
	$pass->addFile('images/icon@2x.png');
	$pass->addFile('images/logo.png');
	$pass->create(true);

}

if (isset($_GET['url'])) {
	$url = $_GET['url'];
	// split the url into parts separated by /
	$parts = explode('/', $url);
	$version = $parts[0];
	$action = $parts[1];

	if ($action == "pass") {
		create_pass();
	}
}
?>
