@IsTest(isParallel=true)
class MyMockableClassTest {
	@IsTest
	public static void testWillReturn_returnsValue() {
		Fauxpex.MockBuilder mockableClassMock = new Fauxpex.MockBuilder('MyMockableClass');

		String expectedValue = 'Hi there';

		mockableClassMock.method('testMyStuff').willReturn(expectedValue);

		MyMockableClass myMock = (MyMockableClass) mockableClassMock.createStub();

		Test.startTest();
		String returnValue = myMock.testMyStuff('');
		Test.stopTest();

		System.assertEquals(expectedValue, returnValue, 'Unexpected return value');
	}

	@IsTest
	public static void testWillThrow_throwsException() {
		Fauxpex.MockBuilder mockableClassMock = new Fauxpex.MockBuilder('MyMockableClass');

		mockableClassMock.method('testMyStuff').willThrow(new TestException('Boop'));

		MyMockableClass myMock = (MyMockableClass) mockableClassMock.createStub();

		Exception caughtException;

		Test.startTest();
		try {
			myMock.testMyStuff('');
		} catch (Exception e) {
			caughtException = e;
		}
		Test.stopTest();

		System.assert(caughtException instanceof TestException, 'Unexpected Exception thrown');
		System.assertEquals('Boop', caughtException.getMessage(), 'Unexpected exception message');
	}

	@IsTest
	public static void callCount_failsAssertion_notEnoughCalls() {
		Fauxpex.MockBuilder mockableClassMock = new Fauxpex.MockBuilder('MyMockableClass');

		mockableClassMock.method('testMyStuff').willReturn('Hello there');

		MyMockableClass myMock = (MyMockableClass) mockableClassMock.createStub();

		Test.startTest();
		myMock.testMyStuff('');
        myMock.testMyStuff('');
		Test.stopTest();

        mockableClassMock.method('testMyStuff').toHaveBeenCalledTimes(2);
	}

	@IsTest
	public static void callCount_withConsecutiveCalls_allReturnsAsExpected() {
		Fauxpex.MockBuilder mockableClassMock = new Fauxpex.MockBuilder('MyMockableClass');

		mockableClassMock
			.method('testMyStuff')
			.willReturnOnConsecutiveCalls(
				new List<String>{
					'Hello there',
					'I am the second call'
				}
			);

		MyMockableClass testMock = (MyMockableClass) mockableClassMock.createStub();

        Test.startTest();
        String resultOne = testMock.testMyStuff('One');
        String resultTwo = testMock.testMyStuff('Two');
        Test.stopTest();

		System.assertEquals('Hello there', resultOne, 'Unexpected return value from the first call');
		System.assertEquals(
			'I am the second call',
			resultTwo,
			'Unexpected return value from the second call'
		);

		mockableClassMock.method('testMyStuff').toHaveBeenCalledTimes(2);
	}

	@IsTest
	public static void testingArgumentCapture() {
		Fauxpex.MockBuilder mockableClassMock = new Fauxpex.MockBuilder('MyMockableClass');

		mockableClassMock.method('testMyStuff').willReturn('Hello there');

		MyMockableClass myMock = (MyMockableClass) mockableClassMock.createStub();

		Test.startTest();
		myMock.testMyStuff('NANI!?');
		myMock.testMyStuff('You weren\'t suppposed to do that');
		Test.stopTest();

		mockableClassMock.method('testMyStuff').toHaveBeenCalledWith('NANI!?');
        mockableClassMock.method('testMyStuff').toHaveBeenCalledWith('You weren\'t suppposed to do that');
	}

	@IsTest
	public static void testingMultipleArgumentCapture() {
		Fauxpex.MockBuilder mockableClassMock = new Fauxpex.MockBuilder('MyMockableClass');

		mockableClassMock.method('testMyStuff')
			.will(
                new ReturnWhen(
                    new Map<String, String>{
                        'NANI!?' => 'Hi',
                        'Wait' => 'What?'
                    }
                )
            );

		MyMockableClass myMock = (MyMockableClass) mockableClassMock.createStub();

		Test.startTest();
        String resultOne = myMock.testMyStuff('Wait');
		String resultTwo = myMock.testMyStuff('NANI!?');
		Test.stopTest();

        System.debug('resultOne: ' + resultOne);

        Assert.areEqual('What?', resultOne, 'Unexpected return value for input Wait');
        Assert.areEqual('Hi', resultTwo, 'Unexpected return value for NANI!?');
	}

    /**
     * Example of mocking a return when a specific parameter is provided.
     */
    class ReturnWhen implements Fauxpex.Stub {
        Map<String, String> resultByParam;

        public ReturnWhen(Map<String, String> resultByParam) {
            this.resultByParam = resultByParam;
        }

        public Object invoke(Fauxpex.Invocation invocation) {
            return this.resultByParam.get((String) invocation.listOfArgs[0]);
        }
    }
}