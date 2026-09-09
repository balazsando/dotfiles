# Java test conventions

Copy the skeleton; the rules after it are what it cannot show. The quality bar itself is
`clean-code` (FIRST, one concept per test); Cucumber and acceptance tests are `atdd`.

## The canonical test

```java
class OrderServiceTest {
    private OrderRepositoryPort orderRepository;
    private StockPort stock;
    private OrderService underTest;

    @BeforeEach
    void setup() {
        orderRepository = mock(OrderRepositoryPort.class);
        stock = mock(StockPort.class);
        underTest = new OrderService(orderRepository, stock);
    }

    @Test
    void testPlace() {
        // given
        var command = PlaceOrderCommand.builder()
            .lineItems(List.of(new LineItem("SKU-1", 2)))
            .build();
        when(stock.reserve(command.lineItems())).thenReturn(Reservation.accepted("RES-1"));
        when(orderRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        // when
        var order = underTest.place(command, new CustomerId("C-1"));

        // then
        assertEquals("RES-1", order.reservationId());
    }

    @Test
    void testPlaceOutOfStock() {
        // given
        var command = PlaceOrderCommand.builder()
            .lineItems(List.of(new LineItem("SKU-9", 1)))
            .build();
        when(stock.reserve(command.lineItems())).thenReturn(Reservation.rejected("SKU-9"));

        // when / then
        assertThrows(OutOfStockException.class, () -> underTest.place(command, new CustomerId("C-1")));
    }
}
```

That skeleton is showing: the class and its methods are package-private; the instance under test
is `underTest`; collaborators are plain `mock()` fields built in `@BeforeEach`; the name is
`test<MethodUnderTest>` plus the case when one method has several; and every test is marked
`// given`, `// when`, `// then`.

## Rules the skeleton cannot show

- Test observable behaviour, not implementation details.
- Unit-test business logic; integration-test adapters.
- POJOs, configuration classes and straightforward delegation get no test at all.
- Mock external dependencies only.
- Parameterise when several inputs prove the same behaviour, rather than copying the method.
- Prefer test-first iterations: failing test → minimal implementation → refactor.
- Keep tests deterministic and readable. Past those markers, a test that needs a comment to be
  understood is a smell.
