<?php

class Passenger {

    public $formattedName;
    public $firstName;
    public $middleName;
    public $lastName;

    // create from json
    static function fromJson($json) {
        $passenger = new Passenger();
        $passenger->formattedName = $json['formattedName'];
        $passenger->firstName = $json['firstName'];
        $passenger->middleName = $json['middleName'];
        $passenger->lastName = $json['lastName'];
        return $passenger;
    }
}
?>
