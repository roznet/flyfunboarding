<?php

class Aircraft {
    public string $registration;
    public string $type;
    public int $aircraft_id;


    static array $jsonKeys = ['registration' => 'integer', 'type' => 'string', 'aircraft_id' => 'integer'];
    static array $jsonValuesOptionalDefaults = ['aircraft_id' => -1];

    function toJson() : array {
        return JsonHelper::toJson($this);
    }
    static function fromJson(array $json) : Aircraft {
        return JsonHelper::fromJson($json, 'Aircraft');
    }

    function uniqueIdentifier() : string {
        return $this->registration;
    }

}
