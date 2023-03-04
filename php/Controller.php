<?php

class Controller {

    function contentType($type = 'application/json') {
        header('Content-Type: ' . $type);
    }

    function terminate($code, $message) {
        http_response_code($code);
        die($message);
    }
   function validateMethod( $method ) {
       if ( $_SERVER['REQUEST_METHOD'] != $method ) {
           $this->terminate(405, 'Method not allowed');
      }
   }
    function getJsonPostBody() {
        $json = json_decode(file_get_contents("php://input"), true);
        return $json;
    }
}
