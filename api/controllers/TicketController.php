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
        $ticket = Ticket::fromJson($json);
        $ticket->flight_id = $flight->flight_id;
        $ticket->passenger_id = $passenger->passenger_id;
        $ticket = MyFlyFunDb::$shared->createOrUpdateTicket($ticket);
        $json = json_encode($ticket->toJson());
        $this->contentType('application/json');
        echo $json;
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

    function boardingPass($params){
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


