<?php

namespace OCA\TimeTracker\Tests\Unit\Controller;

use PHPUnit\Framework\TestCase;

use OCP\AppFramework\Http\TemplateResponse;
use OCP\IRequest;
use OCP\IUser;
use OCP\IUserSession;

use OCA\TimeTracker\Controller\PageController;


class PageControllerTest extends TestCase {
	private $controller;

	protected function setUp(): void {
		$request = $this->createMock(IRequest::class);
		$user = $this->createMock(IUser::class);
		$userSession = $this->createMock(IUserSession::class);
		$userSession->method('getUser')->willReturn($user);

		$this->controller = new PageController(
			'timetracker', $request, $userSession
		);
	}

	public function testIndex() {
		$result = $this->controller->index();

		$this->assertEquals('index', $result->getTemplateName());
		$this->assertTrue($result instanceof TemplateResponse);
	}

}
