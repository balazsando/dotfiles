# Design Patterns Reference

Canonical sources (priority order):

1. [Refactoring.Guru — Design Patterns](https://refactoring.guru/design-patterns) — GoF
2. [Martin Fowler — EAA Catalog](https://martinfowler.com/eaaCatalog/) — Enterprise
3. [SourceMaking — Design Patterns](https://sourcemaking.com/design_patterns) — GoF supplement

When sources differ: Refactoring.Guru for GoF; Fowler for enterprise application patterns.

---

## Applicability Checklist

Apply a pattern only when **all** are true:

- [ ] A concrete variation point exists (not hypothetical)
- [ ] The variation is likely to grow or already has multiple forms
- [ ] The pattern reduces coupling or duplication more than it adds indirection
- [ ] The team can understand the pattern name and intent in this codebase
- [ ] The framework does not already solve the problem

---

## GoF — Creational

| Pattern | Use when | Skip when | Java 21 notes |
|---------|----------|-----------|---------------|
| **Factory Method** | Subclasses/products decide which concrete type to create | Single product type; Spring/container owns creation | Prefer supplier functions or registry maps for simple cases |
| **Abstract Factory** | Families of related products must stay consistent | Only one product family or one product type | Rare in modern DI-heavy apps |
| **Builder** | Many optional parameters; stepwise construction | ≤4 constructor params or a compact record suffices | Records + static factory or nested builder |
| **Prototype** | Clone expensive-to-build objects; preserve state | `copy`/`clone` is trivial; immutability is enough | Prefer records + `with`-style methods |
| **Singleton** | Truly one instance in process (rare) | Testability needs multiple instances; use DI scope instead | Let the container manage lifecycle |

---

## GoF — Structural

| Pattern | Use when | Skip when | Java 21 notes |
|---------|----------|-----------|---------------|
| **Adapter** | Integrate legacy/third-party API behind your interface | You control both sides — change the API instead | Wrapper class implementing target interface |
| **Bridge** | Abstraction and implementation vary independently | One dimension of variation only | Composition over dual inheritance |
| **Composite** | Tree structures; treat leaves and containers uniformly | Flat lists; no recursive structure | Sealed hierarchy for closed tree types |
| **Decorator** | Add behavior dynamically without subclass explosion | Few fixed variants; composition list is enough | Prefer small composed behaviors over deep decorator chains |
| **Facade** | Simplify a complex subsystem for callers | Subsystem is already small and cohesive | Thin orchestration class |
| **Flyweight** | Huge numbers of similar objects; shared intrinsic state | Object count is modest; premature memory optimization | `Map` cache of shared immutable state |
| **Proxy** | Lazy load, access control, remote stub | Framework AOP or interceptors already cover it | JDK dynamic proxy or manual delegate |

---

## GoF — Behavioral

| Pattern | Use when | Skip when | Java 21 notes |
|---------|----------|-----------|---------------|
| **Chain of Responsibility** | Multiple handlers; sender unaware of receiver | Fixed single handler; `if/else` is clearer | `Optional` return to pass along chain |
| **Command** | Encapsulate requests; undo/redo; queue operations | Direct method calls are sufficient | Records for immutable commands |
| **Iterator** | Traverse aggregate without exposing internals | `for-each` / streams already suffice | Use `Iterable` or streams |
| **Mediator** | Many peers would otherwise reference each other | Few objects; direct collaboration is clear | Event bus only if event volume justifies it |
| **Memento** | Snapshot/restore internal state | State is immutable or persistence handles history | Records for snapshots |
| **Observer** | One-to-many notification on state change | Framework events (Spring `ApplicationEvent`) fit better | Prefer domain events + listener interfaces |
| **State** | Behavior changes with internal state; large conditionals | Few states; `switch` on enum/ sealed type is enough | Sealed interface + record states + pattern switch |
| **Strategy** | Interchangeable algorithms at runtime | One algorithm; no variation | `Function`/`Predicate` for trivial strategies |
| **Template Method** | Fixed skeleton, subclass hooks | Hooks are one-liners; favor composition | Prefer composed steps over inheritance |
| **Visitor** | New operations on stable object structure | Structure changes often; double dispatch cost hurts | Sealed types + pattern switch often replace Visitor |

---

## Fowler — Enterprise Application Architecture (selected)

| Pattern | Use when | Skip when | Notes |
|---------|----------|-----------|-------|
| **Domain Model** | Rich behavior in domain objects | Anemic CRUD with no rules | Keep persistence out of entities |
| **Transaction Script** | Simple procedural use-cases | Growing conditional complexity | Procedural is fine for small domains |
| **Table Data Gateway** | Single-table CRUD gateway | Rich domain + ORM mapper exists | Thin JDBC/DAO per table |
| **Row Data Gateway** | One object per row, simple CRUD | JPA entity already maps row | Legacy JDBC systems |
| **Active Record** | Object carries persistence (Rails-style) | Layered architecture with separate persistence | Rare in strict Java enterprise layering |
| **Data Mapper** | Separate domain from DB mapping | Simple CRUD; JPA is enough | Repository + JPA/Hibernate |
| **Repository** | Collection-like access to aggregates | Direct DAO everywhere duplicates query logic | Interface in domain; impl in infrastructure |
| **Unit of Work** | Track changes; commit as one transaction | Single-entity saves; framework `@Transactional` enough | Often implicit in ORM session |
| **Identity Map** | Ensure one in-memory instance per DB row | Stateless services; no shared session | ORM first-level cache |
| **Lazy Load** | Defer expensive associations | Always need data; N+1 risk unmanaged | JPA `FetchType.LAZY` with care |
| **Service Layer** | Orchestrate use-cases, transactions, security | Controller → repository is enough for trivial apps | `@Service` boundary in Spring |
| **DTO** | Cross boundary data transfer | Internal domain — don't DTO everything | Records for DTOs |
| **Remote Facade** | Coarse-grained remote API | Fine-grained RPC chatty calls | REST resource as facade |
| **Gateway** | Isolate external system API | Single call; no mapping complexity | Anti-corruption layer for integrations |

---

## Common Smells — Pattern Misuse

| Smell | Likely issue | Simpler fix |
|-------|--------------|-------------|
| Interface with one impl forever | Speculative abstraction | Concrete class until second impl exists |
| `Abstract` + `Base` + `Impl` chain | Over-layered hierarchy | Flatten; compose behaviors |
| Factory for every object | Factory fever | DI container or direct construction |
| Strategy for two `if` branches | Premature polymorphism | `switch` on enum/sealed type |
| God Object implementing half the GoF catalog | Pattern accumulation | Split by responsibility (SRP) |
| DTO mapping every layer | Boundary obsession | Map only at true boundaries |

---

## Java 21 — Pattern-Friendly Idioms

**Sealed hierarchy + switch** — often replaces State, Visitor, or large `instanceof` chains:

```java
public sealed interface PaymentResult permits Approved, Declined, Pending {
    record Approved(String authCode) implements PaymentResult {}
    record Declined(String reason) implements PaymentResult {}
    record Pending(String reference) implements PaymentResult {}
}

public String message(PaymentResult result) {
    return switch (result) {
        case Approved(var code) -> "Approved: " + code;
        case Declined(var reason) -> "Declined: " + reason;
        case Pending(var ref) -> "Pending: " + ref;
    };
}
```

**Strategy via functional interface** — when behavior is a single method:

```java
public final class PriceCalculator {
    private final Function<LineItem, BigDecimal> discountRule;

    public PriceCalculator(Function<LineItem, BigDecimal> discountRule) {
        this.discountRule = discountRule;
    }

    public BigDecimal total(List<LineItem> items) {
        return items.stream()
            .map(item -> item.price().subtract(discountRule.apply(item)))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
```

**Repository boundary** — domain interface, infrastructure implementation:

```java
public interface OrderRepository {
    Optional<Order> findById(OrderId id);
    void save(Order order);
}
```

Keep implementations in the infrastructure module; inject via constructor in application services.
