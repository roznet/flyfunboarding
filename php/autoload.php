<?php

function php_autoload($class_name) {
	$baseName = str_replace('\\', '/', $class_name) . '.php';
	print( $baseName . PHP_EOL );
	foreach (array('.', 'php', '../php') as $dir) {
		$fileName = $dir . '/' . $baseName ;
		print( $fileName . PHP_EOL );
		if (file_exists($fileName)) {
			require_once $fileName;
		}
	}
}
spl_autoload_register('php_autoload');
?>
