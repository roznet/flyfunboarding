<?php

include_once( '../php/autoload.php' );


if (isset($_GET['url'])) {
	$url = $_GET['url'];
	// split the url into parts separated by /
	$parts = explode('/', $url);
	$version = $parts[0];
	$action = $parts[1];

	if ($action == "pass") {
		$boardingPass = new BoardingPass();
		$boardingPass->create_pass(true);
	}else if ($action == "airport") {
		$airport = new Airport($parts[2]);
		print_r($airport->getInfo());
	}
}
?>
