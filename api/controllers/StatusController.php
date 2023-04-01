<?php

class StatusController extends Controller
{
    public function index() {
        try {
            $status = MyFlyFunDb::$shared->status();
            if ($status) {
                $message = 'OK';
            } else {
                $message = 'Error';
            }
        } catch (Exception $e) {
            $status = false;
            $message = "code: " . $e->getCode();
        }
        $json = [
            'status' => $status,
            'message' => $message
        ];

        $this->contentType('application/json');
        $response = json_encode($json);

        if($status) {
            echo $response;
        } else {
            http_response_code(404);
            echo $response;
        }
    }
            
}
