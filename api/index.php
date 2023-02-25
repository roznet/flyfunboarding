<?php
include_once( '../php/autoload.php' );

if (isset($_GET['url'])) {
	$url = $_GET['url'];
	// split the url into parts separated by /
    $parts = explode('/', $url);
    if (count($parts) < 2) {
        print( "Invalid URL" ) ;
        return;
    }
	$version = $parts[0];
	$action = $parts[1];

    if ($version != "v1") {
        print( "Invalid version");
        return;
    }
    
    if ($action == "pass") {
        include_once( 'samples.php' );
        $boardingPass = new BoardingPass($sample_ticket);
        $boardingPass->create_pass();
	}else if ($action == "airport") {
		$airport = new Airport($parts[2]);
        print(json_encode($airport->getInfo()));
    }else if ($action == "samples") {
        include_once( 'samples.php' );
        print(json_encode([ "aircrafts" => [$sample_aircraft->toJson()], "flights" => [$sample_flight->toJson()], "passengers" => [$sample_passenger->toJson()], "tickets" => [$sample_ticket->toJson()]]));
    } else {
            print( "Invalid action");
    }
}
