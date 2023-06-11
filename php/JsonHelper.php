<?php

class JsonHelper {

    private static function valueFromJson($json, $key, $type, $defaults) {
        $rv = null;
        if (!isset($json[$key])) {
            if( isset($defaults[$key]) ){
                return $defaults[$key];
            }else{
                throw new Exception("Missing key $key");
            }
        }

        if( $type == "DateTime" ){
            $rv = new DateTime($json[$key]);
        }else if( $type == "DateInterval" ){
            $rv = new DateInterval($json[$key]);
        }else if( str_starts_with($type, 'array') ){
            // type can be array or array<type> 
            if( preg_match('/array<(.*)>/', $type, $matches) && class_exists($matches[1]) ){
                $subtype = $matches[1];
                $rv = [];
                foreach ($json[$key] as $item) {
                    $rv[] = JsonHelper::fromJson($item, $subtype);
                }
            }else{// no type, just use array
                $rv = $json[$key];
            }
        }else if( class_exists($type) ) {
            $rv = JsonHelper::fromJson($json[$key], $type);
        }else{
            $rv = $json[$key];
        }
        return $rv;
    }

    private static function valueToJson($obj, $key, $type, $defaults) {
        $rv = null;
        if( $type == "DateTime" ){
            if( $obj->$key == null ){
                return null;
            }
            $rv =  $obj->$key->format('c');
        }else if( $type == "DateInterval" ){
            $rv = $obj->$key->format('PT%hH%iM%sS');
        }else if( str_starts_with($type, 'array') ){
            if( preg_match('/array<(.*)>/', $type, $matches) && class_exists($matches[1]) ){
                $rv = [];
                foreach ($obj->$key as $item) {
                    $rv[] = JsonHelper::toJson($item);
                }
            }else{// no type, just use array
                $rv = $obj->$key;
            }
        }else if( class_exists($type) ){
            $rv = JsonHelper::toJson($obj->$key);
        }else{
            $rv = $obj->$key;
        }
        if( isset($defaults[$key]) && $defaults[$key] == $rv ){
            return null;
        }
        return $rv;
    }

    public static function fromJson($json, $class) : object {
        $obj = new $class();
        $defaults = [];
        if( isset($obj::$jsonValuesOptionalDefaults) ){
            $defaults = $obj::$jsonValuesOptionalDefaults;
        }
        foreach ($class::$jsonKeys as $key => $type) {
            $obj->$key = JsonHelper::valueFromJson($json, $key, $type, $defaults);
        }
        return $obj;
    }

    public static function toJson($obj) : array {
        $rv = [];
        $defaults = [];
        if( isset($obj::$jsonValuesOptionalDefaults) ){
            $defaults = $obj::$jsonValuesOptionalDefaults;
        }
        foreach ($obj::$jsonKeys as $key => $type) {
            $val = JsonHelper::valueToJson($obj, $key, $type, $defaults);
            if( $val !== null ){
                $rv[$key] = $val;
            }
        }
        if( method_exists($obj, 'uniqueIdentifier') ){
            $rv = array_merge($rv, $obj->uniqueIdentifier());
        }
        return $rv;
    }
}
