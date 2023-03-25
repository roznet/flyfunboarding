<?php

class Stats {
    var string $table;
    var ?DateTime $last;
    var int $count;

    public static $jsonKeys = [
        'table' => 'string',
        'count' => 'integer',
        'last' => 'DateTime',
    ];
    public static $jsonValuesOptionalDefaults = [
        'last' => null,
    ];

    static function fromJson($json) {
        return JsonHelper::fromJson($json, 'Stats');
    }

    function toJson() {
        return JsonHelper::toJson($this);
    }
}
