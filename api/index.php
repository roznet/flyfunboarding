<?php

include_once( '../php/autoload.php' );


if (isset($_GET['url'])) {
	$url = $_GET['url'];
	// split the url into parts separated by /
	$parts = explode('/', $url);
	$version = $parts[0];
	$action = $parts[1];

    if ($action == "pass") {
        include_once( 'samples.php' );
        $boardingPass = new BoardingPass($sample_passenger, $sample_flight);
        $boardingPass->create_pass();
		//$boardingPass->create_sample_pass(true);
	}else if ($action == "airport") {
		$airport = new Airport($parts[2]);
		print_r($airport->getInfo());
	}
}
?>
