<?php

class Passenger {

    public $formattedName;
    public $firstName;
    public $middleName;
    public $lastName;
    public $passenger_id;

    // create from json
    static function fromJson($json) {
        $passenger = new Passenger();
        $passenger->formattedName = $json['formattedName'];
        $passenger->firstName = $json['firstName'];
        $passenger->middleName = $json['middleName'];
        $passenger->lastName = $json['lastName'];
        return $passenger;
    }

    function toJson() {
        return [
            "formattedName" => $this->formattedName,
            "firstName" => $this->firstName,
            "middleName" => $this->middleName,
            "lastName" => $this->lastName
        ];
    }

    function uniqueIdentifer() {
        // remove all white space and punctuation from formatted name
        // the regex below will remove all non-letters and non-numbers taking into account unicode
        $name = preg_replace('/[^\p{L}\p{N}]+/u', '', $this->formattedName);

        // convert to upper case
        return strtoupper($name);
    }
}
