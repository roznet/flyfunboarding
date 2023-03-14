<?php

class Passenger {

    public $formattedName;
    public $firstName;
    public $middleName;
    public $lastName;
    public $apple_identifier;
    public int $passenger_id = -1;  

    public static $jsonKeys = [
        'formattedName' => 'string',
        'firstName' => 'string',
        'middleName' => 'string',
        'lastName' => 'string',
        'passenger_id' => 'integer',
        'apple_identifier' => 'string',
    ];
    public static $jsonValuesOptionalDefaults = [
        'passenger_id' => -1,
    ];
    static function fromJson($json) {
        return JsonHelper::fromJson($json, 'Passenger');
    }

    function toJson() {
        return JsonHelper::toJson($this);
    }

    function identifierTag() : string {
        return $this->apple_identifier;
    }

    function uniqueIdentifier() : array{
        // convert to upper case
        return ['passenger_identifier' => MyFlyFunDb::uniqueIdentifier($this->identifierTag())];
    }
}
