<?php

class Aircraft {
    public string $registration;
    public string $type;
    public int $aircraft_id = -1;
    public ?string $aircraft_identifier = null;

    static array $jsonKeys = ['registration' => 'string', 'type' => 'string', 'aircraft_id' => 'integer', 'aircraft_identifier' => 'string'];
    static array $jsonValuesOptionalDefaults = ['aircraft_id' => -1, 'aircraft_identifier' => ''];

    function toJson() : array {
        return JsonHelper::toJson($this);
    }
    static function fromJson(array $json) : Aircraft {
        return JsonHelper::fromJson($json, 'Aircraft');
    }

}
