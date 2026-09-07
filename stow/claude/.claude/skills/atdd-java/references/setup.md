# Cucumber setup — dependencies and runner wiring

Once per project. Writing a feature or a step definition does not need this file; adding Cucumber
to a project that does not have it does.

## Dependencies

### Maven

```xml
<properties>
  <cucumber.version>7.22.0</cucumber.version>
</properties>

<dependencies>
  <!-- Core -->
  <dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-java</artifactId>
    <version>${cucumber.version}</version>
    <scope>test</scope>
  </dependency>

  <!-- JUnit 5 runner (recommended) -->
  <dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-junit-platform-engine</artifactId>
    <version>${cucumber.version}</version>
    <scope>test</scope>
  </dependency>
  <dependency>
    <groupId>org.junit.platform</groupId>
    <artifactId>junit-platform-suite</artifactId>
    <scope>test</scope>
  </dependency>
  <dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
  </dependency>

  <!-- OR JUnit 4 runner (legacy) -->
  <!-- <dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-junit</artifactId>
    <version>${cucumber.version}</version>
    <scope>test</scope>
  </dependency> -->
</dependencies>
```

### Gradle (Kotlin DSL)

```kotlin
val cucumberVersion = "7.22.0"
dependencies {
    testImplementation("io.cucumber:cucumber-java:$cucumberVersion")
    testImplementation("io.cucumber:cucumber-junit-platform-engine:$cucumberVersion")
    testImplementation("org.junit.platform:junit-platform-suite")
    testImplementation("org.junit.jupiter:junit-jupiter")
}
```

### PicoContainer (shared state between glue classes)

Needed as soon as two glue classes share a state object — see
[hooks reference](./hooks.md#sharing-state-between-glue-classes).

```xml
<dependency>
  <groupId>io.cucumber</groupId>
  <artifactId>cucumber-picocontainer</artifactId>
  <version>${cucumber.version}</version>
  <scope>test</scope>
</dependency>
```

## Test runner

### JUnit 5 (recommended)

```java
// src/test/java/com/example/runner/RunCucumberTest.java
package com.example.runner;

import org.junit.platform.suite.api.*;

@Suite
@IncludeEngines("cucumber")
@SelectClasspathResource("features")
@ConfigurationParameter(key = "cucumber.glue", value = "com.example.steps")
@ConfigurationParameter(key = "cucumber.plugin", value = "pretty, html:target/cucumber.html")
public class RunCucumberTest {}
```

Or use `src/test/resources/junit-platform.properties`:

```properties
cucumber.glue=com.example.steps
cucumber.plugin=pretty, html:target/cucumber.html
cucumber.publish.quiet=true
```

### JUnit 4 (legacy)

```java
@RunWith(Cucumber.class)
@CucumberOptions(
    features = "src/test/resources/features",
    glue = "com.example.steps",
    plugin = {"pretty", "html:target/cucumber.html"},
    tags = "not @wip"
)
public class RunCucumberTest {}
```

Other DI containers (Spring, Guice, CDI) and their wiring:
[integration reference](./integration.md#dependency-injection-options).
