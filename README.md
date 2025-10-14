# HexCompiler

This is a lua compiler for the Minecraft mod called Hexcasting. 
It is designed to be used in game via the mod Computer Craft.


## Language Details

### Numbers
Numbers are represented naturally (no distinctions between integers and floats). *examples:*
`1`, `123`, `1.23`, `1.0`, `-4.5`

### Booleans
Either `true` or `false`

### Null
Represented by `null`

### Vectors
List of three comma seperated coordinate values (x, y, z) surrounded by curly braces. *examples:* `{0,0,0}`, `{1, 2, 3}`, `{0, -1, 0}`, `{true, 0, 1}` (although using non-number values will cause an error at runtime)

### Lists
Set of comma seperated values surrounded by square brackets. *examples:* `[1, 2, 3]`, `[true]`, `[]`, `[1, [2, 3], 4]`

### Function values
Functions can be created using the `function` keyword, and are treated as values. They are inherently anonymous, and do not store any information about themselves. For example, this means there will not be an error if you try to call a function with the wrong number of arguments (but things will go wrong nonetheless).
*examples:* `function() {...}`, `function(a) {...}`, `function(a, b, c) {...}` (more details on `...` below)

### Inline Hex
This is a way of bypassing the compiler and directly writing patterns to the output. Double quotes are used to indicate this, with values inserted using curly braces. The resulting effect ***must*** be that a single value has been added to the stack. *examples:* `"consideration one"`, `"minds_reflection"`, `{a} reveal`
#### **CURRENT ISSUE:**
There is no way to indicate to the compiler if the stack has been altered part way through the inline notation. Because of this, variable access will become misaligned. To avoid, only access variables when the stack is the same size as it was at the start of the inline hex value.

### Operators
Special cases (like vector division being the cross product) can be found in the Hexcasting mod book.
| Name                  | Syntax(s)     |
|-----------------------|---------------|
|Addition               |a + b          |
|Subtraction            |a - b          |
|Multiplication         |a * b          |
|Division (not floor)   |a / b          |
|Exponentiate           |a ** b         |
|Modulo                 |a % b          |
|Equal                  |a == b         |
|Not Equal              |a != b         |
|Greater Than           |a > b          |
|Greater Than or Equal  |a >= b         |
|Less Than              |a < b          |
|Less Than or Equal     |a <= b         |
|And                    |a and b, a & b |
|Or                     |a or b, a \| b |
|Xor                    |a xor b, a ^ b |

### Other values
Although there is only syntax present for the above, any other values that can be created (like entities) are valid and have interactions.

### Variables
Variables are block scoped and defined with the `let` keyword, they can also be given initial values by using an assignment statement.
*example:*
```
let my_variable;
let other_var = 5;
```
Variables can be assigned to using the assignment operator (`=`), optionally preceded by a normal operator if the left hand side of an operator is the variable itself.
*example:*
```
let my_variable;
my_variable = 1 + 2;
my_variable = my_variable + 6;
my_variable += 6; // same as previous line.
```
There exists a shorthand for incrementing and decrementing a variable by 1, in the following form:
```
let counter = 0;

counter++; // increases counter by 1
counter += 1; // same thing
counter = counter + 1; // same thing again

counter--; // decreases counter by 1
counter -= 1; // same thing
counter = counter - 1; // same thing again
```
List variables have special syntax for changing the value at a particular index (which start at 1). This can be nested as much as desired.
```
let my_list = [1, 2, 3, 5, 6];

my_list[3] = [4, 5]; // [1, 2, [3, 5], 5, 6]
my_list[3][2] = 4; // [1, 2, [3, 4], 5, 6]

```
They can also be deleted from the scope early using the `delete` keyword. This frees up stack space and is generally a good idea to do early if possible.
*example:*
```
let other_var = 5;
// do stuff
delete other_var;
// stack now more free
```

### If statements
These allow conditions to change how the program executes. They can be chained using else statements like so:
```
let a = 4;

let b;
if (a == 3) {
    b = 1;
} else if (a > 3) {
    b = 2;
} else {
    b = 0;
}
print(b); // 2
```

### Functions
Functions are values that contain code within them. They can be created and immediately used, or stored into a variable. They can\* be recursive (call themselves) and have multiple return points (specified with the `return` keyword). *examples:*
```
let my_function = function(a, b) {
    return a + b;
}
print(my_function(1, 2)); // 3
let other_function = function(a, b) {
    if (a > b) {
        return a - b;
    } else if (b > a) {
        return b - a;
    }
    return 1;
}
print(other_function(3, 5)); // 2
```
\* There is a minor technicality with recursion currently, as a variable has to be declared already to be used within the function. This means that directly declaring a variable as a function and attempting to use recursion will fail. Instead, declare it before assigning the value. *example:*
```
let factorial;
factorial = function(n) {
    if (n == 0) {
        return 1;
    }
    return n * factorial(n - 1)
};
print(factorial(3)); // 6
```

### For Loops
Loops can be used to repeat code, often iterating over elements. While loops are not implemented currently (since the underlying system makes them difficult, although they can be achieved through recursion if needed). There are two main types of for loops:
#### For-in loops
These iterate over a given list and have a variable take on the value at each index from 1 to the size of the list.
```
for (value in list) {
    print(value); // prints each value in list
}

for (v in [1, 6, 2, 8, 4]) {
    print(v); // prints 1, 6, 2, 8, 4
}
```
#### For-range loops
These use an arrow (`->`) notation to specify a range for a value to take on.
```
for (i = min -> max) {
    print(i); // prints all values between min-max (inclusive)
}

for (i = 1 -> 5) {
    print(i); // prints 1, 2, 3, 4, 5
}
```
There is also some special syntax for changing the step size
```
for (i = 1 -> 10 by 2) {
    print(i); // prints 1, 3, 5, 7, 9 (stops since 11 > 10)
}
for (i = 5 -> 1 by -1) {
    print(i); // prints 5, 4, 3, 2, 1
}
```
And shorthand for starting at 1
```
for (i -> 5) {
    print(i); // prints 1, 2, 3, 4, 5
}
```

# UNFINISHED:

### Properties

### Comments

### Global Values

###