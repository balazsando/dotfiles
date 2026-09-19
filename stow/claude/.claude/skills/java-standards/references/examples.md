# Canonical shapes

Inbound port, application service and its wiring first — copy those. Then adapter, domain
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

```java
package com.example.ordering.infrastructure.configuration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OrderingConfiguration {
    @Bean
    PlaceOrderUseCase placeOrderUseCase(OrderRepositoryPort orderRepository, StockPort stock) {
        return new OrderService(orderRepository, stock);
    }
}
```

What that class is showing, and what breaking it costs:

| It shows | Because |
| --- | --- |
| `@RequiredArgsConstructor` + `private final` fields | Constructor injection, no `@Autowired`, no hand-written constructor |
| No stereotype; a `@Bean` in `infrastructure/configuration` | The application layer stays framework-free |
| `implements PlaceOrderUseCase` | The inbound port is the contract; the service is one implementation |
| `...UseCase` / `...Port` / `...Service` names | Inbound port, outbound port, application service — the name says the role |
| Javadoc on the interface only — none on the class or `place` | The contract states what the signature cannot (stock reservation, the thrown exception); implementations do not repeat it |
| The early `throw`, then the blank line | Early exit over nesting; one blank line before a `return` or `throw` |
| `var order = ...` then `return` | One operation per line — an intermediate name, not a stacked call chain |

## Package layout

Layout and port naming: `hexagonal-architecture`. Follow the project's own architecture instead
where it has one.

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

            return Reservation.unavailable();
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
- Framework wiring (`@Configuration`, `@Bean`) lives in `infrastructure/configuration`, never
  beside the class it configures.
