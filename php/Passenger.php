<?php

class Passenger {

    public $formattedName;
    public $firstName;
    public $middleName;
    public $lastName;
    public int $passenger_id = -1;  

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
    static function fromJson($json) {
        return JsonHelper::fromJson($json, 'Passenger');
    }

    function toJson() {
        return JsonHelper::toJson($this);
    }

    function uniqueIdentifier() : array{
        // the regex below will remove all non-letters and non-numbers taking into account unicode
        $ident = array_map(function($x) { return ucfirst(preg_replace('/[^\p{L}\p{N}]+/u','',  $x)); }, [$this->firstName, $this->middleName, $this->lastName]);

        // convert to upper case
        return ['passenger_identifier' => implode($ident)];
    }
}
