<?php

class Passenger {

    public $formattedName;
    public $firstName;
    public $middleName;
    public $lastName;
    public int $passenger_id;

    // create from json
    static function fromJson($json) {
        $passenger = new Passenger();
        $passenger->formattedName = $json['formattedName'];
        $passenger->firstName = $json['firstName'];
        $passenger->middleName = $json['middleName'];
        $passenger->lastName = $json['lastName'];
        if( isset($json['passenger_id']) ) {
            $passenger->passenger_id = $json['passenger_id'];
        }else{
            $passenger->passenger_id = -1;
        }

        return $passenger;
    }

    function toJson() {
        $rv = [
            "formattedName" => $this->formattedName,
            "firstName" => $this->firstName,
            "middleName" => $this->middleName,
            "lastName" => $this->lastName
        ];
        if( $this->passenger_id != -1 ) {
            $rv['passenger_id'] = $this->passenger_id;
        }
        return $rv;
    }

    function uniqueIdentifer() {
        // remove all white space and punctuation from formatted name
        // the regex below will remove all non-letters and non-numbers taking into account unicode
        $name = preg_replace('/[^\p{L}\p{N}]+/u', '', $this->formattedName);

        // convert to upper case
        return strtoupper($name);
    }
}
