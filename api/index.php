<?php
include_once( '../php/autoload.php' );

if (isset($_GET['url'])) {
    $url = $_GET['url'];

    $dispatcher = new Dispatch($url);

    if (!$dispatcher->dispatch()) {
        return;
    } 
    return;

}
