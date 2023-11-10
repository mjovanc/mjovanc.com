+++
title = "Java 21 - Pattern Matching for switch"
description = "In this second article about Java 21, we are going to go through pattern matching for switch, which has got some real improvements."
date = 2023-11-10
path = "java/java-21-pattern-matching-for-switch"

[taxonomies]
categories = ["java"]
tags = ["java", "jdk21"]
+++

Java has now extended the pattern matching feature to `switch` statements. This allows an expression to be tested against a number of patterns, each for a specific action. It enables complex data-oriented queries to be expressed concisely and safely.
<!-- more -->
This new feature has co-evolved with [Record Patterns](https://openjdk.org/jeps/440) feature (JEP 440), it proposes to finalize the feature with additional small refinements that are based upon continued experience and feedback. The main changes from the previous JEP are:

- Removing paraenthesized patterns
- Allow for qualified enum constants, case constants in switch expressions and statements

## Introduction

The goals of the JDK enhancement proposal were to expand the epressiveness and applicability for switch expressions and statements by allowing patterns to be used in case labels. It also allows for historical null-hostility of switch to be more easy when desired. It also increases the safety of `switch` statements by requiring that the pattern switch statements will cover all the possible input values. Also, it ensures that all exisiting switch expressions and statements will continue to compile with zero changes and execute with identical semantics.

Unfortunately _prior_ to Java 21, `switch` was very limited. There was only possible to switch on values of a few types. The corresponding boxed forms, enum types, `String` (excluding `long`) and we could only test for exact equality against constants. We might want to use patterns to test the same variable against a number of different possibilities and by taking actions on each one of them, but since the early `switch` didn't support it, we end up with a chain of if/else.

A working example _prior_ to Java 21 would be:

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

We can re-write all of the code above to a more clearly an reliable piece of code since extending `switch` statements and expressions to work on any type allows for case labels with patterns rather than just constants.

A working example _with_ Java 21 would be:

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

Using `switch` statements and expressions traditionally throw `NullPointerException` if the selector expression evaluates to `null`, so the testing for `null` was be done outside of the `switch`. 

A working example _prior_ to Java 21 would be:

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

This was a reasonable approach when `switch` supported only a few reference types. But, if `switch` allows a selector expression of any reference type and case labels that can have type patterns. In that case, the standalone `null` test feels like an arbitrary dinstiction that invites a needless boilerplate and opportunities for errors. 

The perferable way is to integrate the `null` test into the switch by allowing a new `null` case label. 

A working example _with_ Java 21 would be:

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

A working example _with_ Java 21 would be:

```java
static void testString(String response) {
    switch (response) {
        case null -> { }
        case String s -> {
            if (s.equalsIgnoreCase("YES"))
                System.out.println("You got it");
            else if (s.equalsIgnoreCase("NO"))
                System.out.println("Shame");
            else
                System.out.println("Sorry?");
        } 
    }
}
```

By using a single pattern to discriminate among cases is a problem since it does not scale beyond a single condition. It would be preferable if we would write multiple patterns, but then we need a way to express a refinement to a pattern. We therefor allow when clauses in a `switch` block to specify guards for pattern case labels. 

A working example _with_ Java 21 that we would refer to as guarded case label would be:

```java
String s when s.equalsIgnoreCase("YES")
```

By using that approach we can re-write our existing `testString` method which will lead to a more readable way:

```java
static void testString(String response) {
    switch (response) {
        case null -> { }
        case String s
        when s.equalsIgnoreCase("YES") -> {
            System.out.println("You got it");
        }
        case String s
        when s.equalsIgnoreCase("NO") -> {
            System.out.println("Shame");
        }
        case String s -> {
            System.out.println("Sorry?");
        }
    }
}
```

There is a way we can further enhance this code by some extra rules for other constant strings:

```java
static void testString(String response) {
    switch (response) {
        case null -> { }
        case "y", "Y" -> {
            System.out.println("You got it");
        }
        case "n", "N" -> {
            System.out.println("Shame");
        }
        case String s
        when s.equalsIgnoreCase("YES") -> {
            System.out.println("You got it");
        }
        case String s
        when s.equalsIgnoreCase("NO") -> {
            System.out.println("Shame");
        }
        case String s -> {
            System.out.println("Sorry?");
        } 
    }
}
```

## Switches and enum constants

To use enum constants in case labels is highly constrained at the moment. We need to have an enum type for the selector expression in the `switch`, it also has to be simple names of the enum constants. 

A working example _prior_ to Java 21 would be:

```java
public enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES }

static void testforHearts(Suit s) {
    switch (s) {
        case HEARTS -> System.out.println("It's a heart!");
        default -> System.out.println("Some other suit");
    }
}
```

Even if we are adding pattern labels this constraint will lead to unnecessarily verbose code. 

A working example _with_ Java 21 would be:

```java
sealed interface CardClassification permits Suit, Tarot {}
public enum Suit implements CardClassification { CLUBS, DIAMONDS, HEARTS, SPADES }
final class Tarot implements CardClassification {}

static void exhaustiveSwitchWithoutEnumSupport(CardClassification c) {
    switch (c) {
        case Suit s when s == Suit.CLUBS -> {
            System.out.println("It's clubs");
        }
        case Suit s when s == Suit.DIAMONDS -> {
            System.out.println("It's diamonds");
        }
        case Suit s when s == Suit.HEARTS -> {
            System.out.println("It's hearts");
        }
        case Suit s -> {
            System.out.println("It's spades");
        }
        case Tarot t -> {
            System.out.println("It's a tarot");
        } 
    }
}
```

If we would have a seperate case for each enum constant, we could make this more readable rather than lots of guarded patterns. We could then re-write the above code as:

```java
static void exhaustiveSwitchWithBetterEnumSupport(CardClassification c) {
    switch (c) {
        case Suit.CLUBS -> {
            System.out.println("It's clubs");
        }
        case Suit.DIAMONDS -> {
            System.out.println("It's diamonds");
        }
        case Suit.HEARTS -> {
            System.out.println("It's hearts");
        }
        case Suit.SPADES -> {
            System.out.println("It's spades");
        }
        case Tarot t -> {
            System.out.println("It's a tarot");
        }
    }
}
```

Now there is a direct case for each of the enum constants without using a guarded type pattern.

## Enhanced type checking

### Selector expression typing

By supporting patterns in a `switch` it now means that we can have a relaxed restriction on the type of the selector expression. Currently, the type of the selector expression of a regular `switch` must be either an integral primitive type (exluding `long`), the corresponding boxed form such as `Character`, `Byte`, `Short`, `Integer`, `String`, or an enum type. 

For example, in the pattern switch below, the selector expression `obj` is matched with type patterns that involves a class type, enum type, record type and an array type. As well as a null case label and default.

A working example _with_ Java 21 would be:

```java
record Point(int i, int j) {}
enum Color { RED, GREEN, BLUE; }

static void typeTester(Object obj) {
    switch (obj) {
        case null     -> System.out.println("null");
        case String s -> System.out.println("String");
        case Color c  -> System.out.println("Color: " + c.toString());
        case Point p  -> System.out.println("Record class: " + p.toString());
        case int[] ia -> System.out.println("Array of ints of length" + ia.length);
        default       -> System.out.println("Something else");
    } 
}
```

In the `switch` block, for every case label, must be compatible with the selector expression. A pattern label (a case label with a pattern), we use the existing notion of _compability of an expression with a pattern_.

### Dominance of case labels

Supporting pattern case labels means that for a given value of the selector expression it will be possible now to use more than one case label to apply, whereas in the earlier Java versions we could have at most one case label to be applied. 

One example would be if the selector expression should evaluate to a `String`, then both case labels `case String s` and `case CharSequence cs` would apply.

An example _with_ Java 21 would be:

```java
static void first(Object obj) {
    switch (obj) {
        case String s ->
            System.out.println("A string: " + s);
        case CharSequence cs ->
            System.out.println("A sequence of length " + cs.length());
        default -> {
            break; 
        }
    }
}
```

The value of `obj` in this example if it's of type `String`, then it will apply the first case label. If it would be of type `CharSequence`, but not the type `String` then the second pattern label would apply. But let's say we swap the order of these two case labels?

A working example _with_ Java 21 would be:

```java
static void first(Object obj) {
    switch (obj) {
        case CharSequence cs ->
            System.out.println("A sequence of length " + cs.length());
        case String s ->    
            System.out.println("A string: " + s);
        default -> {
            break; 
        }
    }
}
```

If the value of `obj` now would be of type `String` the `CharSequence` case label applies. This is because it appears first in the `switch` block. The `String` case label is unreachable since there is no value of the selector expression that could cause it to be chosen.

## Exhaustiveness of switch expressions and statements

### Type coverage

By using a `switch` expression it requires that all possible values of the selector expression will be handled in the `switch` block. So to put it to another words, it must be _exhaustive_. For normal `switch` expressions, this property is enforced by a set of extra conditions on the `switch` block. 

For pattern switch expressions and statements, we achieve this by defining a notion of _type coverage_ of `switch` labels in a `switch` block. 

A erroneous example _with_ Java 21 would be:

```java
static int coverage(Object obj) {
    return switch (obj) {           
        case String s -> s.length();
    };
}
```

This switch block only have one switch label, `case String s`. This pattern `switch` expressions is not _exhaustive_ because of the type coverage of its `switch` block does not include the type of the selector expression (`Object`).

### Exhaustiveness in practice

A erroneous example _prior_ to Java 21 would be:

```java
enum Color { RED, YELLOW, GREEN }

int numLetters = switch (color) {
    case RED -> 3;
    case GREEN -> 5;
}
```

This `switch` expression over an enum class is not _exhaustive_ since the anticipated input `YELLOW` is not covered. By adding a case label to handle the `YELLOW` enum constant is sufficient to make the `switch` _exhaustive_, as expected.

A working example _prior_ to Java 21 would be:

```java
int numLetters = switch (color) {
    case RED -> 3;
    case GREEN -> 5;
    case YELLOW -> 6;
}
```

### Exhaustiveness and sealed classes

If the type of the selector expression is a sealed class, then the type coverage check can take into account the permits clause of the sealed class to determine if a `switch` block is _exhaustive_ or not.

> Sealed classes and interfaces restrict which other classes or interfaces may extend or implement them.

By using a sealed class as the selector expression, we can sometimes remove the need for a default clause, which is a good practice. 

An example _with_ Java 21 would be:

```java
sealed interface S permits A, B, C {}

final class A implements S {}
final class B implements S {}

record C(int i) implements S {}

static int testSealedExhaustive(S s) {
    return switch (s) {
        case A a -> 1;
        case B b -> 2;
        case C c -> 3;
    };
}
```

The compiler can now determine that the type coverage of the `switch` block is the types A, B and C. Since `S`, the type of the selector expression is a sealed interface whose permitted subclasses are exactly A, B and C, this `switch` block is now _exhaustive_, and thus no need of using a default label clause.

## Dealing with null

A `switch` traditionally throws `NullPointerException` if the selector expression evaluates to `null`. There are, however, reasonable and non-exception-raising semenatics for pattern matching and `null` values, so we can treat `null` in a more regular way and still remain compatible with existing semantics. 

In this new Java version, there is a new `null` case label. We should however know that:

- If the selector expression would evaluate to `null`, then any `null` case is said to match. We throw `NullPointerException` as before if there is no such label associated with the switch block. 
- If the selector expression would evaluate to a non-null value, then we, as normal, select a matching case label. If there are no case label matches, then any default label is considered a match.

An example _with_ Java 21 would be:

```java
static void nullMatch(Object obj) {
    switch (obj) {
        case null     -> System.out.println("null!");
        case String s -> System.out.println("String");
        default       -> System.out.println("Something else");
    }
}
```

With this given code example, we evaluate null, and print out `null!` instead of throwing a `NullPointerException`.

An example _with_ Java 21 that can throw `NullPointerException` would be:

```java
static void nullMatch(Object obj) {
    switch (obj) {
        case String s  -> System.out.println("String: " + s);
        case Integer i -> System.out.println("Integer");
        default        -> System.out.println("default");
    }
}
```

## Errors

For example, by matching a value against a record pattern, the record's accessor method can complete abruptly. In this case where we match against a record pattern, pattern matching is defined to complete abruptly by throwing a `MatchException`. It will also complete abruptly if such pattern appears as a label in a `switch` block by throwing `MatchException`. 

If no label in a pattern `switch` would match the value of the selector expression, then the `switch` completes abruptly and throws an `MatchException`, since it needs to be _exhaustive_.

An example _with_ Java 21 that throws an exception would be:

```java
record R(int i) {
    public int i() {
        return i / 0;
    } 
}

static void example(R r) {
    switch(r) {
        case R(var i): System.out.println(i);
    }
}
```

The invocation `example(new R(42))` will cause a `MatchException` to be thrown. 

A second example _with_ Java 21 that throws an exception would be: 

```java
static void example(Object obj) {
    switch (obj) {
        case R r when (r.i / 0 == 1): System.out.println("It's an R!");
        default: break;
    }
}
```

This will throw a `ArithmeticException`.

## Summary

So now you probably know a little bit more about Pattern Matching for switch. This new feature is very useful as you probably have realized until now comparing to older Java versions. 

If you found it valuable, please consider sharing it, as it might also be valuable to others. Let me know if you have any questions by reaching me on 𝕏!

## Resources

- [JEP 441](https://openjdk.org/jeps/441)
- [JEP 440](https://openjdk.org/jeps/440)
- [Sealed Classes](https://docs.oracle.com/en/java/javase/17/language/sealed-classes-and-interfaces.html#GUID-0C709461-CC33-419A-82BF-61461336E65F)
- [Pattern Matching for instanceof](https://docs.oracle.com/en/java/javase/17/language/pattern-matching-instanceof-operator.html#GUID-843060B5-240C-4F47-A7B0-95C42E5B08A7)
- [Record Patterns](https://docs.oracle.com/en/java/javase/20/language/record-patterns.html#GUID-7623D3AD-4141-4914-A384-60C65BD0C010)
- [MatchException](https://download.java.net/java/early_access/valhalla/docs/api/java.base/java/lang/MatchException.html)
- [ArithmeticException](https://docs.oracle.com/javase%2F7%2Fdocs%2Fapi%2F%2F/java/lang/ArithmeticException.html)

## Connect with me
- [𝕏](https://x.com/mjovanc)
- [GitHub](https://github.com/mjovanc)
- [LinkedIn](https://www.linkedin.com/in/marcuscvjeticanin/)