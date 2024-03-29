<?php

class BoardingPassController extends Controller {

    public function index($params) {
        $this->validateMethod('GET');

        $ticket_id = $this->paramByPositionOrGet($params, 'ticket_id', 0);
        $ticket = MyFlyFunDb::$shared->directGetTicket($ticket_id);
        if( is_null($ticket) ) {
            $this->terminate(400, 'Ticket not found '.$ticket_id);
        }
        $boardingPass = new BoardingPass($ticket);
        if( isset($_GET['debug']) ) {
            $json = $boardingPass->getPassData();
            header('Content-Type: application/json');
            echo json_encode($json);
        }else{
            header('Content-Type: application/vnd.apple.pkpass');
            header('Content-Disposition: attachment; filename="boardingpass.pkpass"');
            $boardingPass->createPass();
        }
    }

}
