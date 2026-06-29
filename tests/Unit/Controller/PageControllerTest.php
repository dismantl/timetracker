<?php

namespace OCA\TimeTracker\Tests\Unit\Controller;

use PHPUnit\Framework\TestCase;

use OCP\AppFramework\Http\TemplateResponse;

use OCA\TimeTracker\Controller\PageController;


class PageControllerTest extends TestCase {
	private $controller;
	private $userId = 'john';

	protected function setUp(): void {
		$request = $this->getMockBuilder('OCP\IRequest')->getMock();

		$this->controller = new PageController(
			'timetracker', $request, $this->userId
		);
	}

	public function testIndex() {
		$result = $this->controller->index();

		$this->assertEquals('index', $result->getTemplateName());
		$this->assertTrue($result instanceof TemplateResponse);
	}

}
