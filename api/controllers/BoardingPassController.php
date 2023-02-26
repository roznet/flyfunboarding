<?php

class BoardingPassController {

    public function index() {
        include_once( 'samples.php' );
        $boardingPass = new BoardingPass($sample_ticket);
        $boardingPass->create_pass();
    }

    public function list() {
    }
}
