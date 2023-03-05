<?php

class BoardingPassController extends Controller {

    public function index($params) {
        $this->validateMethod('GET');

        $ticket_id = $this->paramByPositionOrGet($params, 'ticket_id', 0);
        $ticket = MyFlyFunDb::$shared->getTicket($ticket_id, false);
        if( is_null($ticket) ) {
            $this->terminate(400, 'Ticket not found');
        }
        $boardingPass = new BoardingPass($ticket);
        $boardingPass->create_pass();
    }

}
