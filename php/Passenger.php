<?php

class Passenger {

    public $formattedName;
    public $firstName;
    public $middleName;
    public $lastName;
    public $stats = [];
    public $apple_identifier;
    public int $passenger_id = -1;  
    public ?string $passenger_identifier = null;

    public static $jsonKeys = [
        'formattedName' => 'string',
        'passenger_id' => 'integer',
        'apple_identifier' => 'string',
        'passenger_identifier' => 'string',
        'stats' => 'array'
    ];
    public static $jsonValuesOptionalDefaults = [
        'passenger_id' => -1,
        'passenger_identifier' => '',
        'stats' => []
    ];
    static function fromJson($json) {
        return JsonHelper::fromJson($json, 'Passenger');
    }

    function toJson() {
        return JsonHelper::toJson($this);
    }

}
