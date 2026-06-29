<?php

$nextcloudRoot = getenv('NEXTCLOUD_ROOT') ?: realpath(__DIR__ . '/../../..');
$nextcloudRoot = $nextcloudRoot ? rtrim($nextcloudRoot, DIRECTORY_SEPARATOR) : null;

if ($nextcloudRoot === null) {
    throw new RuntimeException('Unable to resolve Nextcloud root. Set NEXTCLOUD_ROOT=/path/to/nextcloud.');
}

$nextcloudTestBootstrap = $nextcloudRoot . '/tests/bootstrap.php';
$nextcloudBase = $nextcloudRoot . '/lib/base.php';

if (is_file($nextcloudTestBootstrap)) {
    require_once $nextcloudTestBootstrap;
} elseif (is_file($nextcloudBase)) {
    if (!defined('PHPUNIT_RUN')) {
        define('PHPUNIT_RUN', 1);
    }

    require_once $nextcloudBase;

    // Fix for "Autoload path not allowed: .../tests/lib/testcase.php"
    \OC::$loader->addValidRoot(\OC::$SERVERROOT . '/tests');
} else {
    throw new RuntimeException(
        'Nextcloud bootstrap not found. Set NEXTCLOUD_ROOT=/path/to/nextcloud or run tests from nextcloud/apps/timetracker.'
    );
}

if (!class_exists('PHPUnit_Framework_TestCase') && class_exists(\PHPUnit\Framework\TestCase::class)) {
    class_alias(\PHPUnit\Framework\TestCase::class, 'PHPUnit_Framework_TestCase');
}

// Fix for "Autoload path not allowed: .../timetracker/tests/testcase.php"
\OC_App::loadApp('timetracker');

\OC_Hook::clear();
