# Canonical shapes

Inbound port and application service first — copy those. Then package layout, adapter, domain
types. Same house formatter: 4 spaces, 120 columns, continuation indented one level, LF.

Rules those examples cannot show: [SKILL.md](../SKILL.md).

## Inbound port and application service

An application service and the port it implements. Almost every class in a service follows this
shape.

```java
package com.example.ordering.application.ports.in;

/**
 * Inbound port for placing an order.
 *
 * <p>Protocol-agnostic: any inbound adapter (REST, SOAP, messaging) calls this after
 * authenticating the caller, so no transport type appears in the signature.
 */
public interface PlaceOrderUseCase {
    /**
     * Places an order for the given customer and reserves its stock.
     *
     * @param command    the validated order request
     * @param customerId the authenticated caller
     * 
     * @return the accepted order, with its generated reference
     * @throws OutOfStockException when a line item cannot be reserved
     */
    Order place(PlaceOrderCommand command, CustomerId customerId);
}
```

```java
package com.example.ordering.application.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Application service for the order-placement use case.
 *
 * <p>Orchestrates the domain and the outbound ports; holds no transport or persistence
 * detail of its own.
 */
@Service
@RequiredArgsConstructor
public class OrderService implements PlaceOrderUseCase {
    private final OrderRepositoryPort orderRepository;
    private final StockPort stock;

    @Override
    public Order place(PlaceOrderCommand command, CustomerId customerId) {
        var reservation = stock.reserve(command.lineItems());

        if (reservation.isRejected()) {
            throw new OutOfStockException(reservation.rejectedSku());
        }

        var order = Order.accept(command, customerId, reservation);

        return orderRepository.save(order);
    }
}
```

What that class is showing, and what breaking it costs:

| It shows | Because |
| --- | --- |
| `@RequiredArgsConstructor` + `private final` fields | Constructor injection, no `@Autowired`, no hand-written constructor |
| `@Service` on the class | A stereotype declares the bean — not a `@Configuration` + `@Bean` pair |
| `implements PlaceOrderUseCase` | The inbound port is the contract; the service is one implementation |
| `...UseCase` / `...Port` / `...Service` names | Inbound port, outbound port, application service — the name says the role |
| Javadoc on the interface, none on `place` in the impl | Public API carries the contract; `@Override` does not repeat it |
| The early `throw`, then the blank line | Early exit over nesting; one blank line before a `return` or `throw` |
| `var order = ...` then `return` | One operation per line — an intermediate name, not a stacked call chain |

## Package layout (hexagonal service)

```
<module>/src/main/java/com/example/ordering/
  application/
    ports/in/PlaceOrderUseCase.java        ← inbound port: what the service offers
    ports/out/StockPort.java               ← outbound port: what the service needs
    service/OrderService.java              ← use-case orchestration
    exceptions/OutOfStockException.java
  domain/
    order/Order.java                       ← no framework annotations below here
    shared/CustomerId.java
  adapters/
    in/rest/OrderController.java           ← protocol → inbound port
    out/http/HttpStockClient.java          ← outbound port → protocol
  infrastructure/
    config/StockClientConfig.java          ← beans, properties, framework wiring
```

An outbound port is named for what the application needs (`StockPort`), never for the technology
that happens to satisfy it. The adapter is named for the technology (`HttpStockClient`).

## Outbound adapter with configured dependencies

When a dependency needs `@Qualifier` or `@Value`, write the constructor out — Lombok cannot
annotate the parameters. A single constructor still needs no `@Autowired`.

```java
package com.example.ordering.adapters.out.http;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

/**
 * Outbound adapter that reserves stock over HTTP.
 *
 * <p>Translates a transport failure into a rejected {@link Reservation} rather than
 * propagating it: the application layer knows nothing about HTTP status codes.
 */
@Slf4j
@Component
public class HttpStockClient implements StockPort {
    private static final String USER_AGENT_VALUE = "ordering-service";

    private final WebClient client;
    private final String reservePath;
    private final CorrelationIdProvider correlationIds;

    public HttpStockClient(
        @Qualifier("stockWebClient") WebClient client,
        @Value("${stock.reserve.path}") String reservePath,
        CorrelationIdProvider correlationIds
    ) {
        this.client = client;
        this.reservePath = reservePath;
        this.correlationIds = correlationIds;
    }

    @Override
    public Reservation reserve(List<LineItem> lineItems) {
        try {
            return client.post()
                .uri(reservePath)
                .header(HttpHeaders.USER_AGENT, USER_AGENT_VALUE)
                .header(CORRELATION_ID, correlationIds.current())
                .bodyValue(ReserveRequest.of(lineItems))
                .retrieve()
                .bodyToMono(ReserveResponse.class)
                .block()
                .toReservation();
        } catch (WebClientResponseException e) {
            log.warn("Stock reservation failed: {}", e.getStatusCode(), e);

            return Reservation.rejected(e.getStatusCode());
        }
    }
}
```

A wrapped argument list breaks one parameter per line, with the closing `)` on its own line at
the declaration's indent. A fluent chain is the one place a call may span lines — one call per
line, `.` first.

## Domain types

A carrier with no behaviour is a `record` — nothing to generate, nothing to annotate. Reach for
Lombok only when a framework or a builder needs a mutable class; never hand-write the getter.

```java
public record CustomerId(String value) { }

@Data
@Builder
public class OrderDraft {
    private String reference;
    private CustomerId customer;
    private List<LineItem> lineItems;
}
```

## Where the rest goes

- An exception is one class, one failure, no ceremony — unchecked unless the caller can genuinely
  recover.
- Framework wiring (`@Configuration`, `@Bean`) lives in `infrastructure/config`, never beside the
  class it configures.
