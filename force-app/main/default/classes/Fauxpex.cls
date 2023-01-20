public with sharing class Fauxpex {
	public class Invocation {
		public Object stubbedObject { public get; private set; }
		public String stubbedMethodName { public get; private set; }
		public Type returnType { public get; private set; }
		public Type[] listOfParamTypes { public get; private set; }
		public String[] listOfParamNames { public get; private set; }
		public Object[] listOfArgs { public get; private set; }

		public Invocation(
			Object stubbedObject,
			String stubbedMethodName,
			Type returnType,
			Type[] listOfParamTypes,
			String[] listOfParamNames,
			Object[] listOfArgs
		) {
			this.stubbedObject = stubbedObject;
			this.stubbedMethodName = stubbedMethodName;
			this.returnType = returnType;
			this.listOfParamTypes = listOfParamTypes;
			this.listOfParamNames = listOfParamNames;
			this.listOfArgs = listOfArgs;
		}
	}

	public interface Stub {
		Object invoke(Invocation invocation);
	}

	public class ReturnStub implements Stub {
		private Object returnValue;

		public ReturnStub(Object returnValue) {
			this.returnValue = returnValue;
		}

		public Object invoke(Invocation invocation) {
			return this.returnValue;
		}
	}

	public class ConsecutiveReturnSub implements Stub {
		private Object[] returnValues;
		private Integer invocationCount;

		public ConsecutiveReturnSub(Object[] returnValues) {
			this.returnValues = returnValues;
			this.invocationCount = 0;
		}

		public Object invoke(Invocation invocation) {
			Object returnValue = this.returnValues.get(this.invocationCount);

			this.invocationCount++;

			return returnValue;
		}
	}

	public class ExceptionStub implements Stub {
		private Exception throwable;

		ExceptionStub(Exception throwable) {
			this.throwable = throwable;
		}

		public Object invoke(Invocation invocation) {
			throw this.throwable;
		}
	}

	public class Matcher {
		private InvocationRule invocationRule;

		private ParametersRule parametersRule { private get; set; }

		private String methodName;

		private Stub stub;

		public Matcher(InvocationRule invocationRule) {
			this.invocationRule = invocationRule;
			this.parametersRule = new AnyParameters();
		}

		public void setMethodName(String methodName) {
			this.methodName = methodName;

			this.invocationRule.setMethodName(methodName);
		}

		public Boolean matchesMethodName(String methodName) {
			return this.methodName == methodName;
		}

		public void setStub(Stub stub) {
			this.stub = stub;
		}

		public Object invoked(Invocation invocation) {
			this.invocationRule.invoked(invocation);
			this.parametersRule.invoked(invocation);

			if (this.stub != null) {
				// throw new ExceptionOfSorts();
			}

			return this.stub.invoke(invocation);
		}

		public Boolean matches(Invocation invocation) {
			if (!this.matchesMethodName(invocation.stubbedMethodName)) {
				return false;
			}

			return this.invocationRule.matches(invocation);
		}
	}

	public class InvocationMockBuilder {
		private MockBuilder mockBuilder;

		private Matcher matcher;

		private String methodName;

		public InvocationMockBuilder(MockBuilder mockBuilder, Matcher matcher) {
			this.mockBuilder = mockBuilder;
			this.matcher = matcher;
		}

		public InvocationMockBuilder method(String methodName) {
			this.methodName = methodName;
			this.matcher.setMethodName(methodName);

			return this;
		}

		public void will(Stub stub) {
			this.matcher.setStub(stub);
		}

		public void willReturn(Object returnValue) {
			this.will(new ReturnStub(returnValue));
		}

		public void willThrow(Exception throwable) {
			this.will(new ExceptionStub(throwable));
		}

		public void willReturnOnConsecutiveCalls(Object[] returnValues) {
			this.will(new ConsecutiveReturnSub(returnValues));
		}

        public void toHaveBeenCalledTimes(Integer expectedCallCount) {
            Integer callCount = 0;

            for (Invocation invocation : this.mockBuilder.invocations) {
                if (this.methodName == invocation.stubbedMethodName) {
                    callCount++;
                }
            }

            Assert.areEqual(expectedCallCount, callCount, 'Unexpected number of calls for method: ' + this.methodName);
		}

        public void toHaveBeenCalledWith(Object parameter) {
            this.toHaveBeenCalledWith(new Object[]{parameter});
		}
        
        public void toHaveBeenCalledWith(Object[] expectedArguments) {
            for (Invocation invocation : this.mockBuilder.invocations) {
                if (invocation.stubbedMethodName != this.methodName) {
                    continue;
                }

                Object[] args = invocation.listOfArgs;

                // Supporting overloading
                if (expectedArguments.size() != args.size()) {
                    continue;
                }

                Boolean matched = false;

                for (Integer i = 0; i < args.size(); i++) {
				    Object expectedArgument = expectedArguments[i];
				    Object argument = args[i];

                    matched = argument == expectedArgument;

                    if (!matched) {
                        break;
                    }
			    }

                if (matched) {
                    return;
                }
            }

            Assert.areEqual(null, expectedArguments, 'Expected method ' + this.methodName + ' to have been called with: ' + expectedArguments);
		}
	}

	public abstract class InvocationRule {
		private Invocation[] invocations = new List<Invocation>();

		private String methodName;

		public void invoked(Invocation invocation) {
			this.invocations.add(invocation);
		}

		public Integer getInvocationCount() {
			return this.invocations.size();
		}

		public void setMethodName(String methodName) {
			this.methodName = methodName;
		}

		public Invocation[] getInvocations() {
			return new List<Invocation>(this.invocations);
		}

		protected String getMethodName() {
			return this.methodName;
		}

		abstract Boolean matches(Invocation invocation);
	}

	public class InvocationRuleAny extends InvocationRule {
		public override Boolean matches(Invocation invocation) {
			return true;
		}
	}

	public class InvocationRuleCallTimes extends InvocationRule {
		private Integer numberOfCalls;

		public InvocationRuleCallTimes(Integer numberOfCalls) {
			this.numberOfCalls = numberOfCalls;
		}

		public override Boolean matches(Invocation invocation) {
			return true;
		}
	}

	public interface ParametersRule {
		void invoked(Invocation invocation);
	}

	public class AnyParameters implements ParametersRule {
		private Invocation[] invocations = new List<Invocation>();

		public void invoked(Invocation invocation) {
			this.invocations.add(invocation);
		}
	}

	public class Parameters implements ParametersRule {
		String methodName;

		Object[] expectedArguments;

		Object[][] arguments;

		Parameters(String methodName, Object[] expectedArguments) {
			this.methodName = methodName;
			this.expectedArguments = expectedArguments;
			this.arguments = new List<List<Object>>();
		}

		public void invoked(Invocation invocation) {
			this.arguments.add(invocation.listOfArgs);
		}

		private void verifyArguments(Object[] args) {
			this.verifyArgumentCount(args.size());

			for (Integer i = 0; i < args.size(); i++) {
				Object expectedArgument = this.expectedArguments[i];
				Object argument = args[i];

				System.assertEquals(
					expectedArgument,
					argument,
					'A bit simplistic but ideas are there'
				);
			}
		}

		private void verifyArgumentCount(Integer argumentSize) {
			Integer expectedArgumentSize = this.expectedArguments.size();

			System.assertEquals(
				expectedArgumentSize,
				argumentSize,
				'Unexpected number of arguments for method ' + this.methodName
			);
		}
	}

	public class MockBuilder {
        public Invocation[] invocations = new Invocation[]{};

		private Type typeToMock;
		private Matcher[] matchers;

		public MockBuilder(Type typeToMock) {
			this.typeToMock = typeToMock;

			this.matchers = new List<Matcher>();
		}

		public MockBuilder(String className) {
			this(Type.forName(className));
		}

		public InvocationMockBuilder method(String methodName) {
			return this.expects(new InvocationRuleAny()).method(methodName);
		}

		public InvocationMockBuilder expects(InvocationRule invocationRule) {
			Matcher matcher = new Matcher(invocationRule);

			this.matchers.add(matcher);

			return new InvocationMockBuilder(this, matcher);
		}

		public Object createStub() {
			return Test.createStub(this.typeToMock, new MockProvider(this));
		}

		public Object invoke(Invocation invocation) {
            this.invocations.add(invocation);

			for (Matcher matcher : this.matchers) {
				if (matcher.matches(invocation)) {
					return matcher.invoked(invocation);
				}
			}

			return null;
		}
	}

	public class MockProvider implements System.StubProvider {
		private MockBuilder mockBuilder;

		public MockProvider(MockBuilder mockBuilder) {
			this.mockBuilder = mockBuilder;
		}

		public Object handleMethodCall(
			Object stubbedObject,
			String stubbedMethodName,
			Type returnType,
			List<Type> listOfParamTypes,
			List<String> listOfParamNames,
			List<Object> listOfArgs
		) {
			return this.mockBuilder.invoke(
				new Invocation(
					stubbedObject,
					stubbedMethodName,
					returnType,
					listOfParamTypes,
					listOfParamNames,
					listOfArgs
				)
			);
		}
	}
}