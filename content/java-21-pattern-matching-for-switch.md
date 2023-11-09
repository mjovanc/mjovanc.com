+++
title = "Java 21 - Pattern Matching for switch"
description = "Java 21 is now out and with it comes a good amount of new features. But in this article we are going to be focusing on the most exciting one, virtual threads."
date = 2023-11-05
path = "java/java-21-pattern-matching-for-switch"

[taxonomies]
categories = ["java"]
tags = ["java", "jdk21"]
+++

Java has now extended the pattern matching feature to switch statements. This allows an expression to be tested against a number of patterns, each for a specific action. It enables complex data-oriented queries to be expressed concisely and safely.
<!-- more -->
This new feature has co-evolved with [Record Patterns](https://openjdk.org/jeps/440) feature (JEP 440), it proposes to finalize the feature with additional small refinements that are based upon continued experience and feedback. The main changes from the previous JEP are:

- Removing paraenthesized patterns
- Allow for qualified enum constants, case constants in switch expressions and statements

## Introduction

The goals of the JDK enhancement proposal were to expand the epressiveness and applicability for switch expressions and statements by allowing patterns to be used in case labels. It also allows for historical null-hostility of switch to be more easy when desired. It also increases the safety of switch statements by requiring that the pattern switch statements will cover all the possible input values. Also, it ensures that all exisiting switch expressions and statements will continue to compile with zero changes and execute with identical semantics.

Unfortunately _prior_ to Java 21, switch was very limited. There was only possible to switch on values of a few types. The corresponding boxed forms, enum types and `String`, excluding `long`. We could only test for exact equality against constants. We might want to use patterns to test the same variable against a number of different possibilities and by taking action on each of of them, but since the early `switch` didn't support it, we end up with a chain of if/else. 

An example _prior_ to Java 21 would be:

```java
static String formatter(Object obj) {
    String formatted = "unknown";

    if (obj instanceof Integer i) {
        formatted = String.format("int %d", i);
    } else if (obj instanceof Long l) {
        formatted = String.format("Long %d", l);
    } else if (obj instanceof Double d) {
        formatted = String.format("Double %f", d);
    } else if (obj instanceof String s) {
        formatted = String.format("String %s", s);
    }

    return formatted;
}
```

This might feel familiar, it benefits from using `instanceof` expression pattern. But it's not good enough. This approach allows for possible coding errors to be remained hidden since we are using an overly general control construct. But using a `switch` is a perfect match for pattern matching. 

We can rewrite all of the code above to a more clearly an reliable piece of code since extending `switch` statements and expressions to work on any type allows for case labels with patterns rather than just constants.

An example _with_ Java 21 would be:

```java
static String formatterPatternSwitch(Object obj) {
    return switch (obj) {
        case Integer i -> String.format("int %d", i);
        case Long l    -> String.format("long %d", l);
        case Double d  -> String.format("double %f", d);
        case String s  -> String.format("String %s", s);
        default        -> obj.toString();
    }; 
}
```

As you can see, the `switch` semantics are very clear. A case label with a pattern applies if the value of the selector expression `obj` matches the pattern. We also see that the intent of the code is much clearer since we are using the right control construct. As a bonus, this code is more optimizable, we are likely to be able to perform the dispatch in O(1) time.

## Switches and null

Using `switch` statements and expressions traditionally throw `NullPointerException` if the selector expression evaluates to `null`, so the testing for `null` should be done outside of the `switch`. 

An example _prior_ to Java 21 would be:

```java
static void testFooBar(String s) {
    if (s == null) {
        System.out.println("Ouch!");
        return;
    }
    switch (s) {
        case "Foo", "Bar" -> System.out.println("Super");
        default           -> System.out.println("OK");
    }
}
```

This was a reasonable approach when `switch` supported only a few reference types. But, if `switch` allows a selector expression of any reference type and case labels can have type patterns. In that case, the standalone `null` test feels like an arbitrary dinstiction that invites a needless boilerplate and opportunities for errors. The perferable way is to integrate the `null` test into the switch by allowing a new `null` case label. 

An example _with_ Java 21 would be:

```java
static void testFooBar(String s) {
    switch (s) {
        case null         -> System.out.println("Ouch");
        case "Foo", "Bar" -> System.out.println("Super");
        default           -> System.out.println("OK");
    }
}
```

We can always determine `null` by using it as a case label in the `switch`. Without a case `null`, the `switch` throws `NullPointerException`, just as in previous Java versions. To keep backward compatibility with the current semantics of `switch`, the default label do not match a `null` selector.

## Case refinement

By constrast to case labels with constants, we can apply many values by using a pattern case label. 



## Switches and enum constants

## Improved enum constant case labels

## Patterns in switch labels

## Enhanced type checking

### Selector expression typing

### Dominance of case labels

## Exhaustiveness of switch expressions and statements

### Type coverage

### Exhaustiveness in practice

### Exhaustiveness and sealed classes

### Exhaustiveness and compatibility

## Scope of pattern variable declarations

## Dealing with null

## Errors

## Summary

So now you probably know a little bit more about Pattern Matching for switch. Feel free to contribute to my repo (link below). I will make sure the article is up-to-date and accurate. 

The repository used you can find here: [https://github.com/mjovanc/java-21-pattern-matching-for-switch](https://github.com/mjovanc/java-21-pattern-matching-for-switch)

If you found it valuable, please consider sharing it, as it might also be valuable to others. Let me know if you have any questions by reaching me on 𝕏!

## Resources

- [JEP 441](https://openjdk.org/jeps/441)
- [JEP 440](https://openjdk.org/jeps/440)

## Connect with me
- [𝕏](https://x.com/mjovanc)
- [GitHub](https://github.com/mjovanc)
- [LinkedIn](https://www.linkedin.com/in/marcuscvjeticanin/)