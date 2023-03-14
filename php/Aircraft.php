<?php

class Aircraft {
    public string $registration;
    public string $type;
    public int $aircraft_id = -1;

    static array $jsonKeys = ['registration' => 'string', 'type' => 'string', 'aircraft_id' => 'integer'];
    static array $jsonValuesOptionalDefaults = ['aircraft_id' => -1];

    function toJson() : array {
        return JsonHelper::toJson($this);
    }
    static function fromJson(array $json) : Aircraft {
        return JsonHelper::fromJson($json, 'Aircraft');
    }

    function identifierTag() : string {
        // N122DR
        return $this->registration;
    }
    function uniqueIdentifier() : array {
        return ['aircraft_identifier' => MyFlyFunDb::uniqueIdentifier($this->identifierTag())];
    }

}
