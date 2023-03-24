<?php

class TicketController extends Controller {

    function index($params) {
        $this->validateMethod('GET');

        $ticket_id = $this->paramByPositionOrGet($params, 'ticket_id', 0);
        $ticket = MyFlyFunDb::$shared->getTicket($ticket_id);
        if( is_null($ticket) ) {
            $this->terminate(400, 'Ticket not found');
        }
        $json = json_encode($ticket);
        $this->contentType('application/json');
        echo $json;
    }

    function index_delete($params) {
        $this->validateMethod('DELETE');

        $ticket_id = $this->paramByPositionOrGet($params, 'ticket_id', 0);
        $ticket = MyFlyFunDb::$shared->getTicket($ticket_id);
        if( is_null($ticket) ) {
            $this->terminate(400, 'Ticket not found');
        }
        $status = MyFlyFunDb::$shared->deleteTicket($ticket);
        $this->contentType('application/json');
        echo json_encode(array('status'=>$status,'ticket_identifier'=>$ticket->ticket_identifier));
    }

    function issue($params) {
        $this->validateMethod('POST');

        $flight_id = $this->paramByPositionOrGet($params, 'flight_id', 0);
        $passenger_id = $this->paramByPositionOrGet($params, 'passenger_id',1);

        $flight = MyFlyFunDb::$shared->getFlight($flight_id,false);
        $passenger = MyFlyFunDb::$shared->getPassenger($passenger_id,false);


        if( is_null($flight) ) {
            $this->terminate(400, 'Flight not found');
        }
        if( is_null($passenger) ) {
            $this->terminate(400, 'Passenger not found');
        }

        $json = $this->getJsonPostBody();
        $json['flight'] = $flight->toJson();
        $json['passenger'] = $passenger->toJson();

        // Can have only one ticket per passenger per flight
        $existing = MyFlyFunDb::$shared->getTicketByFlightAndPassenger($flight->flight_id, $passenger->passenger_id);
        if( !is_null($existing) ) {
            $json['ticket_identifier'] = $existing->ticket_identifier;
            $json['ticket_id'] = $existing->ticket_id;
        }
        $ticket = Ticket::fromJson($json);
        $ticket->flight_id = $flight->flight_id;
        $ticket->passenger_id = $passenger->passenger_id;
        $ticket = MyFlyFunDb::$shared->createOrUpdateTicket($ticket);
        $json = json_encode($ticket->toJson());
        $this->contentType('application/json');
        echo $json;
    }

    function verify_post() {
        $this->validateMethod('POST');

        $json = $this->getJsonPostBody();
        if( !isset($json['ticket']) ) {
            $this->terminate(400, 'Ticket not found');
        }
        $ticket_id = $json['ticket'];
        $ticket = MyFlyFunDb::$shared->getTicket($ticket_id);
        if( is_null($ticket) ) {
            $this->terminate(400, 'Ticket not found');
        }
        if( $ticket->verify($json) ){
            $json = json_encode($ticket->toJson());
            $this->contentType('application/json');
            echo $json;
        }else{
            $this->terminate(403, 'Ticket not valid');
        }
    }

    function list($params) {
        $this->validateMethod('GET');

        $flight_id = $this->paramByPositionOrGet($params, 'flight_id', 0, true);
        if( $flight_id === null ){
            $flight_id = -1;
        }

        $tickets = MyFlyFunDb::$shared->listTickets($flight_id);
        $json = json_encode($tickets);
        $this->contentType('application/json');
        echo $json;
    }

    function boardingpass($params){
        $this->validateMethod('GET');

        $ticket_id = $this->paramByPositionOrGet($params, 'ticket_id', 0);
        $ticket = MyFlyFunDb::$shared->getTicket($ticket_id, false);
        if( is_null($ticket) ) {
            $this->terminate(400, 'Ticket not found');
        }
        $boardingPass = new BoardingPass($ticket);
        if( isset($_GET['debug']) ) {
            $json = $boardingPass->getPassData();
            header('Content-Type: application/json');
            echo json_encode($json);
        }else{
            header('Content-Type: application/vnd.apple.pkpass');
            $boardingPass->createPass();
        }
    }



}


