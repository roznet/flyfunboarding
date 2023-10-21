<?php

function php_autoload($class_name) {
	$baseName = str_replace('\\', '/', $class_name) . '.php';
	foreach (array('.', 'php', '../php') as $dir) {
		$fileName = $dir . '/' . $baseName ;
		if (file_exists($fileName)) {
			require_once $fileName;
		}
	}
}
spl_autoload_register('php_autoload');
