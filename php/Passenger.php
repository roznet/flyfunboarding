<?php

class Passenger {

    public $formattedName;
    public $firstName;
    public $middleName;
    public $lastName;
    public int $passenger_id;

    public static $jsonKeys = [
        'formattedName' => 'string',
        'firstName' => 'string',
        'middleName' => 'string',
        'lastName' => 'string',
        'passenger_id' => 'integer'
    ];
    public static $jsonValuesOptionalDefaults = [
        'passenger_id' => -1
    ];
    // create from json
    static function fromJson($json) {
        return JsonHelper::fromJson($json, 'Passenger');
    }

    function toJson() {
        return JsonHelper::toJson($this);
    }

    function uniqueIdentifer() {
        // remove all white space and punctuation from formatted name
        // the regex below will remove all non-letters and non-numbers taking into account unicode
        $name = preg_replace('/[^\p{L}\p{N}]+/u', '', $this->formattedName);

        // convert to upper case
        return strtoupper($name);
    }
}
